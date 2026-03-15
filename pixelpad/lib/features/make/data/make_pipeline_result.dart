import 'dart:typed_data';

import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

class MakePipelineResult {
  final Uint16List mapping;
  final List<PaletteColorEntry> palette;
  final Uint8List bgMask;
  final int width;
  final int height;
  final int maxColors;
  final int backgroundTolerance;

  const MakePipelineResult({
    required this.mapping,
    required this.palette,
    required this.bgMask,
    required this.width,
    required this.height,
    required this.maxColors,
    required this.backgroundTolerance,
  });
}

class MakePipelineSession {
  final String sessionId;
  final Uint8List perfectPixelRgba;
  final int width;
  final int height;
  final int perfectWidth;
  final int perfectHeight;

  const MakePipelineSession({
    required this.sessionId,
    required this.perfectPixelRgba,
    required this.width,
    required this.height,
    required this.perfectWidth,
    required this.perfectHeight,
  });
}
