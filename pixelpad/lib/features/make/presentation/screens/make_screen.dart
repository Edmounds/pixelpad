import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as picker;

import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/make/presentation/screens/bean_preset_screen.dart';
import 'package:pixelpad/features/make/presentation/screens/make_parameter_screen.dart';

const List<String> _galleryAssets = [
  'assets/source/community-example1.png',
  'assets/source/community-example2.png',
  'assets/source/community-example3.png',
  'assets/source/community-example4.png',
  'assets/source/home-example.png',
  'assets/source/34984974-8f37-43f5-a957-6f03905ebb1c.png',
  'assets/source/a5f69544-ad63-48ff-a53d-4fb5d974e6b4.png',
  'assets/source/mygallery.png',
];

class MakeScreen extends StatelessWidget {
  const MakeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [_MakeHeader(), SizedBox(height: 18), _MakeBody()],
        ),
      ),
    );
  }
}

class _MakeHeader extends StatelessWidget {
  const _MakeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.arrow,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '图片制作',
          style: AppTextStyles.pageTitle.copyWith(color: AppColors.primary),
        ),
        const Spacer(),
        const _HeaderIcon(asset: 'assets/source/icon_search.svg', size: 20),
        const SizedBox(width: 16),
        const _HeaderIcon(asset: 'assets/source/icon_bell.svg', size: 20),
        const SizedBox(width: 16),
        const _HeaderIcon(asset: 'assets/source/icon_settings.svg', size: 20),
      ],
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final String asset;
  final double size;

  const _HeaderIcon({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

class _MakeBody extends StatelessWidget {
  const _MakeBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择图纸',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFF9F871),
          ),
        ),
        const SizedBox(height: 10),
        Divider(color: AppColors.white.withValues(alpha: 0.7), height: 1),
        const SizedBox(height: 16),
        _MakeOptionCard(
          title: '上传图片',
          subtitle: '上传图片以创建图纸',
          icon: 'assets/source/icon_upload.svg',
          image: 'assets/source/upload.png',
          onTap: () => _showUploadOptions(context),
        ),
        const SizedBox(height: 16),
        Divider(color: AppColors.white.withValues(alpha: 0.7), height: 1),
        const SizedBox(height: 16),
        const _MakeOptionCard(
          title: '编辑文本',
          subtitle: '编辑文本以创建图纸',
          icon: 'assets/source/icon_text.svg',
          image: 'assets/source/editword.png',
        ),
        const SizedBox(height: 16),
        Divider(color: AppColors.white.withValues(alpha: 0.7), height: 1),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.header,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const _GalleryCard(),
        ),
      ],
    );
  }
}

class _MakeOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final String image;
  final VoidCallback? onTap;

  const _MakeOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(icon, width: 20, height: 20),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 120,
                height: 86,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(18),
                  ),
                  child: Container(
                    color: Colors.transparent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Image.asset(
                      image,
                      width: 84,
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF232323),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/source/icon_gallery.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '我的图库',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF9F871),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '收藏或设计你的图纸',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 110,
            height: 80,
            alignment: Alignment.centerRight,
            child: Image.asset(
              'assets/source/mygallery.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showUploadOptions(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _UploadOptionsSheet(
        onAlbumTap: () async {
          Navigator.of(sheetContext).pop();
          await _pickFromAlbum(context);
        },
        onLibraryTap: () async {
          Navigator.of(sheetContext).pop();
          if (!context.mounted) {
            return;
          }
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const _GalleryPickerScreen(),
            ),
          );
        },
      );
    },
  );
}

Future<void> _pickFromAlbum(BuildContext context) async {
  final picker.ImagePicker imagePicker = picker.ImagePicker();
  final picker.XFile? picked = await imagePicker.pickImage(
    source: picker.ImageSource.gallery,
  );
  if (picked == null) {
    return;
  }
  final Uint8List bytes = await picked.readAsBytes();
  if (!context.mounted) {
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => _ImageEditorScreen(bytes: bytes),
    ),
  );
}

class _UploadOptionsSheet extends StatelessWidget {
  final VoidCallback onAlbumTap;
  final VoidCallback onLibraryTap;

  const _UploadOptionsSheet({
    required this.onAlbumTap,
    required this.onLibraryTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFFBDA9FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择新建图纸的方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232323),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OptionButton(
                  label: '从相册导入',
                  textColor: const Color(0xFF896CFE),
                  fontWeight: FontWeight.w400,
                  background: AppColors.white,
                  onTap: onAlbumTap,
                ),
                _OptionButton(
                  label: '从图库导入',
                  textColor: const Color(0xFF232323),
                  fontWeight: FontWeight.w500,
                  background: const Color(0xFFF9F871),
                  onTap: onLibraryTap,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _PresetHintCard(
              onSettingsTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const BeanPresetScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetHintCard extends StatelessWidget {
  final VoidCallback onSettingsTap;

  const _PresetHintCard({required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFA48BF0),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onSettingsTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '调整豆子预设，以获得更好的创作体验',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDA9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/source/icon_settings.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF2D2148),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final FontWeight fontWeight;
  final Color background;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.textColor,
    required this.fontWeight,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle baseTextStyle =
        Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    return SizedBox(
      width: 136,
      height: 32,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: baseTextStyle.copyWith(
                fontSize: 20,
                height: 26 / 20,
                letterSpacing: -0.1,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GalleryPickerScreen extends StatelessWidget {
  const _GalleryPickerScreen();

  Future<void> _openAsset(BuildContext context, String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final Uint8List bytes = data.buffer.asUint8List();
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ImageEditorScreen(bytes: bytes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('从图库导入'),
        backgroundColor: AppColors.header,
      ),
      backgroundColor: const Color(0xFF1F1F1F),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _galleryAssets.length,
        itemBuilder: (context, index) {
          final String asset = _galleryAssets[index];
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openAsset(context, asset),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(asset, fit: BoxFit.cover),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImageEditorScreen extends StatefulWidget {
  final Uint8List bytes;

  const _ImageEditorScreen({required this.bytes});

  @override
  State<_ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<_ImageEditorScreen> {
  static const double _minCropSizeFactor = 0.15;
  static const double _handleSize = 18;

  Uint8List? _editedBytes;
  bool _processing = false;
  bool _uploading = false;
  bool _cropDirty = false;
  bool _isCropping = false;
  bool _hasCropRect = false;
  bool _isDrawingCrop = false;
  bool _isMovingCrop = false;
  Offset? _drawStartPx;
  Size _imageSize = const Size(1, 1);
  Rect _cropRectPx = const Rect.fromLTWH(0, 0, 1, 1);

  Uint8List get _displayBytes => _editedBytes ?? widget.bytes;

  @override
  void initState() {
    super.initState();
    _updateImageSize(_displayBytes);
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (ui.Image image) {
      completer.complete(image);
    });
    return completer.future;
  }

  Future<void> _updateImageSize(Uint8List bytes) async {
    final ui.Image image = await _decodeImage(bytes);
    if (!mounted) {
      return;
    }
    setState(() {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _resetCropRect();
    });
  }

  Rect _imageRectFor(Size container) {
    final FittedSizes fitted = applyBoxFit(
      BoxFit.contain,
      _imageSize,
      container,
    );
    final Size destination = fitted.destination;
    final Offset offset = Offset(
      (container.width - destination.width) / 2,
      (container.height - destination.height) / 2,
    );
    return offset & destination;
  }

  Rect _cropRectInView(Rect imageRect) {
    final double scale = imageRect.width / _imageSize.width;
    return Rect.fromLTWH(
      imageRect.left + _cropRectPx.left * scale,
      imageRect.top + _cropRectPx.top * scale,
      _cropRectPx.width * scale,
      _cropRectPx.height * scale,
    );
  }

  void _resetCropRect() {
    final double size = min(_imageSize.width, _imageSize.height) * 0.6;
    final double left = (_imageSize.width - size) / 2;
    final double top = (_imageSize.height - size) / 2;
    _cropRectPx = Rect.fromLTWH(left, top, size, size);
    _hasCropRect = false;
    _isDrawingCrop = false;
    _isMovingCrop = false;
    _drawStartPx = null;
  }

  void _updateCropForHandle(_CropHandle handle, Offset delta, Rect imageRect) {
    if (_imageSize.width <= 0 || _imageSize.height <= 0) {
      return;
    }
    final double scale = imageRect.width / _imageSize.width;
    final double dx = delta.dx / scale;
    final double dy = delta.dy / scale;
    final double minSize =
        min(_imageSize.width, _imageSize.height) * _minCropSizeFactor;

    double left = _cropRectPx.left;
    double top = _cropRectPx.top;
    double right = _cropRectPx.right;
    double bottom = _cropRectPx.bottom;

    switch (handle) {
      case _CropHandle.topLeft:
        left += dx;
        top += dy;
        break;
      case _CropHandle.topRight:
        right += dx;
        top += dy;
        break;
      case _CropHandle.bottomLeft:
        left += dx;
        bottom += dy;
        break;
      case _CropHandle.bottomRight:
        right += dx;
        bottom += dy;
        break;
    }

    left = left.clamp(0.0, right - minSize);
    top = top.clamp(0.0, bottom - minSize);
    right = right.clamp(left + minSize, _imageSize.width);
    bottom = bottom.clamp(top + minSize, _imageSize.height);

    setState(() {
      _cropRectPx = Rect.fromLTRB(left, top, right, bottom);
      _cropDirty = true;
      _hasCropRect = true;
    });
  }

  Offset _localInImageRectToImage(Offset localPoint, Rect imageRect) {
    final double scale = imageRect.width / _imageSize.width;
    return Offset(localPoint.dx / scale, localPoint.dy / scale);
  }

  Offset _clampImagePoint(Offset pointPx) {
    return Offset(
      pointPx.dx.clamp(0.0, _imageSize.width),
      pointPx.dy.clamp(0.0, _imageSize.height),
    );
  }

  void _startCropDrawing(Offset viewPoint, Rect imageRect) {
    if (!_isCropping) {
      return;
    }
    final Offset startPx = _clampImagePoint(
      _localInImageRectToImage(viewPoint, imageRect),
    );
    setState(() {
      _drawStartPx = startPx;
      _isDrawingCrop = true;
      _hasCropRect = true;
      _cropRectPx = Rect.fromLTWH(startPx.dx, startPx.dy, 0, 0);
      _cropDirty = true;
    });
  }

  void _updateCropDrawing(Offset viewPoint, Rect imageRect) {
    if (!_isDrawingCrop || _drawStartPx == null) {
      return;
    }
    final Offset currentPx = _clampImagePoint(
      _localInImageRectToImage(viewPoint, imageRect),
    );
    final double dx = currentPx.dx - _drawStartPx!.dx;
    final double dy = currentPx.dy - _drawStartPx!.dy;
    if (dx <= 0 || dy <= 0) {
      setState(() {
        _cropRectPx = Rect.fromLTWH(_drawStartPx!.dx, _drawStartPx!.dy, 0, 0);
      });
      return;
    }
    double w = dx;
    double h = dy;
    w = min(w, _imageSize.width - _drawStartPx!.dx);
    h = min(h, _imageSize.height - _drawStartPx!.dy);
    setState(() {
      _cropRectPx = Rect.fromLTWH(_drawStartPx!.dx, _drawStartPx!.dy, w, h);
    });
  }

  void _finishCropDrawing() {
    if (!_isDrawingCrop) {
      return;
    }
    final double minSize =
        min(_imageSize.width, _imageSize.height) * _minCropSizeFactor;
    if (_cropRectPx.width < minSize || _cropRectPx.height < minSize) {
      setState(() {
        _hasCropRect = false;
        _cropRectPx = const Rect.fromLTWH(0, 0, 1, 1);
        _cropDirty = false;
      });
    }
    setState(() {
      _isDrawingCrop = false;
      _drawStartPx = null;
    });
  }

  void _startCropMove(Offset viewPoint, Rect imageRect) {
    if (!_hasCropRect || !_isCropping) {
      return;
    }
    setState(() {
      _isMovingCrop = true;
    });
  }

  void _updateCropMove(Offset delta, Rect imageRect) {
    if (!_isMovingCrop) {
      return;
    }
    final double scale = imageRect.width / _imageSize.width;
    final double dx = delta.dx / scale;
    final double dy = delta.dy / scale;
    double newLeft = _cropRectPx.left + dx;
    double newTop = _cropRectPx.top + dy;
    newLeft = newLeft.clamp(0.0, _imageSize.width - _cropRectPx.width);
    newTop = newTop.clamp(0.0, _imageSize.height - _cropRectPx.height);
    setState(() {
      _cropRectPx = Rect.fromLTWH(
        newLeft,
        newTop,
        _cropRectPx.width,
        _cropRectPx.height,
      );
      _cropDirty = true;
    });
  }

  void _finishCropMove() {
    if (!_isMovingCrop) {
      return;
    }
    setState(() {
      _isMovingCrop = false;
    });
  }

  Future<void> _runEdit(img.Command command) async {
    if (_processing) {
      return;
    }
    setState(() {
      _processing = true;
    });

    Uint8List? result;
    Object? error;
    try {
      final Uint8List source = _displayBytes;
      result = await Future.microtask(() async {
        command.decodeImage(source);
        await command.execute();
        final img.Image? edited = command.outputImage;
        if (edited == null) return null;
        return Uint8List.fromList(img.encodePng(edited));
      });
    } catch (e) {
      error = e;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _processing = false;
      if (result != null) {
        _editedBytes = result;
      }
    });

    if (result != null) {
      await _updateImageSize(result);
    }
    if (!mounted) {
      return;
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('处理失败，请重试')));
    }
  }

  Future<void> _applyCrop() async {
    if (!_hasCropRect) {
      return;
    }
    final int x = _cropRectPx.left.round();
    final int y = _cropRectPx.top.round();
    final int w = _cropRectPx.width.round();
    final int h = _cropRectPx.height.round();

    final cmd = img.Command()..copyCrop(x: x, y: y, width: w, height: h);
    await _runEdit(cmd);

    if (mounted) {
      setState(() {
        _cropDirty = false;
      });
    }
  }

  Future<Uint8List?> _buildCroppedBytes(Uint8List source) async {
    return Future.microtask(() {
      final img.Image? decoded = img.decodeImage(source);
      if (decoded == null) return null;
      final int x = _cropRectPx.left.round();
      final int y = _cropRectPx.top.round();
      final int w = _cropRectPx.width.round();
      final int h = _cropRectPx.height.round();
      final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      return Uint8List.fromList(img.encodePng(cropped));
    });
  }

  Future<void> _applyScale() async {
    final cmd = img.Command()
      ..copyResize(width: (_imageSize.width * 0.8).round());
    await _runEdit(cmd);
  }

  Future<void> _applyGrayFilter() async {
    final cmd = img.Command()..grayscale();
    await _runEdit(cmd);
  }

  Future<void> _applySepiaFilter() async {
    final cmd = img.Command()..sepia();
    await _runEdit(cmd);
  }

  void _resetEdits() {
    setState(() {
      _editedBytes = null;
      _resetCropRect();
      _cropDirty = false;
      _isCropping = false;
    });
    _updateImageSize(widget.bytes);
  }

  Future<void> _handleComplete() async {
    if (_processing || _uploading) {
      return;
    }
    setState(() {
      _uploading = true;
    });
    try {
      Uint8List uploadBytes = _displayBytes;
      if (_cropDirty) {
        final Uint8List? cropped = await _buildCroppedBytes(uploadBytes);
        if (cropped != null) {
          uploadBytes = cropped;
        }
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => MakeParameterScreen(
            imageBytes: uploadBytes,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('打开参数页失败，请稍后重试')));
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片处理'),
        backgroundColor: AppColors.header,
        actions: [
          TextButton(
            onPressed: _processing ? null : _resetEdits,
            child: const Text('还原', style: TextStyle(color: Color(0xFFF9F871))),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final Size container = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  final Rect imageRect = _imageRectFor(container);
                  final Rect cropRect = _cropRectInView(imageRect);
                  final bool showCrop =
                      _isCropping && _hasCropRect && _cropRectPx.width > 0;

                  return Stack(
                    children: [
                      Positioned.fromRect(
                        rect: imageRect,
                        child: Image.memory(_displayBytes, fit: BoxFit.contain),
                      ),
                      if (_isCropping)
                        Positioned.fromRect(
                          rect: imageRect,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) {
                              if (!_hasCropRect) {
                                _startCropDrawing(
                                  details.localPosition,
                                  imageRect,
                                );
                              }
                            },
                            onPanUpdate: (details) {
                              if (_isDrawingCrop) {
                                _updateCropDrawing(
                                  details.localPosition,
                                  imageRect,
                                );
                              }
                            },
                            onPanEnd: (_) => _finishCropDrawing(),
                          ),
                        ),
                      if (_isCropping)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _CropOverlayPainter(
                                imageRect: imageRect,
                                cropRect: showCrop ? cropRect : null,
                              ),
                            ),
                          ),
                        ),
                      if (showCrop)
                        Positioned.fromRect(
                          rect: cropRect,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) => _startCropMove(
                              cropRect.topLeft + details.localPosition,
                              imageRect,
                            ),
                            onPanUpdate: (details) =>
                                _updateCropMove(details.delta, imageRect),
                            onPanEnd: (_) => _finishCropMove(),
                          ),
                        ),
                      if (showCrop)
                        _CropHandleWidget(
                          position: cropRect.topLeft,
                          size: _handleSize,
                          onDrag: (delta) => _updateCropForHandle(
                            _CropHandle.topLeft,
                            delta,
                            imageRect,
                          ),
                        ),
                      if (showCrop)
                        _CropHandleWidget(
                          position: cropRect.topRight,
                          size: _handleSize,
                          onDrag: (delta) => _updateCropForHandle(
                            _CropHandle.topRight,
                            delta,
                            imageRect,
                          ),
                        ),
                      if (showCrop)
                        _CropHandleWidget(
                          position: cropRect.bottomLeft,
                          size: _handleSize,
                          onDrag: (delta) => _updateCropForHandle(
                            _CropHandle.bottomLeft,
                            delta,
                            imageRect,
                          ),
                        ),
                      if (showCrop)
                        _CropHandleWidget(
                          position: cropRect.bottomRight,
                          size: _handleSize,
                          onDrag: (delta) => _updateCropForHandle(
                            _CropHandle.bottomRight,
                            delta,
                            imageRect,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          Container(
            color: AppColors.header,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _EditorActionButton(
                      label: '裁剪',
                      onTap: _processing
                          ? null
                          : () {
                              if (!_isCropping) {
                                setState(() {
                                  _isCropping = true;
                                  _hasCropRect = false;
                                  _cropDirty = false;
                                });
                                return;
                              }
                              if (_hasCropRect) {
                                _applyCrop();
                                if (mounted) {
                                  setState(() {
                                    _isCropping = false;
                                  });
                                }
                              }
                            },
                    ),
                    const SizedBox(width: 8),
                    _EditorActionButton(
                      label: '缩放',
                      onTap: _processing ? null : _applyScale,
                    ),
                    const SizedBox(width: 8),
                    _EditorActionButton(
                      label: '灰度',
                      onTap: _processing ? null : _applyGrayFilter,
                    ),
                    const SizedBox(width: 8),
                    _EditorActionButton(
                      label: '复古',
                      onTap: _processing ? null : _applySepiaFilter,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_processing || _uploading)
                        ? null
                        : _handleComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF9F871),
                      foregroundColor: const Color(0xFF232323),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text((_processing || _uploading) ? '处理中...' : '完成'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CropHandle { topLeft, topRight, bottomLeft, bottomRight }

class _CropOverlayPainter extends CustomPainter {
  final Rect imageRect;
  final Rect? cropRect;

  const _CropOverlayPainter({required this.imageRect, required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );
    if (cropRect != null && cropRect!.width > 0 && cropRect!.height > 0) {
      canvas.drawRect(cropRect!, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    if (cropRect != null && cropRect!.width > 0 && cropRect!.height > 0) {
      final Paint borderPaint = Paint()
        ..color = const Color(0xFFF9F871)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(cropRect!, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect ||
        oldDelegate.imageRect != imageRect;
  }
}

class _CropHandleWidget extends StatelessWidget {
  final Offset position;
  final double size;
  final ValueChanged<Offset> onDrag;

  const _CropHandleWidget({
    required this.position,
    required this.size,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFF9F871),
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }
}

class _EditorActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _EditorActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 36,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFF9F871)),
            foregroundColor: const Color(0xFFF9F871),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
