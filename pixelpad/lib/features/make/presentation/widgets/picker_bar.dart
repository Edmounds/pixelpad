import 'package:flutter/material.dart';

typedef PickerBarItemBuilder =
    Widget Function(
      BuildContext context,
      int index,
      double scale,
      double opacity,
    );

class PickerBar extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageChanged;
  final PickerBarItemBuilder itemBuilder;
  final double height;
  final Color backgroundColor;

  const PickerBar({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onPageChanged,
    required this.itemBuilder,
    this.height = 96,
    this.backgroundColor = const Color(0xFFB8A6FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth =
              constraints.maxWidth * controller.viewportFraction;
          final double centerX = constraints.maxWidth / 2;
          final double lineOffset = itemWidth * 0.6;
          final double lineHeight = height * 0.65;

          return Stack(
            children: [
              Positioned.fill(
                child: PageView.builder(
                  controller: controller,
                  itemCount: itemCount,
                  onPageChanged: onPageChanged,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: controller,
                      builder: (context, child) {
                        final double page = controller.hasClients
                            ? controller.page ??
                                  controller.initialPage.toDouble()
                            : controller.initialPage.toDouble();
                        final double distance = (page - index).abs().clamp(
                          0.0,
                          2.0,
                        );
                        final double scale = 1 - (distance * 0.15);
                        final double opacity = 1 - (distance * 0.3);

                        return Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: itemBuilder(
                                context,
                                index,
                                scale,
                                opacity,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned(
                left: centerX - lineOffset,
                top: (height - lineHeight) / 2,
                child: Container(
                  width: 2,
                  height: lineHeight,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              Positioned(
                left: centerX + lineOffset - 2,
                top: (height - lineHeight) / 2,
                child: Container(
                  width: 2,
                  height: lineHeight,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
