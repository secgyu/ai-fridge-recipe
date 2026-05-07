import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final double currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(count, (int i) {
        final double distance = (currentIndex - i).abs().clamp(0.0, 1.0);
        final double activeness = 1.0 - distance;
        final double width = 6.0 + 14.0 * activeness;
        final Color color =
            Color.lerp(AppColors.border, AppColors.primary, activeness) ??
            AppColors.border;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: width,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
