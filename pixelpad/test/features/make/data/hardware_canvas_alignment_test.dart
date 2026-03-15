import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:pixelpad/features/make/data/hardware_upload_image.dart';

void main() {
  test('aligns 50x52 content into a 52x52 hardware canvas using padding', () {
    final AlignedHardwareFrame aligned = alignToHardwareCanvas(
      width: 50,
      height: 52,
      mapping: Uint16List.fromList(List<int>.filled(50 * 52, 7)),
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

    expect(aligned.width, 52);
    expect(aligned.height, 52);
    expect(aligned.mapping.length, 52 * 52);
    expect(aligned.bgMask.length, 52 * 52);
    expect(aligned.mapping[0], 0);
    expect(aligned.bgMask[0], 1);
    expect(aligned.mapping[1], 7);
    expect(aligned.bgMask[1], 0);
    expect(aligned.mapping[51], 0);
    expect(aligned.bgMask[51], 1);
  });

  test('applies crop before padding when building the hardware canvas', () {
    final List<int> values = List<int>.generate(
      54 * 52,
      (int index) => index % 54,
    );
    final AlignedHardwareFrame aligned = alignToHardwareCanvas(
      width: 54,
      height: 52,
      mapping: Uint16List.fromList(values),
      bgMask: Uint8List.fromList(List<int>.filled(54 * 52, 0)),
      metadata: const HardwareCutMetadata(
        inputWidth: 54,
        inputHeight: 52,
        targetWidth: 52,
        targetHeight: 52,
        cropLeft: 1,
        cropRight: 1,
        cropTop: 0,
        cropBottom: 0,
        padLeft: 0,
        padRight: 0,
        padTop: 0,
        padBottom: 0,
      ),
    );

    expect(aligned.width, 52);
    expect(aligned.height, 52);
    expect(aligned.mapping.first, 1);
    expect(aligned.mapping[51], 52);
  });
}
