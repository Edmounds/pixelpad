import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:pixelpad/features/make/data/hardware_upload_image.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

void main() {
  test('renderHardwareUploadPng always produces a 52x52 PNG', () async {
    final Uint8List pngBytes = await renderHardwareUploadPng(
      width: 50,
      height: 52,
      mapping: Uint16List.fromList(List<int>.filled(50 * 52, 1)),
      palette: const <PaletteColorEntry>[
        PaletteColorEntry(
          idx: 1,
          id: 'A1',
          count: 50 * 52,
          rgba: <int>[255, 0, 0, 255],
          hex: '#ff0000',
        ),
      ],
      bgMask: Uint8List.fromList(List<int>.filled(50 * 52, 0)),
      metadata: const HardwareCutMetadata(
        inputWidth: 50,
        inputHeight: 52,
        targetWidth: 52,
        targetHeight: 52,
        cropLeft: 0,
        cropRight: 0,
        cropTop: 0,
        cropBottom: 0,
        padLeft: 1,
        padRight: 1,
        padTop: 0,
        padBottom: 0,
      ),
    );

    final img.Image? image = img.decodePng(pngBytes);
    expect(image, isNotNull);
    expect(image!.width, 52);
    expect(image.height, 52);
  });

  test(
    'renderHardwareUploadPng turns unselected colors into black pixels',
    () async {
      final Uint16List mapping = Uint16List(52 * 52);
      mapping[0] = 1;
      mapping[1] = 2;
      final Uint8List pngBytes = await renderHardwareUploadPng(
        width: 52,
        height: 52,
        mapping: mapping,
        palette: const <PaletteColorEntry>[
          PaletteColorEntry(
            idx: 1,
            id: 'A1',
            count: 1,
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
        bgMask: Uint8List.fromList(List<int>.filled(52 * 52, 0)),
        metadata: const HardwareCutMetadata(
          inputWidth: 52,
          inputHeight: 52,
          targetWidth: 52,
          targetHeight: 52,
          cropLeft: 0,
          cropRight: 0,
          cropTop: 0,
          cropBottom: 0,
          padLeft: 0,
          padRight: 0,
          padTop: 0,
          padBottom: 0,
        ),
        selectedIndices: <int>{1},
      );

      final img.Image? image = img.decodePng(pngBytes);
      expect(image, isNotNull);
      final img.Pixel selected = image!.getPixel(0, 0);
      final img.Pixel unselected = image.getPixel(1, 0);
      expect(selected.r.toInt(), 255);
      expect(selected.g.toInt(), 0);
      expect(selected.b.toInt(), 0);
      expect(unselected.r.toInt(), 0);
      expect(unselected.g.toInt(), 0);
      expect(unselected.b.toInt(), 0);
      expect(unselected.a.toInt(), 255);
    },
  );
}
