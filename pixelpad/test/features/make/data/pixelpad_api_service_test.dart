import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

void main() {
  test('ColorMapResult preserves palette entry ids and idx values', () {
    final ColorMapResult result = ColorMapResult.fromJson(<String, dynamic>{
      'width': 2,
      'height': 2,
      'mapping_u16le_base64': '',
      'palette': <Map<String, dynamic>>[
        <String, dynamic>{
          'idx': 7,
          'id': 'H2',
          'count': 12,
          'rgba': <int>[250, 250, 250, 255],
          'hex': '#fafafa',
        },
        <String, dynamic>{
          'idx': 9,
          'id': 'C7',
          'count': 8,
          'rgba': <int>[57, 119, 204, 255],
        },
      ],
    });

    expect(result.palette, hasLength(2));
    expect(result.palette[0].idx, 7);
    expect(result.palette[0].id, 'H2');
    expect(result.palette[0].count, 12);
    expect(result.palette[0].rgba, <int>[250, 250, 250, 255]);
    expect(result.palette[1].idx, 9);
    expect(result.palette[1].id, 'C7');
    expect(result.palette[1].hex, '#3977cc');
  });

  test('removeBackground sends tolerance and crop flags', () async {
    late Uri capturedUri;
    late Map<String, String> capturedFields;
    final http.Client client = MockClient((http.Request request) async {
      capturedUri = request.url;
      capturedFields = request.bodyFields;
      return http.Response(
        jsonEncode(<String, dynamic>{
          'width': 2,
          'height': 2,
          'bg_mask_rle_u32le_base64': '',
          'bg_mask_start': false,
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });

    final PixelPadApiService service = PixelPadApiService(
      client: client,
      baseUrl: 'https://example.test',
    );

    await service.removeBackground(
      sessionId: 'session-1',
      tolerance: 17,
      tightCrop: true,
      previewOnly: false,
    );

    expect(capturedUri.toString(), 'https://example.test/remove_background');
    expect(capturedFields['session_id'], 'session-1');
    expect(capturedFields['tolerance'], '17');
    expect(capturedFields['tight_crop'], 'true');
    expect(capturedFields['preview_only'], 'false');
  });

  test('cutPixel sends session_id and tile_size and parses response', () async {
    late Uri capturedUri;
    late Map<String, String> capturedFields;
    final http.Client client = MockClient((http.Request request) async {
      capturedUri = request.url;
      capturedFields = request.bodyFields;
      return http.Response(
        jsonEncode(<String, dynamic>{
          'session_id': 'session-1',
          'input_width': 50,
          'input_height': 52,
          'target_width': 52,
          'target_height': 52,
          'tile_size': 52,
          'cols': 1,
          'rows': 1,
          'crop': <int>[0, 0, 0, 0],
          'padding': <int>[1, 1, 0, 0],
          'canvas_base64': 'ZmFrZS1jYW52YXM=',
          'tiles_base64': <String>['ZmFrZS10aWxl'],
        }),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    });

    final dynamic service = PixelPadApiService(
      client: client,
      baseUrl: 'https://example.test',
    );

    final dynamic result = await service.cutPixel(
      sessionId: 'session-1',
      tileSize: 52,
    );

    expect(capturedUri.toString(), 'https://example.test/cut_pixel');
    expect(capturedFields['session_id'], 'session-1');
    expect(capturedFields['tile_size'], '52');
    expect(result.sessionId, 'session-1');
    expect(result.inputWidth, 50);
    expect(result.inputHeight, 52);
    expect(result.targetWidth, 52);
    expect(result.targetHeight, 52);
    expect(result.tileSize, 52);
    expect(result.cols, 1);
    expect(result.rows, 1);
    expect(result.crop, <int>[0, 0, 0, 0]);
    expect(result.padding, <int>[1, 1, 0, 0]);
    expect(result.canvasBase64, 'ZmFrZS1jYW52YXM=');
    expect(result.tilesBase64, <String>['ZmFrZS10aWxl']);
  });
}
