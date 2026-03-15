import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:pixelpad/features/make/data/make_api.dart';

class PixelPadApiService {
  PixelPadApiService({http.Client? client, this.baseUrl = makeApiBaseUrl})
    : _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 20);

  final http.Client _client;
  final String baseUrl;

  Future<SessionResult> createSession({
    required Uint8List imageBytes,
    required String settingsFile,
    String filename = 'upload.png',
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/sessions'),
    );
    request.fields['settings_file'] = settingsFile;
    request.files.add(
      http.MultipartFile.fromBytes('file', imageBytes, filename: filename),
    );

    final http.StreamedResponse streamed = await _client
        .send(request)
        .timeout(_timeout);
    final http.Response response = await http.Response.fromStream(
      streamed,
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('create_session_failed:${response.statusCode}');
    }
    return SessionResult.fromJson(_decodeJsonBody(response.body));
  }

  Future<PerfectPixelResult> perfectPixel({required String sessionId}) async {
    final http.Response response = await _client
        .post(
          Uri.parse('$baseUrl/perfect_pixel'),
          body: {'session_id': sessionId},
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('perfect_pixel_failed:${response.statusCode}');
    }
    return PerfectPixelResult.fromJson(_decodeJsonBody(response.body));
  }

  Future<RemoveBackgroundResult> removeBackground({
    required String sessionId,
    int tolerance = 5,
    bool tightCrop = true,
    bool previewOnly = false,
  }) async {
    final http.Response response = await _client
        .post(
          Uri.parse('$baseUrl/remove_background'),
          body: {
            'session_id': sessionId,
            'tolerance': tolerance.toString(),
            'tight_crop': tightCrop ? 'true' : 'false',
            'preview_only': previewOnly ? 'true' : 'false',
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('remove_background_failed:${response.statusCode}');
    }
    return RemoveBackgroundResult.fromJson(_decodeJsonBody(response.body));
  }

  Future<ColorMapResult> colorMap({
    required String sessionId,
    required int maxColors,
    String colorMapMode = 'nearest',
    bool alphaHarden = true,
  }) async {
    final http.Response response = await _client
        .post(
          Uri.parse('$baseUrl/color_map'),
          body: {
            'session_id': sessionId,
            'max_colors': maxColors.toString(),
            'color_map_mode': colorMapMode,
            'alpha_harden': alphaHarden ? 'true' : 'false',
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('color_map_failed:${response.statusCode}');
    }
    return ColorMapResult.fromJson(_decodeJsonBody(response.body));
  }

  Future<CutPixelResult> cutPixel({
    required String sessionId,
    int tileSize = 52,
  }) async {
    final http.Response response = await _client
        .post(
          Uri.parse('$baseUrl/cut_pixel'),
          body: <String, String>{
            'session_id': sessionId,
            'tile_size': tileSize.toString(),
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('cut_pixel_failed:${response.statusCode}');
    }
    return CutPixelResult.fromJson(_decodeJsonBody(response.body));
  }
}

class SessionResult {
  final String sessionId;
  final int width;
  final int height;

  const SessionResult({
    required this.sessionId,
    required this.width,
    required this.height,
  });

  factory SessionResult.fromJson(Map<String, dynamic> json) {
    return SessionResult(
      sessionId: _asString(json['session_id'] ?? json['sessionId']),
      width: _asInt(json['width']),
      height: _asInt(json['height']),
    );
  }
}

class PerfectPixelResult {
  final String rgbaU8Base64;
  final int width;
  final int height;

  const PerfectPixelResult({
    required this.rgbaU8Base64,
    required this.width,
    required this.height,
  });

  factory PerfectPixelResult.fromJson(Map<String, dynamic> json) {
    return PerfectPixelResult(
      rgbaU8Base64: _asString(
        json['rgba_u8_base64'] ?? json['rgbaU8Base64'] ?? json['rgba_base64'],
      ),
      width: _asInt(json['width']),
      height: _asInt(json['height']),
    );
  }
}

class RemoveBackgroundResult {
  final int width;
  final int height;
  final String bgMaskRleU32leBase64;
  final bool bgMaskStart;

  const RemoveBackgroundResult({
    required this.width,
    required this.height,
    required this.bgMaskRleU32leBase64,
    required this.bgMaskStart,
  });

  factory RemoveBackgroundResult.fromJson(Map<String, dynamic> json) {
    return RemoveBackgroundResult(
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      bgMaskRleU32leBase64: _asString(
        json['bg_mask_rle_u32le_base64'] ?? json['bgMaskRleU32leBase64'],
      ),
      bgMaskStart: _asBool(json['bg_mask_start'] ?? json['bgMaskStart']),
    );
  }
}

class ColorMapResult {
  final int width;
  final int height;
  final List<PaletteColorEntry> palette;
  final String mappingU16leBase64;
  final List<int>? previewPadding;

  const ColorMapResult({
    required this.width,
    required this.height,
    required this.palette,
    required this.mappingU16leBase64,
    required this.previewPadding,
  });

  factory ColorMapResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPalette = (json['palette'] as List<dynamic>? ?? []);
    return ColorMapResult(
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      palette: _toPaletteEntries(rawPalette),
      mappingU16leBase64: _asString(
        json['mapping_u16le_base64'] ?? json['mappingU16leBase64'],
      ),
      previewPadding: _toIntList(json['preview_padding']),
    );
  }
}

class CutPixelResult {
  final String sessionId;
  final int inputWidth;
  final int inputHeight;
  final int targetWidth;
  final int targetHeight;
  final int tileSize;
  final int cols;
  final int rows;
  final List<int> crop;
  final List<int> padding;
  final String canvasBase64;
  final List<String> tilesBase64;

  const CutPixelResult({
    required this.sessionId,
    required this.inputWidth,
    required this.inputHeight,
    required this.targetWidth,
    required this.targetHeight,
    required this.tileSize,
    required this.cols,
    required this.rows,
    required this.crop,
    required this.padding,
    required this.canvasBase64,
    required this.tilesBase64,
  });

  factory CutPixelResult.fromJson(Map<String, dynamic> json) {
    return CutPixelResult(
      sessionId: _asString(json['session_id'] ?? json['sessionId']),
      inputWidth: _asInt(json['input_width'] ?? json['inputWidth']),
      inputHeight: _asInt(json['input_height'] ?? json['inputHeight']),
      targetWidth: _asInt(json['target_width'] ?? json['targetWidth']),
      targetHeight: _asInt(json['target_height'] ?? json['targetHeight']),
      tileSize: _asInt(json['tile_size'] ?? json['tileSize']),
      cols: _asInt(json['cols']),
      rows: _asInt(json['rows']),
      crop: _toIntList(json['crop']) ?? const <int>[],
      padding: _toIntList(json['padding']) ?? const <int>[],
      canvasBase64: _asString(json['canvas_base64'] ?? json['canvasBase64']),
      tilesBase64: (json['tiles_base64'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(growable: false),
    );
  }
}

class PaletteColorEntry {
  final int idx;
  final String id;
  final int count;
  final List<int> rgba;
  final String hex;

  const PaletteColorEntry({
    required this.idx,
    required this.id,
    required this.count,
    required this.rgba,
    required this.hex,
  });
}

Map<String, dynamic> _decodeJsonBody(String body) {
  if (body.isEmpty) {
    return <String, dynamic>{};
  }
  final Object? parsed = jsonDecode(body);
  if (parsed is Map) {
    return parsed.map(
      (dynamic key, dynamic value) => MapEntry(key.toString(), value),
    );
  }
  return <String, dynamic>{};
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _asString(dynamic value) {
  if (value is String) {
    return value;
  }
  return '';
}

bool _asBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    final String normalized = value.trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }
  return false;
}

List<int> _toRgba(dynamic color) {
  if (color is List) {
    final List<int> rgba = color
        .whereType<num>()
        .map((num value) => value.toInt().clamp(0, 255).toInt())
        .toList();
    if (rgba.length >= 4) {
      return rgba.sublist(0, 4);
    }
    if (rgba.length == 3) {
      return <int>[rgba[0], rgba[1], rgba[2], 255];
    }
  }
  if (color is Map) {
    final Object? nested = color['rgba'];
    if (nested is List) {
      return _toRgba(nested);
    }
    final int r = _asInt(color['r']).clamp(0, 255).toInt();
    final int g = _asInt(color['g']).clamp(0, 255).toInt();
    final int b = _asInt(color['b']).clamp(0, 255).toInt();
    final int a = (_asInt(color['a']) == 0 ? 255 : _asInt(color['a']))
        .clamp(0, 255)
        .toInt();
    return <int>[r, g, b, a];
  }
  return const <int>[0, 0, 0, 255];
}

List<PaletteColorEntry> _toPaletteEntries(List<dynamic> rawPalette) {
  return List<PaletteColorEntry>.generate(rawPalette.length, (int index) {
    final dynamic item = rawPalette[index];
    if (item is Map) {
      final Map<dynamic, dynamic> map = item;
      final int idx = _asInt(
        map['idx'] ?? map['palette_idx'] ?? map['paletteIdx'] ?? (index + 1),
      );
      final List<int> rgba = _toRgba(map['rgba'] ?? item);
      return PaletteColorEntry(
        idx: idx,
        id: _asString(map['id'] ?? map['num'] ?? map['label']).isNotEmpty
            ? _asString(map['id'] ?? map['num'] ?? map['label'])
            : '$idx',
        count: _asInt(map['count']),
        rgba: rgba,
        hex: _asString(map['hex']).isNotEmpty
            ? _asString(map['hex'])
            : _rgbaToHex(rgba),
      );
    }

    final List<int> rgba = _toRgba(item);
    final int idx = index + 1;
    return PaletteColorEntry(
      idx: idx,
      id: '$idx',
      count: 0,
      rgba: rgba,
      hex: _rgbaToHex(rgba),
    );
  });
}

String _rgbaToHex(List<int> rgba) {
  final int r = rgba.isNotEmpty ? rgba[0].clamp(0, 255).toInt() : 0;
  final int g = rgba.length > 1 ? rgba[1].clamp(0, 255).toInt() : 0;
  final int b = rgba.length > 2 ? rgba[2].clamp(0, 255).toInt() : 0;
  return '#'
      '${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

List<int>? _toIntList(dynamic value) {
  if (value is! List) {
    return null;
  }
  return value.whereType<num>().map((num v) => v.toInt()).toList();
}
