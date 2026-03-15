import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/make/data/make_pipeline_result.dart';
import 'package:pixelpad/features/make/data/make_pipeline_service.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';
import 'package:pixelpad/features/make/presentation/screens/make_parameter_screen.dart';

void main() {
  group('MakeParameterScreen', () {
    testWidgets('auto processes on first load and can confirm into result screen', (
      WidgetTester tester,
    ) async {
      final _FakeMakePipelineService service = _FakeMakePipelineService();
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MakeParameterScreen(
            imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
            pipelineService: service,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await _pumpForAsyncWork(tester);

      expect(service.initializeSessionCalls, 1);
      expect(service.processCalls, 1);
      expect(find.text('确认参数'), findsOneWidget);

      final ElevatedButton confirmButton = tester.widget<ElevatedButton>(
        find.byKey(MakeParameterScreen.confirmButtonKey),
      );
      expect(confirmButton.onPressed, isNotNull);

      await tester.tap(find.byKey(MakeParameterScreen.confirmButtonKey));
      await _pumpForAsyncWork(tester);

      expect(find.text('存储到图库'), findsOneWidget);
      expect(service.processCalls, 1);
    });

    testWidgets('changing tolerance disables confirm until processing again', (
      WidgetTester tester,
    ) async {
      final _FakeMakePipelineService service = _FakeMakePipelineService();
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MakeParameterScreen(
            imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
            pipelineService: service,
          ),
        ),
      );
      await _pumpForAsyncWork(tester);

      final Slider slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(12);
      await tester.pump();

      ElevatedButton confirmButton = tester.widget<ElevatedButton>(
        find.byKey(MakeParameterScreen.confirmButtonKey),
      );
      expect(confirmButton.onPressed, isNull);

      await tester.tap(find.byKey(MakeParameterScreen.processButtonKey));
      await _pumpForAsyncWork(tester);

      confirmButton = tester.widget<ElevatedButton>(
        find.byKey(MakeParameterScreen.confirmButtonKey),
      );
      expect(confirmButton.onPressed, isNotNull);
      expect(service.processCalls, 2);
    });

    testWidgets('max colors picker opens and selecting a new value marks screen dirty', (
      WidgetTester tester,
    ) async {
      final _FakeMakePipelineService service = _FakeMakePipelineService();
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: MakeParameterScreen(
            imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
            pipelineService: service,
          ),
        ),
      );
      await _pumpForAsyncWork(tester);

      await tester.tap(find.byKey(MakeParameterScreen.maxColorsCardKey));
      await _pumpForAsyncWork(tester);

      expect(find.text('选择最大颜色数'), findsOneWidget);
      expect(find.text('24'), findsWidgets);

      await tester.drag(find.byType(PageView).last, const Offset(-300, 0));
      await _pumpForAsyncWork(tester);
      await tester.tap(find.widgetWithText(ElevatedButton, '确认'));
      await _pumpForAsyncWork(tester);

      final ElevatedButton confirmButton = tester.widget<ElevatedButton>(
        find.byKey(MakeParameterScreen.confirmButtonKey),
      );
      expect(confirmButton.onPressed, isNull);
      expect(service.processCalls, 1);
    });
  });
}

class _FakeMakePipelineService extends MakePipelineService {
  _FakeMakePipelineService()
    : super(api: null);

  int initializeSessionCalls = 0;
  int processCalls = 0;

  @override
  Future<MakePipelineSession> initializeSession({
    required Uint8List imageBytes,
    required String settingsFile,
  }) async {
    initializeSessionCalls += 1;
    return MakePipelineSession(
      sessionId: 'session-1',
      perfectPixelRgba: Uint8List(0),
      width: 2,
      height: 2,
      perfectWidth: 2,
      perfectHeight: 2,
    );
  }

  @override
  Future<MakePipelineResult> processWithParameters({
    required String sessionId,
    required int sessionWidth,
    required int sessionHeight,
    required int perfectWidth,
    required int perfectHeight,
    required int maxColors,
    required int tolerance,
  }) async {
    processCalls += 1;
    return MakePipelineResult(
      mapping: Uint16List.fromList(<int>[1, 2, 0, 1]),
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
          count: 1,
          rgba: <int>[0, 255, 0, 255],
          hex: '#00ff00',
        ),
      ],
      bgMask: Uint8List.fromList(<int>[0, 0, 1, 0]),
      width: 2,
      height: 2,
      maxColors: maxColors,
      backgroundTolerance: tolerance,
    );
  }
}

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  for (int i = 0; i < 8; i += 1) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
