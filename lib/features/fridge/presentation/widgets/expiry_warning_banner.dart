import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 유통기한 임박(D-3 이내) 재료가 있을 때 노출되는 경고 배너.
///
/// 옅은 danger 배경 + danger 텍스트로 시선을 끌되, 카드 형태로 압박감 완화.
class ExpiryWarningBanner extends StatelessWidget {
  const ExpiryWarningBanner({
    super.key,
    required this.count,
    this.onTap,
  });

  final int count;
  final VoidCallback? onTap;

  static const Color _bg = Color(0xFFFEF2F2); // danger 5% tint
  static const Color _border = Color(0xFFFECACA);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _bg,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rMd,
            border: Border.all(color: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '유통기한 임박 재료 $count개',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.2,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.danger,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
