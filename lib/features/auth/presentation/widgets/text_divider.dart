import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// "또는", "소셜 계정으로 빠르게 로그인" 등 가운데 텍스트 + 양옆 디바이더.
class TextDivider extends StatelessWidget {
  const TextDivider({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Divider(thickness: 1, color: AppColors.border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: AppColors.textTertiary,
            ),
          ),
        ),
        const Expanded(
          child: Divider(thickness: 1, color: AppColors.border),
        ),
      ],
    );
  }
}
