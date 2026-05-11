import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 재료 리스트의 한 행. 냉장고/항아리/온보딩 미리보기에서 공통 사용.
///
/// 디자인:
/// - 좌: 36pt 일러스트 썸네일 (rounded square, 옅은 배경)
/// - 중앙: 재료명 (15pt / 600) + 선택적 부제 (12pt / textTertiary)
/// - 우: D-day 라벨 (긴급도에 따라 색상) + 선택적 chevron
class IngredientListItem extends StatelessWidget {
  const IngredientListItem({
    super.key,
    required this.name,
    required this.imagePath,
    required this.daysLeft,
    this.subtitle,
    this.onTap,
    this.showChevron = false,
  });

  final String name;

  /// "채소 | 냉장 보관" 등 보조 정보. `null`이면 미표시.
  final String? subtitle;

  final String imagePath;

  /// 유통기한까지 남은 일수. 만료 후엔 음수, 미설정이면 null.
  final int? daysLeft;

  final VoidCallback? onTap;

  /// `true`면 우측 끝에 chevron(>) 아이콘 표시. 탭 가능한 행에 권장.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _Thumbnail(imagePath: imagePath),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        letterSpacing: -0.1,
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (daysLeft != null) ...<Widget>[
              _DDayLabel(daysLeft: daysLeft!),
              if (showChevron) const SizedBox(width: AppSpacing.sm),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: AppRadius.rSm,
          ),
          child: const Icon(
            Icons.restaurant_outlined,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _DDayLabel extends StatelessWidget {
  const _DDayLabel({required this.daysLeft});

  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final Color color = _resolveColor(daysLeft);
    return Text(
      _resolveText(daysLeft),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.1,
        color: color,
      ),
    );
  }

  static Color _resolveColor(int daysLeft) {
    if (daysLeft <= 2) return AppColors.danger;
    if (daysLeft <= 6) return AppColors.warning;
    return AppColors.success;
  }

  static String _resolveText(int daysLeft) {
    if (daysLeft < 0) return '지남';
    if (daysLeft == 0) return 'D-Day';
    return 'D-$daysLeft';
  }
}
