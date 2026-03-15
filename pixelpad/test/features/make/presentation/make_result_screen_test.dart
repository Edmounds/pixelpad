import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/device/domain/services/bluetooth_service.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';
import 'package:pixelpad/features/make/presentation/screens/make_result_screen.dart';

void main() {
  testWidgets('prefetches cut_pixel once and uploads a 52x52 PNG', (
    WidgetTester tester,
  ) async {
    final _FakePixelPadApiService api = _FakePixelPadApiService();
    final _UploadRecorder recorder = _UploadRecorder();
    recorder.uploaded.clear();
    expect(recorder.service.isConnected, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MakeResultScreen(
          sessionId: 'session-1',
          width: 50,
          height: 52,
          mapping: Uint16List.fromList(List<int>.filled(50 * 52, 1)),
          bgMask: Uint8List.fromList(List<int>.filled(50 * 52, 0)),
          palette: const <PaletteColorEntry>[
            PaletteColorEntry(
              idx: 1,
              id: 'A1',
              count: 50 * 52,
              rgba: <int>[255, 0, 0, 255],
              hex: '#ff0000',
            ),
          ],
          api: api,
          btService: recorder.service,
        ),
      ),
    );

    await _pumpForAsyncWork(tester);

    expect(api.cutPixelCalls, 1);
    expect(recorder.uploaded, hasLength(1));
    final img.Image? uploaded = img.decodePng(recorder.uploaded.single);
    expect(uploaded, isNotNull);
    expect(uploaded!.width, 52);
    expect(uploaded.height, 52);
  });

  testWidgets(
    'color toggles reuse local cut metadata without requesting cut_pixel again',
    (WidgetTester tester) async {
      final _FakePixelPadApiService api = _FakePixelPadApiService();
      final _UploadRecorder recorder = _UploadRecorder();
      recorder.uploaded.clear();
      expect(recorder.service.isConnected, isTrue);
      final Uint16List mapping = Uint16List(50 * 52);
      for (int index = 0; index < mapping.length; index += 2) {
        mapping[index] = 1;
        if (index + 1 < mapping.length) {
          mapping[index + 1] = 2;
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MakeResultScreen(
            sessionId: 'session-1',
            width: 50,
            height: 52,
            mapping: mapping,
            bgMask: Uint8List.fromList(List<int>.filled(50 * 52, 0)),
            palette: const <PaletteColorEntry>[
              PaletteColorEntry(
                idx: 1,
                id: 'A1',
                count: 1300,
                rgba: <int>[255, 0, 0, 255],
                hex: '#ff0000',
              ),
              PaletteColorEntry(
                idx: 2,
                id: 'B2',
                count: 1300,
                rgba: <int>[0, 255, 0, 255],
                hex: '#00ff00',
              ),
            ],
            api: api,
            btService: recorder.service,
          ),
        ),
      );

      await _pumpForAsyncWork(tester);
      expect(api.cutPixelCalls, 1);
      expect(recorder.uploaded, hasLength(1));

      await tester.ensureVisible(find.text('A1').last);
      await tester.tap(find.text('A1').last);
      await _pumpForAsyncWork(tester);

      expect(api.cutPixelCalls, 1);
      expect(recorder.uploaded, hasLength(2));
      final img.Image? uploaded = img.decodePng(recorder.uploaded.last);
      expect(uploaded, isNotNull);
      final img.Pixel filtered = uploaded!.getPixel(2, 0);
      expect(filtered.r.toInt(), 0);
      expect(filtered.g.toInt(), 0);
      expect(filtered.b.toInt(), 0);
    },
  );

  testWidgets('retries cut_pixel after an initial prefetch failure', (
    WidgetTester tester,
  ) async {
    final _FakePixelPadApiService api = _FakePixelPadApiService(
      failCutPixelTimes: 1,
    );
    final _UploadRecorder recorder = _UploadRecorder();
    recorder.uploaded.clear();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MakeResultScreen(
          sessionId: 'session-1',
          width: 50,
          height: 52,
          mapping: Uint16List.fromList(List<int>.filled(50 * 52, 1)),
          bgMask: Uint8List.fromList(List<int>.filled(50 * 52, 0)),
          palette: const <PaletteColorEntry>[
            PaletteColorEntry(
              idx: 1,
              id: 'A1',
              count: 50 * 52,
              rgba: <int>[255, 0, 0, 255],
              hex: '#ff0000',
            ),
          ],
          api: api,
          btService: recorder.service,
        ),
      ),
    );

    await _pumpForAsyncWork(tester);
    expect(api.cutPixelCalls, 1);
    expect(recorder.uploaded, isEmpty);

    await tester.ensureVisible(find.text('A1').last);
    await tester.tap(find.text('A1').last);
    await _pumpForAsyncWork(tester);

    expect(api.cutPixelCalls, 2);
    expect(recorder.uploaded, hasLength(1));
  });
}

class _FakePixelPadApiService extends PixelPadApiService {
  _FakePixelPadApiService({this.failCutPixelTimes = 0}) : super(client: null);

  int cutPixelCalls = 0;
  int failCutPixelTimes;

  @override
  Future<CutPixelResult> cutPixel({
    required String sessionId,
    int tileSize = 52,
  }) async {
    cutPixelCalls += 1;
    if (cutPixelCalls <= failCutPixelTimes) {
      throw Exception('cut_pixel_failed:500');
    }
    return const CutPixelResult(
      sessionId: 'session-1',
      inputWidth: 50,
      inputHeight: 52,
      targetWidth: 52,
      targetHeight: 52,
      tileSize: 52,
      cols: 1,
      rows: 1,
      crop: <int>[0, 0, 0, 0],
      padding: <int>[1, 1, 0, 0],
      canvasBase64: '',
      tilesBase64: <String>[],
    );
  }
}

class _UploadRecorder {
  _UploadRecorder() : service = _FakeDeviceImageUploader(onUpload: _onUpload);

  static final List<Uint8List> _sharedUploaded = <Uint8List>[];

  final DeviceImageUploader service;

  List<Uint8List> get uploaded => _sharedUploaded;

  static Future<void> _onUpload(
    Uint8List pngBytes,
    void Function(double progress) onProgress,
  ) async {
    _sharedUploaded.add(Uint8List.fromList(pngBytes));
    onProgress(1.0);
  }
}

class _FakeDeviceImageUploader implements DeviceImageUploader {
  _FakeDeviceImageUploader({required this.onUpload});

  final Future<void> Function(
    Uint8List pngBytes,
    void Function(double progress) onProgress,
  )
  onUpload;

  @override
  bool get isConnected => true;

  @override
  String get deviceName => 'Test Device';

  @override
  Future<void> uploadImage(
    Uint8List pngBytes,
    void Function(double progress) onProgress,
  ) {
    return onUpload(pngBytes, onProgress);
  }
}

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  for (int i = 0; i < 120; i += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
