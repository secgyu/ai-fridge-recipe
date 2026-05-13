import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/core/router/app_routes.dart';
import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/utils/image_mapper.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/presentation/providers/ingredient_provider.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/category_filter_chips.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/cook_cta_button.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/empty_fridge_state.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/expiry_warning_banner.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/fridge_header.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/ingredient_sheet.dart';
import 'package:fridge_meal/shared/widgets/ingredient_list_item.dart';

/// 홈 화면 = 내 냉장고.
///
/// 구성:
/// - 헤더(타이틀 + 개수 + 알림/추가 버튼)
/// - 유통기한 임박 배너 (D-3 이내 재료 존재 시)
/// - 카테고리 필터 칩 (가로 스크롤, 보유 카테고리만)
/// - 재료 리스트 (D-day 오름차순)
/// - 하단 고정 "요리 시작" CTA
///
/// 로딩/에러/빈 상태를 각각 다른 컴포지션으로 처리.
class FridgeScreen extends ConsumerWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Ingredient>> all = ref.watch(ingredientsProvider);
    final AsyncValue<List<Ingredient>> filtered = ref.watch(
      filteredIngredientsProvider,
    );
    final IngredientCategory? selected = ref.watch(
      selectedCategoryFilterProvider,
    );
    final List<IngredientCategory> available = ref.watch(
      availableCategoriesProvider,
    );
    final int soonCount = ref.watch(expirySoonCountProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              FridgeHeader(
                count: all.maybeWhen(
                  data: (List<Ingredient> l) => l.length,
                  orElse: () => 0,
                ),
                onNotificationTap: () => _showComingSoon(context, '알림'),
                onAddTap: () => _openAddSheet(context),
              ),
              Expanded(
                child: all.when(
                  loading: () => const _Loading(),
                  error: (Object e, _) => _ErrorView(
                    onRetry: () => ref.invalidate(ingredientsProvider),
                  ),
                  data: (List<Ingredient> list) {
                    if (list.isEmpty) {
                      return EmptyFridgeState(
                        onAddTap: () => _openAddSheet(context),
                      );
                    }
                    return _FridgeContent(
                      ingredients: filtered.value ?? const <Ingredient>[],
                      totalCount: list.length,
                      soonCount: soonCount,
                      availableCategories: available,
                      selectedCategory: selected,
                      onCategorySelect: (IngredientCategory? c) {
                        unawaited(HapticFeedback.selectionClick());
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .select(c);
                      },
                      onItemTap: (Ingredient i) => _openEditSheet(context, i),
                      onWarningTap: () =>
                          _showComingSoon(context, '임박 재료 보기'),
                    );
                  },
                ),
              ),
              // 빈 상태일 때는 CTA를 숨겨 EmptyFridgeState 내부 버튼만 노출.
              if (all.value?.isNotEmpty ?? false)
                CookCtaButton(
                  enabled: (all.value?.length ?? 0) >= 2,
                  onPressed: () => _showComingSoon(context, '요리 시작'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context, Ingredient item) async {
    unawaited(HapticFeedback.selectionClick());
    await IngredientSheet.showEdit(context, item);
  }

  void _openAddSheet(BuildContext context) {
    unawaited(HapticFeedback.selectionClick());
    context.push(AppRoutes.addIngredient);
  }

  void _showComingSoon(BuildContext context, String label) {
    unawaited(HapticFeedback.selectionClick());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label은 곧 만나실 수 있어요'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
      );
  }
}

class _FridgeContent extends StatelessWidget {
  const _FridgeContent({
    required this.ingredients,
    required this.totalCount,
    required this.soonCount,
    required this.availableCategories,
    required this.selectedCategory,
    required this.onCategorySelect,
    required this.onItemTap,
    required this.onWarningTap,
  });

  final List<Ingredient> ingredients;
  final int totalCount;
  final int soonCount;
  final List<IngredientCategory> availableCategories;
  final IngredientCategory? selectedCategory;
  final ValueChanged<IngredientCategory?> onCategorySelect;
  final ValueChanged<Ingredient> onItemTap;
  final VoidCallback onWarningTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (soonCount > 0) ...<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
            ),
            child: ExpiryWarningBanner(
              count: soonCount,
              onTap: onWarningTap,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        CategoryFilterChips(
          availableCategories: availableCategories,
          selected: selectedCategory,
          onSelect: onCategorySelect,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ingredients.isEmpty
              ? const _NoMatchPlaceholder()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    // CookCtaButton 베일 영역만큼 여유.
                    AppSpacing.huge,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: ingredients.length,
                  separatorBuilder: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                    ),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final Ingredient item = ingredients[index];
                    return IngredientListItem(
                      name: item.name,
                      subtitle:
                          '${item.category.label} | ${item.storage.label}',
                      imagePath: IngredientImageMapper.resolve(
                        name: item.name,
                        category: item.category,
                      ),
                      daysLeft: item.daysLeft,
                      showChevron: true,
                      onTap: () => onItemTap(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '재료를 불러오지 못했어요',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _NoMatchPlaceholder extends StatelessWidget {
  const _NoMatchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Text(
          '이 카테고리에 해당하는 재료가 없어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
