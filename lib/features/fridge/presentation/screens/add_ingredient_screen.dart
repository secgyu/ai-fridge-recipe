import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/add_autocomplete_tab.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/add_barcode_tab.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/add_manual_tab.dart';

/// F-01 재료 추가 풀스크린.
///
/// 탭 3개를 가로 스와이프로 전환:
/// 1. 자동완성: 30개 신선식품 마스터에서 검색 → 칩 탭 → 폼 자동 채움
/// 2. 바코드: `MobileScanner` 카메라 → 식약처 mock 조회
/// 3. 직접 입력: 자유 텍스트 + 카테고리 선택
///
/// 셸 밖 풀스크린이므로 바텀 네비는 숨김.
class AddIngredientScreen extends ConsumerWidget {
  const AddIngredientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '뒤로',
            ),
            title: const Text(
              '재료 추가',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textTertiary,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
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
                  onTap: (_) =>
                      unawaited(HapticFeedback.selectionClick()),
                  tabs: const <Widget>[
                    Tab(text: '자동완성'),
                    Tab(text: '바코드'),
                    Tab(text: '직접 입력'),
                  ],
                ),
              ),
            ),
          ),
          body: const SafeArea(
            top: false,
            child: TabBarView(
              physics: BouncingScrollPhysics(),
              children: <Widget>[
                AddAutocompleteTab(),
                AddBarcodeTab(),
                AddManualTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 풀스크린 진입 직후 보이는 자리표시용 헤더 (탭별 상단 공통 패딩).
class AddTabHeader extends StatelessWidget {
  const AddTabHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
