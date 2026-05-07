import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/theme/app_typography.dart';

/// 온보딩 한 페이지의 표준 레이아웃.
///
/// 상단: 제목 + 설명, 가운데: 일러스트(또는 위젯) 영역.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.title,
    required this.description,
    required this.illustration,
  });

  final String title;
  final String description;
  final Widget illustration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.xxxl),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypo.h1.copyWith(fontSize: 26, height: 1.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.55,
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
            ),
          ),
          // 텍스트와 일러스트의 시각적 연결을 위해 위쪽 여백을 더 짧게(2:3).
          const Spacer(flex: 2),
          illustration,
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
