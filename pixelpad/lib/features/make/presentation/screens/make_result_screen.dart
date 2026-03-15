import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/device/domain/services/bluetooth_service.dart';
import 'package:pixelpad/features/make/data/hardware_upload_image.dart';
import 'package:pixelpad/features/make/data/pixel_renderer.dart';
import 'package:pixelpad/features/make/data/pixelpad_api_service.dart';

class MakeResultScreen extends StatefulWidget {
  final String sessionId;
  final Uint16List mapping;
  final List<PaletteColorEntry> palette;
  final Uint8List bgMask;
  final int width;
  final int height;
  final PixelPadApiService? api;
  final DeviceImageUploader? btService;

  const MakeResultScreen({
    super.key,
    required this.sessionId,
    required this.mapping,
    required this.palette,
    required this.bgMask,
    required this.width,
    required this.height,
    this.api,
    this.btService,
  });

  @override
  State<MakeResultScreen> createState() => _MakeResultScreenState();
}

class _MakeResultScreenState extends State<MakeResultScreen> {
  Uint8List? _imageBytes;
  bool _loading = false;
  String? _error;
  final Set<int> _selected = <int>{};
  late final DeviceImageUploader _btService;
  late final PixelPadApiService _api;
  bool _btUploading = false;
  int _renderVersion = 0;
  Future<HardwareCutMetadata>? _hardwareMetadataFuture;
  int? _queuedUploadVersion;
  int _uploadVersion = 0;

  List<_ColorToken> get _tokens => List<_ColorToken>.generate(
    widget.palette.length,
    (int index) => _ColorToken(
      index: widget.palette[index].idx,
      label: widget.palette[index].id,
      color: _colorFromRgba(widget.palette[index].rgba),
    ),
  );

  @override
  void initState() {
    super.initState();
    _btService = widget.btService ?? BluetoothTransferService();
    _api = widget.api ?? PixelPadApiService();
    _ensureHardwareMetadataFuture();
    _renderLocalImage();
    _queueHardwareUpload();
  }

  Future<HardwareCutMetadata> _ensureHardwareMetadataFuture() {
    final Future<HardwareCutMetadata>? existing = _hardwareMetadataFuture;
    if (existing != null) {
      return existing;
    }

    final Future<HardwareCutMetadata> future = _prefetchHardwareMetadata();
    future.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {
        if (identical(_hardwareMetadataFuture, future)) {
          _hardwareMetadataFuture = null;
        }
      },
    );
    _hardwareMetadataFuture = future;
    return future;
  }

  Future<HardwareCutMetadata> _prefetchHardwareMetadata() async {
    final CutPixelResult result = await _api.cutPixel(
      sessionId: widget.sessionId,
      tileSize: 52,
    );
    if (result.targetWidth != 52 ||
        result.targetHeight != 52 ||
        result.cols != 1 ||
        result.rows != 1) {
      throw Exception('当前作品不是单个52x52设备画布，无法直接同步到设备');
    }
    return HardwareCutMetadata.fromCutPixelResult(result);
  }

  Future<void> _renderLocalImage() async {
    final int currentVersion = ++_renderVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Uint8List? imageBytes = await renderPixelPng(
        width: widget.width,
        height: widget.height,
        mapping: widget.mapping,
        palette: widget.palette,
        bgMask: widget.bgMask,
        selectedIndices: _selected.isEmpty ? null : Set<int>.from(_selected),
      );
      if (imageBytes == null) {
        throw Exception('render_empty');
      }
      if (!mounted || currentVersion != _renderVersion) {
        return;
      }
      setState(() {
        _imageBytes = imageBytes;
      });
    } catch (_) {
      if (!mounted || currentVersion != _renderVersion) {
        return;
      }
      setState(() {
        _error = '渲染失败';
      });
    } finally {
      if (mounted && currentVersion == _renderVersion) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<Uint8List> _buildHardwareUploadBytes() async {
    final HardwareCutMetadata metadata = await _ensureHardwareMetadataFuture();
    return renderHardwareUploadPng(
      width: widget.width,
      height: widget.height,
      mapping: widget.mapping,
      palette: widget.palette,
      bgMask: widget.bgMask,
      metadata: metadata,
      selectedIndices: _selected.isEmpty ? null : Set<int>.from(_selected),
    );
  }

  void _queueHardwareUpload() {
    if (!_btService.isConnected) {
      return;
    }
    _queuedUploadVersion = ++_uploadVersion;
    if (_btUploading) {
      return;
    }
    _drainQueuedUploads();
  }

  /// 蓝牙已连接时，静默将图片上传到设备。失败仅 SnackBar 提示，不阻断操作。
  Future<void> _drainQueuedUploads() async {
    if (!_btService.isConnected || _btUploading) {
      return;
    }
    final int? currentQueue = _queuedUploadVersion;
    if (currentQueue == null) {
      return;
    }
    _queuedUploadVersion = null;
    setState(() {
      _btUploading = true;
    });
    try {
      final Uint8List imageBytes = await _buildHardwareUploadBytes();
      await _btService.uploadImage(imageBytes, (_) {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已同步到设备'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('同步失败: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _btUploading = false;
        });
      }
      if (_queuedUploadVersion != null &&
          _queuedUploadVersion != currentQueue) {
        _drainQueuedUploads();
      }
    }
  }

  void _toggleColor(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
    _renderLocalImage();
    _queueHardwareUpload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _ResultHeader(onBack: () => Navigator.of(context).pop()),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF404040), height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ResultPreviewCard(
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: SizedBox.expand(
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  isAntiAlias: false,
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _error ?? '暂无预览',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF9A9A9A),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Transform.translate(
                      offset: const Offset(0, -24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _ColorsSection(
                          tokens: _tokens,
                          selected: _selected,
                          onToggle: _toggleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: '存储到图库',
                              background: const Color(0xFF2E2E2E),
                              borderColor: const Color(0xFF6C6C6C),
                              textColor: AppColors.white,
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: '确认',
                              background: const Color(0xFF2E2E2E),
                              borderColor: const Color(0xFF6C6C6C),
                              textColor: AppColors.white,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _ResultHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Row(
                children: const [
                  Icon(Icons.chevron_left, color: AppColors.primary),
                  SizedBox(width: 2),
                  Text(
                    '返回',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          const _HeaderIcon(asset: 'assets/source/icon_search.svg'),
          const SizedBox(width: 14),
          const _HeaderIcon(asset: 'assets/source/icon_bell.svg'),
          const SizedBox(width: 14),
          const Icon(Icons.person, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final String asset;

  const _HeaderIcon({required this.asset});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: 18,
      height: 18,
      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    );
  }
}

class _ResultPreviewCard extends StatelessWidget {
  final Widget child;

  const _ResultPreviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double horizontalPadding = 32;
    final double height = width - horizontalPadding * 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppColors.header),
      child: SizedBox(height: height, child: child),
    );
  }
}

class _ColorsSection extends StatelessWidget {
  final List<_ColorToken> tokens;
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _ColorsSection({
    required this.tokens,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionPill(label: 'Colors'),
        const SizedBox(height: 12),
        if (tokens.isEmpty)
          const Text(
            '暂无颜色数据',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9A9A9A),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: tokens
                .map(
                  (token) => _ColorTokenChip(
                    label: token.label,
                    color: token.color,
                    selected: selected.contains(token.index),
                    onTap: () => onToggle(token.index),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _SectionPill extends StatelessWidget {
  final String label;

  const _SectionPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.header, width: 1),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF9F871),
        ),
      ),
    );
  }
}

class _ColorToken {
  final int index;
  final String label;
  final Color color;

  const _ColorToken({
    required this.index,
    required this.label,
    required this.color,
  });
}

class _ColorTokenChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorTokenChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: AppColors.white,
                  width: selected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            if (selected)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F26B),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1A1A1A),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

Color _colorFromRgba(List<int> rgba) {
  final int r = rgba.isNotEmpty ? rgba[0].clamp(0, 255).toInt() : 0;
  final int g = rgba.length > 1 ? rgba[1].clamp(0, 255).toInt() : 0;
  final int b = rgba.length > 2 ? rgba[2].clamp(0, 255).toInt() : 0;
  return Color.fromARGB(255, r, g, b);
}

/// 蓝牙传输进度对话框。
///
/// 直接使用已连接的设备传输数据，显示进度条和状态信息。
class _BluetoothUploadProgressDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final BluetoothTransferService btService;

  const _BluetoothUploadProgressDialog({
    required this.imageBytes,
    required this.btService,
  });

  @override
  State<_BluetoothUploadProgressDialog> createState() =>
      _BluetoothUploadProgressDialogState();
}

class _BluetoothUploadProgressDialogState
    extends State<_BluetoothUploadProgressDialog> {
  double _progress = 0.0;
  String _status = '准备传输...';
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startUpload();
  }

  Future<void> _startUpload() async {
    try {
      setState(() {
        _status = '正在传输数据到 ${widget.btService.deviceName}...';
      });
      await widget.btService.uploadImage(widget.imageBytes, (progress) {
        if (mounted) {
          setState(() {
            _progress = progress;
            if (progress >= 1.0) {
              _status = '传输完成！';
              _done = true;
            }
          });
        }
      });
      if (mounted && !_done) {
        setState(() {
          _status = '传输完成！';
          _done = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '传输失败: $e';
          _status = '传输失败';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '传输到设备',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF9F871),
              ),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
            Text(
              _status,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFF2E2E2E),
              color: const Color(0xFFF9F871),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (_done && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('已成功发送到设备！')));
                  }
                },
                child: Text(
                  _done || _error != null ? '关闭' : '取消',
                  style: const TextStyle(color: Color(0xFFF9F871)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
