import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pixelpad/features/make/data/make_pipeline_result.dart';
import 'package:pixelpad/features/make/data/make_pipeline_service.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

void main() {
  group('MakePipelineService', () {
    test('initializeSession returns session metadata and perfect pixel buffer', () async {
      final _FakePixelPadApiService api = _FakePixelPadApiService(
        createSessionResult: const SessionResult(
          sessionId: 'session-123',
          width: 8,
          height: 6,
        ),
        perfectPixelResult: PerfectPixelResult(
          rgbaU8Base64: base64Encode(Uint8List.fromList(List<int>.filled(8 * 6 * 4, 255))),
          width: 8,
          height: 6,
        ),
      );
      final MakePipelineService service = MakePipelineService(api: api);

      final MakePipelineSession session = await service.initializeSession(
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
        settingsFile: 'MARD-24.json',
      );

      expect(session.sessionId, 'session-123');
      expect(session.width, 8);
      expect(session.height, 6);
      expect(session.perfectPixelRgba.length, 8 * 6 * 4);
      expect(api.createSessionCalls, 1);
      expect(api.perfectPixelCalls, 1);
    });

    test('processWithParameters forwards tolerance/maxColors and aligns buffers', () async {
      final _FakePixelPadApiService api = _FakePixelPadApiService(
        removeBackgroundResult: RemoveBackgroundResult(
          width: 2,
          height: 2,
          bgMaskRleU32leBase64: '',
          bgMaskStart: false,
        ),
        colorMapResult: ColorMapResult(
          width: 2,
          height: 2,
          palette: const <PaletteColorEntry>[
            PaletteColorEntry(
              idx: 1,
              id: 'A1',
              count: 2,
              rgba: <int>[255, 0, 0, 255],
              hex: '#ff0000',
            ),
            PaletteColorEntry(
              idx: 2,
              id: 'B2',
              count: 2,
              rgba: <int>[0, 255, 0, 255],
              hex: '#00ff00',
            ),
          ],
          mappingU16leBase64: _mappingBase64(<int>[1, 2, 0, 1]),
          previewPadding: const <int>[1, 1, 0, 0],
        ),
      );
      final MakePipelineService service = MakePipelineService(api: api);

      final MakePipelineResult result = await service.processWithParameters(
        sessionId: 'session-xyz',
        sessionWidth: 3,
        sessionHeight: 3,
        perfectWidth: 3,
        perfectHeight: 3,
        maxColors: 24,
        tolerance: 9,
      );

      expect(api.removeBackgroundCalls, 1);
      expect(api.removeBackgroundTolerance, 9);
      expect(api.removeBackgroundTightCrop, true);
      expect(api.removeBackgroundPreviewOnly, false);
      expect(api.colorMapCalls, 1);
      expect(api.colorMapMaxColors, 24);
      expect(result.width, 3);
      expect(result.height, 3);
      expect(result.maxColors, 24);
      expect(result.backgroundTolerance, 9);
      expect(result.mapping.length, 9);
      expect(
        result.mapping,
        Uint16List.fromList(<int>[0, 0, 0, 0, 1, 2, 0, 0, 1]),
      );
      expect(
        result.bgMask,
        Uint8List.fromList(<int>[1, 1, 1, 1, 0, 0, 1, 0, 0]),
      );
    });
  });
}

class _FakePixelPadApiService extends PixelPadApiService {
  _FakePixelPadApiService({
    this.createSessionResult = const SessionResult(
      sessionId: 'default-session',
      width: 0,
      height: 0,
    ),
    this.perfectPixelResult = const PerfectPixelResult(
      rgbaU8Base64: '',
      width: 0,
      height: 0,
    ),
    this.removeBackgroundResult = const RemoveBackgroundResult(
      width: 0,
      height: 0,
      bgMaskRleU32leBase64: '',
      bgMaskStart: false,
    ),
    this.colorMapResult = const ColorMapResult(
      width: 0,
      height: 0,
      palette: <PaletteColorEntry>[],
      mappingU16leBase64: '',
      previewPadding: null,
    ),
  });

  final SessionResult createSessionResult;
  final PerfectPixelResult perfectPixelResult;
  final RemoveBackgroundResult removeBackgroundResult;
  final ColorMapResult colorMapResult;

  int createSessionCalls = 0;
  int perfectPixelCalls = 0;
  int removeBackgroundCalls = 0;
  int colorMapCalls = 0;
  int? removeBackgroundTolerance;
  bool? removeBackgroundTightCrop;
  bool? removeBackgroundPreviewOnly;
  int? colorMapMaxColors;

  @override
  Future<SessionResult> createSession({
    required Uint8List imageBytes,
    required String settingsFile,
    String filename = 'upload.png',
  }) async {
    createSessionCalls += 1;
    return createSessionResult;
  }

  @override
  Future<PerfectPixelResult> perfectPixel({required String sessionId}) async {
    perfectPixelCalls += 1;
    return perfectPixelResult;
  }

  @override
  Future<RemoveBackgroundResult> removeBackground({
    required String sessionId,
    int tolerance = 5,
    bool tightCrop = true,
    bool previewOnly = false,
  }) async {
    removeBackgroundCalls += 1;
    removeBackgroundTolerance = tolerance;
    removeBackgroundTightCrop = tightCrop;
    removeBackgroundPreviewOnly = previewOnly;
    return removeBackgroundResult;
  }

  @override
  Future<ColorMapResult> colorMap({
    required String sessionId,
    required int maxColors,
    String colorMapMode = 'nearest',
    bool alphaHarden = true,
  }) async {
    colorMapCalls += 1;
    colorMapMaxColors = maxColors;
    return colorMapResult;
  }
}

String _mappingBase64(List<int> values) {
  final ByteData data = ByteData(values.length * 2);
  for (int index = 0; index < values.length; index += 1) {
    data.setUint16(index * 2, values[index], Endian.little);
  }
  return base64Encode(data.buffer.asUint8List());
}
