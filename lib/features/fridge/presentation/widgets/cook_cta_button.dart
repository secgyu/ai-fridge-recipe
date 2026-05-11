import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 하단 고정 "요리 시작" CTA.
///
/// SafeArea + 상단 그라데이션 베일로 리스트 끝부분의 가독성을 보장한다.
class CookCtaButton extends StatelessWidget {
  const CookCtaButton({
    super.key,
    required this.enabled,
    required this.onPressed,
  });

  /// `false`면 비활성(회색) 상태. 보통 재료 < 2개일 때.
  final bool enabled;

  /// 활성 상태에서의 콜백. 비활성이면 무시.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
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
                child: const Center(
                  child: Text(
                    '요리 시작',
                    style: TextStyle(
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
