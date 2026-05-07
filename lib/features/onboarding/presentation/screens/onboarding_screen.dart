import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:fridge_meal/features/onboarding/presentation/widgets/ingredient_stack_preview.dart';
import 'package:fridge_meal/features/onboarding/presentation/widgets/onboarding_page.dart';
import 'package:fridge_meal/features/onboarding/presentation/widgets/page_indicator.dart';

/// 최초 1회 노출되는 온보딩 (3페이지).
///
/// 마지막 페이지의 "시작하기"를 누르면 [OnboardingCompleted.markCompleted]가
/// 호출되고, 상위(`_AppEntry`)가 다음 화면으로 자동 전환된다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  double _pageOffset = 0;
  bool _completing = false;

  static const int _pageCount = 3;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handlePageOffset);
  }

  void _handlePageOffset() {
    final double page = _controller.page ?? 0;
    if (_pageOffset != page) {
      setState(() {
        _pageOffset = page;
        _currentIndex = page.round();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePageOffset);
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentIndex >= _pageCount - 1;

  Future<void> _onCtaPressed() async {
    if (_completing) return;
    if (_isLastPage) {
      _completing = true;
      unawaited(HapticFeedback.lightImpact());
      await ref.read(onboardingCompletedProvider.notifier).markCompleted();
      // 상위 위젯이 provider 변화를 watch 해 자동 전환.
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    await _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView(
                controller: _controller,
                children: <Widget>[
                  OnboardingPage(
                    title: '스캔으로 시작해요',
                    description: '바코드나 텍스트를 스캔하면\n재료가 자동으로 등록돼요',
                    illustration: _IllustrationImage(
                      asset: 'assets/images/onboarding/scan.png',
                    ),
                  ),
                  const OnboardingPage(
                    title: '재료를 모아보세요',
                    description: '냉장고에 있는 재료를 정리하고\n유통기한을 한눈에 확인해요',
                    illustration: IngredientStackPreview(),
                  ),
                  OnboardingPage(
                    title: 'AI가 요리를 추천해요',
                    description: '등록된 재료를 바탕으로\n바로 만들 수 있는 레시피를 추천해드려요',
                    illustration: _IllustrationImage(
                      asset: 'assets/images/onboarding/ai_recipe.png',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PageIndicator(count: _pageCount, currentIndex: _pageOffset),
            const SizedBox(height: AppSpacing.xxl),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                0,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onCtaPressed,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _isLastPage ? '시작하기' : '다음',
                      key: ValueKey<bool>(_isLastPage),
                    ),
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

class _IllustrationImage extends StatelessWidget {
  const _IllustrationImage({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
