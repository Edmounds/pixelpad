import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:pixelpad/core/app/navigation.dart';
import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/device/data/inventory_api_service.dart';
import 'package:pixelpad/features/make/data/bean_preset_storage.dart';
import 'package:pixelpad/features/make/presentation/widgets/picker_bar.dart';

const List<String> _fallbackBeanBrands = [
  'Coco',
  'DMC',
  'manifest',
  '卡卡家',
  '漫漫家',
  '盼盼拼豆',
  'MARD',
];

const List<int> _fallbackColorCounts = [24, 48, 72, 96, 120, 144, 221, 295];

class BeanPresetScreen extends StatefulWidget {
  const BeanPresetScreen({super.key});

  @override
  State<BeanPresetScreen> createState() => _BeanPresetScreenState();
}

class _BeanPresetScreenState extends State<BeanPresetScreen> {
  late final PageController _brandController;
  late final PageController _countController;
  final InventoryApiService _inventoryApiService = InventoryApiService();

  Map<String, List<int>> _countsByBrand = <String, List<int>>{};
  List<String> _beanBrands = List<String>.from(_fallbackBeanBrands);
  List<int> _colorCounts = List<int>.from(_fallbackColorCounts);
  int _brandIndex = _fallbackBeanBrands.indexOf(BeanPresetStorage.defaultBrand);
  int _countIndex = _fallbackColorCounts.indexOf(
    BeanPresetStorage.defaultCount,
  );
  bool _usingLocalFallback = false;

  @override
  void initState() {
    super.initState();
    if (_brandIndex < 0) {
      _brandIndex = 0;
    }
    if (_countIndex < 0) {
      _countIndex = 0;
    }
    _brandController = PageController(
      viewportFraction: 0.26,
      initialPage: _brandIndex,
    );
    _countController = PageController(
      viewportFraction: 0.22,
      initialPage: _countIndex,
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _brandController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _onBrandChanged(int index) {
    if (_beanBrands.isEmpty) {
      return;
    }
    final int safeIndex = index.clamp(0, _beanBrands.length - 1).toInt();
    final String brand = _beanBrands[safeIndex];
    final int? preferred =
        (_countIndex >= 0 && _countIndex < _colorCounts.length)
        ? _colorCounts[_countIndex]
        : null;
    _applyCountsForBrand(brand, preferredCount: preferred);
    setState(() => _brandIndex = safeIndex);
    if (_countController.hasClients) {
      _countController.jumpToPage(_countIndex);
    }
  }

  void _onCountChanged(int index) {
    if (_colorCounts.isEmpty) {
      return;
    }
    setState(() {
      _countIndex = index.clamp(0, _colorCounts.length - 1).toInt();
    });
  }

  Future<void> _bootstrap() async {
    final BeanPreset preset = await BeanPresetStorage.load();
    _applyPreset(preset);
    await _loadRemoteSettings(preset);
  }

  void _applyPreset(BeanPreset preset) {
    int nextBrand = _beanBrands.indexOf(preset.brand);
    if (nextBrand < 0) {
      nextBrand = _brandIndex.clamp(0, _beanBrands.length - 1).toInt();
    }
    final String brand = _beanBrands[nextBrand];
    _applyCountsForBrand(brand, preferredCount: preset.count);
    if (!mounted) return;
    setState(() {
      _brandIndex = nextBrand;
    });
    _brandController.jumpToPage(nextBrand);
    _countController.jumpToPage(_countIndex);
  }

  Future<void> _loadRemoteSettings(BeanPreset preset) async {
    try {
      final List<String> files = await _inventoryApiService.listSettingsFiles();
      final Map<String, List<int>> parsed = _parseSettingsFiles(files);
      if (!mounted) {
        return;
      }
      if (parsed.isEmpty) {
        setState(() {
          _usingLocalFallback = true;
        });
        return;
      }
      setState(() {
        _countsByBrand = parsed;
        _beanBrands = parsed.keys.toList()..sort();
        _usingLocalFallback = false;
      });
      _applyPreset(preset);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _usingLocalFallback = true;
      });
    }
  }

  Map<String, List<int>> _parseSettingsFiles(List<String> files) {
    final RegExp pattern = RegExp(
      r'^(.+)-([0-9]+)\\.json$',
      caseSensitive: false,
    );
    final Map<String, Set<int>> groups = <String, Set<int>>{};
    for (final String file in files) {
      final RegExpMatch? match = pattern.firstMatch(file.trim());
      if (match == null) {
        continue;
      }
      final String brand = (match.group(1) ?? '').trim();
      final int? count = int.tryParse(match.group(2) ?? '');
      if (brand.isEmpty || count == null) {
        continue;
      }
      groups.putIfAbsent(brand, () => <int>{}).add(count);
    }
    final Map<String, List<int>> result = <String, List<int>>{};
    groups.forEach((String brand, Set<int> counts) {
      final List<int> sorted = counts.toList()..sort();
      if (sorted.isNotEmpty) {
        result[brand] = sorted;
      }
    });
    return result;
  }

  void _applyCountsForBrand(String brand, {int? preferredCount}) {
    final List<int> nextCounts = List<int>.from(
      _countsByBrand[brand] ?? _fallbackColorCounts,
    );
    if (nextCounts.isEmpty) {
      nextCounts.add(BeanPresetStorage.defaultCount);
    }
    int nextCountIndex = 0;
    if (preferredCount != null) {
      final int idx = nextCounts.indexOf(preferredCount);
      if (idx >= 0) {
        nextCountIndex = idx;
      }
    }
    _colorCounts = nextCounts;
    _countIndex = nextCountIndex;
  }

  Future<void> _savePreset() async {
    final BeanPreset preset = BeanPreset(
      brand: _beanBrands[_brandIndex],
      count: _colorCounts[_countIndex],
    );
    await BeanPresetStorage.save(preset);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已保存预设')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => AppNavigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.play_arrow,
                            size: 16,
                            color: Color(0xFFF9F871),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '返回',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFF9F871),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              '选择你的豆子',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '这能帮助我们为你定制更适合的创作旅程。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFFBFBFBF),
              ),
            ),
            if (_usingLocalFallback) ...[
              const SizedBox(height: 8),
              const Text(
                '当前未拉取到在线配置，已使用本地预设。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F871),
                ),
              ),
            ],
            const SizedBox(height: 18),
            PickerBar(
              controller: _brandController,
              itemCount: _beanBrands.length,
              onPageChanged: _onBrandChanged,
              itemBuilder: (context, index, scale, opacity) {
                final String label = _beanBrands[index];
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: opacity),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            const Text(
              '选择颜色数量',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '选色越多，后续作图可选颜色越丰富。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: Color(0xFFBFBFBF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_colorCounts[_countIndex]}',
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_drop_up, size: 36, color: Color(0xFFF9F871)),
            const SizedBox(height: 12),
            PickerBar(
              controller: _countController,
              itemCount: _colorCounts.length,
              onPageChanged: _onCountChanged,
              itemBuilder: (context, index, scale, opacity) {
                final int value = _colorCounts[index];
                return Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: opacity),
                  ),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _FrostedButton(label: '保存', onTap: _savePreset),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FrostedButton({required this.label, required this.onTap});

  @override
  State<_FrostedButton> createState() => _FrostedButtonState();
}

class _FrostedButtonState extends State<_FrostedButton> {
  bool _pressed = false;

  void _handleHighlightChanged(bool isPressed) {
    if (_pressed == isPressed) return;
    setState(() => _pressed = isPressed);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _handleHighlightChanged,
              borderRadius: BorderRadius.circular(999),
              splashColor: Colors.white.withValues(alpha: 0.18),
              highlightColor: Colors.white.withValues(alpha: 0.12),
              child: Ink(
                width: 211,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: _pressed ? 0.28 : 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
