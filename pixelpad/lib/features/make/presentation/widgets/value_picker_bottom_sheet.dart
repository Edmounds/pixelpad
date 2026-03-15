import 'package:flutter/material.dart';

import 'package:pixelpad/core/theme/app_theme.dart';
import 'package:pixelpad/features/make/presentation/widgets/picker_bar.dart';

class ValuePickerBottomSheet extends StatefulWidget {
  final String title;
  final int initialValue;
  final int minValue;
  final int maxValue;

  const ValuePickerBottomSheet({
    super.key,
    required this.title,
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
  });

  static Future<int?> show(
    BuildContext context, {
    required String title,
    required int initialValue,
    required int minValue,
    required int maxValue,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ValuePickerBottomSheet(
        title: title,
        initialValue: initialValue,
        minValue: minValue,
        maxValue: maxValue,
      ),
    );
  }

  @override
  State<ValuePickerBottomSheet> createState() => _ValuePickerBottomSheetState();
}

class _ValuePickerBottomSheetState extends State<ValuePickerBottomSheet> {
  late final List<int> _values;
  late final PageController _controller;
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _values = List<int>.generate(
      widget.maxValue - widget.minValue + 1,
      (int index) => widget.minValue + index,
    );
    _selectedValue = widget.initialValue.clamp(
      widget.minValue,
      widget.maxValue,
    );
    _controller = PageController(
      viewportFraction: 0.22,
      initialPage: _selectedValue - widget.minValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Material(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$_selectedValue',
                  style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.arrow_drop_up,
                  size: 36,
                  color: Color(0xFFF9F871),
                ),
                const SizedBox(height: 12),
                PickerBar(
                  controller: _controller,
                  itemCount: _values.length,
                  onPageChanged: (int index) {
                    setState(() {
                      _selectedValue = _values[index];
                    });
                  },
                  itemBuilder: (context, index, scale, opacity) {
                    final int value = _values[index];
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E2E2E),
                          foregroundColor: AppColors.white,
                        ),
                        child: const Text('取消'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedValue),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF9F871),
                          foregroundColor: const Color(0xFF232323),
                        ),
                        child: const Text('确认'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
