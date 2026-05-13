import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 조합 탭 하단 고정 "AI 레시피 만들기" CTA.
///
/// [count]가 2 미만이면 비활성. 활성 시 [count]를 라벨에 함께 표시한다.
class GenerateRecipeCta extends StatelessWidget {
  const GenerateRecipeCta({
    super.key,
    required this.count,
    required this.onPressed,
  });

  final int count;
  final VoidCallback onPressed;

  static const int _minCount = 2;

  @override
  Widget build(BuildContext context) {
    final bool enabled = count >= _minCount;
    final String label = enabled
        ? '재료 $count개로 AI 레시피 만들기'
        : '재료 $_minCount개 이상 담아주세요';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0x00FFFFFF),
            AppColors.background,
          ],
          stops: <double>[0.0, 0.4],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: AnimatedOpacity(
            opacity: enabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 120),
            child: Material(
              color: AppColors.primary,
              borderRadius: AppRadius.rLg,
              child: InkWell(
                borderRadius: AppRadius.rLg,
                onTap: enabled ? onPressed : null,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: -0.3,
                      color: Colors.white,
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
