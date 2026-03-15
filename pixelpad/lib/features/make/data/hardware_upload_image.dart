import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

class HardwareCutMetadata {
  final int inputWidth;
  final int inputHeight;
  final int targetWidth;
  final int targetHeight;
  final int cropLeft;
  final int cropRight;
  final int cropTop;
  final int cropBottom;
  final int padLeft;
  final int padRight;
  final int padTop;
  final int padBottom;

  const HardwareCutMetadata({
    required this.inputWidth,
    required this.inputHeight,
    required this.targetWidth,
    required this.targetHeight,
    required this.cropLeft,
    required this.cropRight,
    required this.cropTop,
    required this.cropBottom,
    required this.padLeft,
    required this.padRight,
    required this.padTop,
    required this.padBottom,
  });

  factory HardwareCutMetadata.fromCutPixelResult(CutPixelResult result) {
    if (result.crop.length < 4 || result.padding.length < 4) {
      throw Exception('cut_pixel_metadata_invalid');
    }
    return HardwareCutMetadata(
      inputWidth: result.inputWidth,
      inputHeight: result.inputHeight,
      targetWidth: result.targetWidth,
      targetHeight: result.targetHeight,
      cropLeft: result.crop[0],
      cropRight: result.crop[1],
      cropTop: result.crop[2],
      cropBottom: result.crop[3],
      padLeft: result.padding[0],
      padRight: result.padding[1],
      padTop: result.padding[2],
      padBottom: result.padding[3],
    );
  }
}

class AlignedHardwareFrame {
  final int width;
  final int height;
  final Uint16List mapping;
  final Uint8List bgMask;

  const AlignedHardwareFrame({
    required this.width,
    required this.height,
    required this.mapping,
    required this.bgMask,
  });
}

AlignedHardwareFrame alignToHardwareCanvas({
  required int width,
  required int height,
  required Uint16List mapping,
  required Uint8List bgMask,
  required HardwareCutMetadata metadata,
}) {
  final int currentPixels = width * height;
  if (mapping.length != currentPixels || bgMask.length != currentPixels) {
    throw Exception('hardware_canvas_source_size_mismatch');
  }

  if (width == metadata.targetWidth && height == metadata.targetHeight) {
    return AlignedHardwareFrame(
      width: width,
      height: height,
      mapping: Uint16List.fromList(mapping),
      bgMask: Uint8List.fromList(bgMask),
    );
  }

  if (width != metadata.inputWidth || height != metadata.inputHeight) {
    throw Exception('hardware_canvas_input_size_mismatch');
  }

  final int innerWidth = width - metadata.cropLeft - metadata.cropRight;
  final int innerHeight = height - metadata.cropTop - metadata.cropBottom;
  if (innerWidth <= 0 || innerHeight <= 0) {
    throw Exception('hardware_canvas_crop_invalid');
  }
  if (innerWidth + metadata.padLeft + metadata.padRight !=
          metadata.targetWidth ||
      innerHeight + metadata.padTop + metadata.padBottom !=
          metadata.targetHeight) {
    throw Exception('hardware_canvas_target_mismatch');
  }

  final Uint16List alignedMapping = Uint16List(
    metadata.targetWidth * metadata.targetHeight,
  );
  final Uint8List alignedMask = Uint8List(
    metadata.targetWidth * metadata.targetHeight,
  )..fillRange(0, metadata.targetWidth * metadata.targetHeight, 1);

  for (int y = 0; y < innerHeight; y += 1) {
    final int srcRow = (y + metadata.cropTop) * width + metadata.cropLeft;
    final int dstRow =
        (y + metadata.padTop) * metadata.targetWidth + metadata.padLeft;
    for (int x = 0; x < innerWidth; x += 1) {
      alignedMapping[dstRow + x] = mapping[srcRow + x];
      alignedMask[dstRow + x] = bgMask[srcRow + x];
    }
  }

  return AlignedHardwareFrame(
    width: metadata.targetWidth,
    height: metadata.targetHeight,
    mapping: alignedMapping,
    bgMask: alignedMask,
  );
}

Future<Uint8List> renderHardwareUploadPng({
  required int width,
  required int height,
  required Uint16List mapping,
  required List<PaletteColorEntry> palette,
  required Uint8List bgMask,
  required HardwareCutMetadata metadata,
  Set<int>? selectedIndices,
}) async {
  final AlignedHardwareFrame frame = alignToHardwareCanvas(
    width: width,
    height: height,
    mapping: mapping,
    bgMask: bgMask,
    metadata: metadata,
  );
  final bool hasSelection =
      selectedIndices != null && selectedIndices.isNotEmpty;
  final Map<int, List<int>> paletteByIdx = <int, List<int>>{
    for (final PaletteColorEntry entry in palette)
      if (entry.idx > 0) entry.idx: entry.rgba,
  };
  final img.Image image = img.Image(
    width: frame.width,
    height: frame.height,
    numChannels: 4,
  );
  for (int y = 0; y < frame.height; y += 1) {
    for (int x = 0; x < frame.width; x += 1) {
      final int index = y * frame.width + x;
      if (frame.bgMask[index] != 0) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      final int paletteIdx = frame.mapping[index];
      if (paletteIdx <= 0) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      final List<int>? color = paletteByIdx[paletteIdx];
      if (color == null) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      if (hasSelection && !selectedIndices.contains(paletteIdx)) {
        image.setPixelRgba(x, y, 0, 0, 0, 255);
        continue;
      }
      image.setPixelRgba(
        x,
        y,
        color.isNotEmpty ? color[0].clamp(0, 255).toInt() : 0,
        color.length > 1 ? color[1].clamp(0, 255).toInt() : 0,
        color.length > 2 ? color[2].clamp(0, 255).toInt() : 0,
        color.length > 3 ? color[3].clamp(0, 255).toInt() : 255,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
