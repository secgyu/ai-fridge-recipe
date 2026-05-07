import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/theme/app_theme.dart';
import 'package:fridge_meal/core/theme/app_typography.dart';
import 'package:fridge_meal/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:fridge_meal/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:fridge_meal/features/splash/presentation/screens/splash_screen.dart';

class FridgeMealApp extends ConsumerWidget {
  const FridgeMealApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '냉장고 한 끼',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AppEntry(),
    );
  }
}

/// 앱 진입 게이트.
///
/// 1) 스플래시(1.5s) → 2) 온보딩(미완료 시) → 3) 메인.
/// 라우터(GoRouter) 도입 시 redirect 기반으로 교체된다.
class _AppEntry extends ConsumerStatefulWidget {
  const _AppEntry();

  @override
  ConsumerState<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<_AppEntry> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (!_splashDone) {
      child = SplashScreen(
        key: const ValueKey<String>('splash'),
        onComplete: () => setState(() => _splashDone = true),
      );
    } else if (!ref.watch(onboardingCompletedProvider)) {
      child = const OnboardingScreen(key: ValueKey<String>('onboarding'));
    } else {
      child = const _SetupCheckScreen(key: ValueKey<String>('home'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}

/// 임시 홈. 라우터/인증/홈 화면 도입 시 제거된다.
class _SetupCheckScreen extends StatelessWidget {
  const _SetupCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Text('냉장고 한 끼', style: AppTypo.h1),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '셋업 완료. 다음 단계에서 라우터 + 디자인 시스템을 이어서 진행해요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
