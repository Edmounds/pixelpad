import 'dart:async';
import 'dart:typed_data';

import 'package:pixelpad/features/make/data/make_pipeline_result.dart';
import 'package:pixelpad/features/make/data/palette_mapping.dart';
import 'package:pixelpad/features/make/data/pixel_codec.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

class MakePipelineException implements Exception {
  final String message;

  const MakePipelineException(this.message);

  @override
  String toString() => 'MakePipelineException($message)';
}

class MakePipelineService {
  MakePipelineService({PixelPadApiService? api}) : _api = api ?? PixelPadApiService();

  final PixelPadApiService _api;

  Future<MakePipelineSession> initializeSession({
    required Uint8List imageBytes,
    required String settingsFile,
  }) async {
    SessionResult sessionResult;
    try {
      sessionResult = await _api.createSession(
        imageBytes: imageBytes,
        settingsFile: settingsFile,
      );
    } catch (error) {
      throw MakePipelineException(
        formatPipelineStepError(step: '创建会话', error: error),
      );
    }
    if (sessionResult.sessionId.isEmpty) {
      throw const MakePipelineException('创建会话失败');
    }

    PerfectPixelResult perfectResult;
    try {
      perfectResult = await _api.perfectPixel(sessionId: sessionResult.sessionId);
    } catch (error) {
      throw MakePipelineException(
        formatPipelineStepError(step: '像素优化', error: error),
      );
    }

    final int width =
        (perfectResult.width > 0) ? perfectResult.width : sessionResult.width;
    final int height =
        (perfectResult.height > 0) ? perfectResult.height : sessionResult.height;
    if (width <= 0 || height <= 0) {
      throw const MakePipelineException('图像尺寸无效');
    }

    final Uint8List rgba = decodeRgbaU8(perfectResult.rgbaU8Base64);
    if (rgba.isNotEmpty && rgba.length != width * height * 4) {
      throw const MakePipelineException('像素优化结果异常');
    }

    return MakePipelineSession(
      sessionId: sessionResult.sessionId,
      perfectPixelRgba: rgba,
      width: sessionResult.width > 0 ? sessionResult.width : width,
      height: sessionResult.height > 0 ? sessionResult.height : height,
      perfectWidth: width,
      perfectHeight: height,
    );
  }

  Future<MakePipelineResult> processWithParameters({
    required String sessionId,
    required int sessionWidth,
    required int sessionHeight,
    required int perfectWidth,
    required int perfectHeight,
    required int maxColors,
    required int tolerance,
  }) async {
    RemoveBackgroundResult removeResult;
    try {
      removeResult = await _api.removeBackground(
        sessionId: sessionId,
        tolerance: tolerance,
        tightCrop: true,
        previewOnly: false,
      );
    } catch (error) {
      throw MakePipelineException(
        formatPipelineStepError(step: '背景移除', error: error),
      );
    }

    ColorMapResult colorMapResult;
    try {
      colorMapResult = await _api.colorMap(
        sessionId: sessionId,
        maxColors: maxColors,
        colorMapMode: 'nearest',
        alphaHarden: true,
      );
    } catch (error) {
      throw MakePipelineException(
        formatPipelineStepError(step: '颜色映射', error: error),
      );
    }

    final int removeWidth = (removeResult.width > 0) ? removeResult.width : perfectWidth;
    final int removeHeight = (removeResult.height > 0) ? removeResult.height : perfectHeight;
    final int colorMapWidth =
        (colorMapResult.width > 0) ? colorMapResult.width : removeWidth;
    final int colorMapHeight =
        (colorMapResult.height > 0) ? colorMapResult.height : removeHeight;
    int width = (colorMapWidth > 0)
        ? colorMapWidth
        : ((removeWidth > 0) ? removeWidth : perfectWidth);
    int height = (colorMapHeight > 0)
        ? colorMapHeight
        : ((removeHeight > 0) ? removeHeight : perfectHeight);
    if (width <= 0 || height <= 0) {
      throw const MakePipelineException('图像尺寸无效');
    }

    Uint16List mapping = decodeMappingU16le(colorMapResult.mappingU16leBase64);
    if (mapping.length != colorMapWidth * colorMapHeight) {
      throw MakePipelineException(
        '颜色映射解码失败 (cm=$colorMapWidth x $colorMapHeight, mapping=${mapping.length})',
      );
    }

    final Uint8List decodedBgMask = decodeRleMask(
      removeResult.bgMaskRleU32leBase64,
      removeResult.bgMaskStart,
      removeWidth * removeHeight,
    );

    final List<({int width, int height})> previewCanvasCandidates =
        <({int width, int height})>[
          if (removeWidth > 0 && removeHeight > 0)
            (width: removeWidth, height: removeHeight),
          if (perfectWidth > 0 && perfectHeight > 0)
            (width: perfectWidth, height: perfectHeight),
          if (sessionWidth > 0 && sessionHeight > 0)
            (width: sessionWidth, height: sessionHeight),
        ];

    PreviewInsets? previewInsets;
    for (final ({int width, int height}) candidate in previewCanvasCandidates) {
      final List<PreviewInsets> matches = matchingPreviewInsets(
        rawPadding: colorMapResult.previewPadding,
        innerWidth: colorMapWidth,
        innerHeight: colorMapHeight,
        canvasWidth: candidate.width,
        canvasHeight: candidate.height,
      );
      if (matches.isEmpty) {
        continue;
      }
      if (matches.length == 1 ||
          decodedBgMask.length != candidate.width * candidate.height) {
        previewInsets = matches.first;
      } else {
        previewInsets = matches.reduce((PreviewInsets best, PreviewInsets next) {
          final int bestPenalty = previewInsetsMaskPenalty(
            mask: decodedBgMask,
            innerWidth: colorMapWidth,
            innerHeight: colorMapHeight,
            canvasWidth: candidate.width,
            canvasHeight: candidate.height,
            insets: best,
          );
          final int nextPenalty = previewInsetsMaskPenalty(
            mask: decodedBgMask,
            innerWidth: colorMapWidth,
            innerHeight: colorMapHeight,
            canvasWidth: candidate.width,
            canvasHeight: candidate.height,
            insets: next,
          );
          return nextPenalty < bestPenalty ? next : best;
        });
      }
      width = candidate.width;
      height = candidate.height;
      mapping = expandMappingToCanvas(
        mapping: mapping,
        innerWidth: colorMapWidth,
        innerHeight: colorMapHeight,
        canvasWidth: width,
        canvasHeight: height,
        insets: previewInsets,
      );
      break;
    }

    final Uint8List bgMask =
        (previewInsets != null && decodedBgMask.length == colorMapWidth * colorMapHeight)
        ? expandMaskToCanvas(
            mask: decodedBgMask,
            innerWidth: colorMapWidth,
            innerHeight: colorMapHeight,
            canvasWidth: width,
            canvasHeight: height,
            insets: previewInsets,
          )
        : alignMaskToExpectedOrZero(
            decodedMask: decodedBgMask,
            expectedPixels: width * height,
          );

    final int totalPixels = width * height;
    if (mapping.length != totalPixels) {
      throw MakePipelineException(
        '颜色映射解码失败 (final=$width x $height, mapping=${mapping.length}, mask=${decodedBgMask.length})',
      );
    }

    return MakePipelineResult(
      mapping: mapping,
      palette: colorMapResult.palette,
      bgMask: bgMask,
      width: width,
      height: height,
      maxColors: maxColors,
      backgroundTolerance: tolerance,
    );
  }
}

String formatPipelineStepError({
  required String step,
  required Object error,
}) {
  if (error is TimeoutException) {
    return '$step超时，请检查网络后重试';
  }

  final String raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('clientexception') ||
      raw.contains('failed host lookup')) {
    return '网络连接失败，请检查网络后重试';
  }

  final int? statusCode = extractPipelineStatusCode(error.toString());
  if (statusCode == 401 || statusCode == 403) {
    return '登录状态已失效，请重新登录后再试';
  }
  if (statusCode == 413) {
    return '图片过大，请压缩后重试';
  }
  if (statusCode == 429) {
    return '请求过于频繁，请稍后再试';
  }
  if (statusCode != null && statusCode >= 500) {
    return '$step失败，服务器繁忙，请稍后再试';
  }

  return '$step失败，请稍后重试';
}

int? extractPipelineStatusCode(String text) {
  final RegExpMatch? match = RegExp(r'_failed:(\d{3})').firstMatch(text);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1) ?? '');
}
