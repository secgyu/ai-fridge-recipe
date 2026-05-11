import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 냉장고에 등록된 재료가 0개일 때의 빈 상태.
///
/// 항아리 마스코트 + 안내 문구 + 1차 CTA로 사용자가 첫 재료를 추가하도록 유도.
class EmptyFridgeState extends StatelessWidget {
  const EmptyFridgeState({super.key, required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 120,
              height: 120,
              child: Image.asset(
                'assets/images/splash/splash.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              '냉장고가 비어있어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '첫 재료를 추가하면\n어울리는 레시피를 추천해드릴게요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Material(
              color: AppColors.primary,
              borderRadius: AppRadius.rLg,
              child: InkWell(
                borderRadius: AppRadius.rLg,
                onTap: onAddTap,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        '재료 추가하기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.2,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
