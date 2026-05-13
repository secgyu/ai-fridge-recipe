import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:fridge_meal/core/router/app_routes.dart';
import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/history/presentation/widgets/empty_history_view.dart';

/// 기록 탭.
///
/// 두 가지 카테고리를 분리:
/// - 즐겨찾기: 레시피 상세에서 ❤️로 명시적으로 저장한 것 (F-07)
/// - 만든 요리: AI 추천을 실제 조리 완료한 기록 (F-07/F-11)
///
/// MVP 단계에서는 두 탭 모두 빈 상태만 노출하며, F-07/F-11이 들어오면
/// `TabBarView` 내부 위젯만 실제 리스트로 교체된다.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                const _HistoryHeader(),
                const _HistoryTabBar(),
                Expanded(
                  child: TabBarView(
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      EmptyHistoryView(
                        icon: Icons.favorite_rounded,
                        title: '즐겨찾는 레시피가 없어요',
                        description: '마음에 든 레시피에 별을 눌러두면\n오프라인에서도 다시 볼 수 있어요',
                        actionLabel: '레시피 만들러 가기',
                        onAction: () => _goToCook(context),
                      ),
                      EmptyHistoryView(
                        icon: Icons.restaurant_menu_rounded,
                        title: '아직 만든 요리가 없어요',
                        description: 'AI가 추천한 레시피를 완성하면\n여기에 차곡차곡 쌓여요',
                        actionLabel: '레시피 만들러 가기',
                        onAction: () => _goToCook(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goToCook(BuildContext context) {
    unawaited(HapticFeedback.selectionClick());
    context.go(AppRoutes.cook);
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '기록',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _HistoryTabBar extends StatelessWidget {
  const _HistoryTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: TabBar(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorPadding: const EdgeInsets.only(bottom: 2),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        onTap: (_) => unawaited(HapticFeedback.selectionClick()),
        tabs: const <Widget>[
          Tab(text: '즐겨찾기'),
          Tab(text: '만든 요리'),
        ],
      ),
    );
  }
}
