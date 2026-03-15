import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:image/image.dart' as img;

// Nordic UART Service (NUS) UUIDs，与 ESP32 固件约定一致。
const String _nusServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const String _nusRxUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // 手机 -> 硬件
const String _nusTxUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // 硬件 -> 手机
const int _pixelChunkSize = 240;
const int _pixelChunkDelayMs = 5;

abstract interface class DeviceImageUploader {
  bool get isConnected;
  String get deviceName;

  Future<void> uploadImage(
    Uint8List pngBytes,
    void Function(double) onProgress,
  );
}

/// 管理蓝牙连接和图片传输的全局单例。
///
/// 首页 HeroCard 点击时调用 connect() 建立连接，
/// MakeResultScreen 确认按钮直接调用 uploadImage() 传输数据。
class BluetoothTransferService implements DeviceImageUploader {
  static final BluetoothTransferService _instance =
      BluetoothTransferService._internal();
  factory BluetoothTransferService() => _instance;
  BluetoothTransferService._internal()
    : _isConnectedOverride = null,
      _deviceNameOverride = null,
      _uploadOverride = null;

  BluetoothTransferService.test({
    bool isConnected = false,
    String deviceName = '',
    required Future<void> Function(
      Uint8List pngBytes,
      void Function(double) onProgress,
    )
    onUpload,
  }) : _isConnectedOverride = isConnected,
       _deviceNameOverride = deviceName,
       _uploadOverride = onUpload;

  final bool? _isConnectedOverride;
  final String? _deviceNameOverride;
  final Future<void> Function(
    Uint8List pngBytes,
    void Function(double) onProgress,
  )?
  _uploadOverride;

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;

  /// 当前已连接的设备，null 表示未连接。
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// 是否已连接设备。
  bool get isConnected =>
      _isConnectedOverride ??
      (_connectedDevice != null && _writeCharacteristic != null);

  /// 已连接设备的名称。
  String get deviceName =>
      _deviceNameOverride ?? (_connectedDevice?.platformName ?? '');

  /// 连接状态变化通知。
  final ValueNotifier<bool> connectionNotifier = ValueNotifier<bool>(false);

  /// 连接到指定蓝牙设备并发现可写特征。
  Future<void> connect(BluetoothDevice device) async {
    // 断开旧连接
    await disconnect();

    await device.connect(license: License.free, autoConnect: false);
    _connectedDevice = device;

    if (Platform.isAndroid) {
      try {
        await device.requestMtu(512);
      } catch (_) {}
    }

    final services = await device.discoverServices();
    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    // 优先按 NUS UUID 精确匹配，保证连接正确的特征。
    for (final service in services) {
      final serviceUuid = service.serviceUuid.str.toLowerCase();
      for (final c in service.characteristics) {
        final cUuid = c.characteristicUuid.str.toLowerCase();
        if (serviceUuid == _nusServiceUuid && cUuid == _nusRxUuid) {
          _writeCharacteristic = c;
        }
        if (serviceUuid == _nusServiceUuid && cUuid == _nusTxUuid) {
          _notifyCharacteristic = c;
        }
      }
    }

    // 若设备不使用标准 NUS UUID，退而按属性匹配（兼容性 fallback）。
    if (_writeCharacteristic == null) {
      for (final service in services) {
        for (final c in service.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            _writeCharacteristic ??= c;
          }
          if (c.properties.notify || c.properties.indicate) {
            _notifyCharacteristic ??= c;
          }
        }
      }
    }

    if (_writeCharacteristic == null) {
      await disconnect();
      throw Exception('未找到可写特征，请确认设备兼容性');
    }

    // 监听断开事件
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectedDevice = null;
        _writeCharacteristic = null;
        _notifyCharacteristic = null;
        connectionNotifier.value = false;
      }
    });

    connectionNotifier.value = true;
  }

  /// 断开当前设备连接。
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
      _writeCharacteristic = null;
      _notifyCharacteristic = null;
      connectionNotifier.value = false;
    }
  }

  /// 将 52x52 PNG 图片转为 RGB 字节流并通过蓝牙发送到设备。
  ///
  /// Args:
  ///   pngBytes: 52x52 PNG 图片的原始字节。
  ///   onProgress: 进度回调，范围 0.0 ~ 1.0。
  Future<void> uploadImage(
    Uint8List pngBytes,
    void Function(double) onProgress,
  ) async {
    if (_uploadOverride != null) {
      await _uploadOverride(pngBytes, onProgress);
      return;
    }
    if (!isConnected) {
      throw Exception('设备未连接，请先在首页连接蓝牙设备');
    }

    onProgress(0.1);
    final rgbBytes = _convertToRgb52x52(pngBytes);
    final characteristic = _writeCharacteristic!;
    final supportsWithResponse = characteristic.properties.write;
    final supportsWithoutResponse =
        characteristic.properties.writeWithoutResponse;
    if (!supportsWithResponse && !supportsWithoutResponse) {
      throw Exception('设备特征不支持写入，请重新连接设备');
    }

    // 第一步：握手
    onProgress(0.2);
    final handshakeCmd = '{"cmd":"recv","size":${rgbBytes.length}}\n';
    await characteristic.write(
      utf8.encode(handshakeCmd),
      // 与 pixel 实现对齐：握手优先使用有响应写。
      withoutResponse: !supportsWithResponse && supportsWithoutResponse,
    );

    // 延时 50ms
    await Future.delayed(const Duration(milliseconds: 50));

    // 第二步：固定 240 字节分包发送 RGB 数据（与 pixel 一致）。
    onProgress(0.3);
    int sent = 0;

    while (sent < rgbBytes.length) {
      int end = sent + _pixelChunkSize;
      if (end > rgbBytes.length) end = rgbBytes.length;
      final chunk = rgbBytes.sublist(sent, end);

      await characteristic.write(
        chunk,
        // 与 pixel 实现对齐：图片数据包使用无响应写，必要时降级为有响应写。
        withoutResponse: supportsWithoutResponse,
      );

      sent = end;
      onProgress(0.3 + 0.6 * (sent / rgbBytes.length));
      await Future.delayed(const Duration(milliseconds: _pixelChunkDelayMs));
    }

    onProgress(1.0);
  }

  /// 将 PNG 图片解码为 52x52 的 RGB 字节流（8112 bytes）。
  Uint8List _convertToRgb52x52(Uint8List pngBytes) {
    final image = img.decodeImage(pngBytes);
    if (image == null) throw Exception('图片解码失败');
    if (image.width != 52 || image.height != 52) {
      throw Exception('图片必须是 52x52 像素');
    }

    final rgbBytes = Uint8List(52 * 52 * 3);
    int i = 0;
    for (final p in image) {
      rgbBytes[i++] = p.r.toInt();
      rgbBytes[i++] = p.g.toInt();
      rgbBytes[i++] = p.b.toInt();
    }
    return rgbBytes;
  }
}
