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
import 'package:fridge_meal/features/cook/presentation/providers/selected_ingredients_provider.dart';
import 'package:fridge_meal/features/cook/presentation/widgets/draggable_ingredient_card.dart';
import 'package:fridge_meal/features/cook/presentation/widgets/generate_recipe_cta.dart';
import 'package:fridge_meal/features/cook/presentation/widgets/pot_drop_zone.dart';
import 'package:fridge_meal/features/cook/presentation/widgets/selected_ingredients_sheet.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/presentation/providers/ingredient_provider.dart';
import 'package:fridge_meal/features/fridge/presentation/widgets/category_filter_chips.dart';

/// 조합 탭 (F-02 핵심 화면).
///
/// 레이아웃 (세로 분할):
/// - 상단: 헤더 + 카테고리 필터 + 재료 그리드 (Draggable)
/// - 하단: 항아리 드롭 존 + CTA
///
/// 작은 화면(SE급)을 고려해 상단 비중을 60% (flex 6 vs 4)로.
class CookScreen extends ConsumerStatefulWidget {
  const CookScreen({super.key});

  @override
  ConsumerState<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends ConsumerState<CookScreen> {
  IngredientCategory? _category;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Ingredient>> all = ref.watch(ingredientsProvider);
    final List<Ingredient> selected = ref.watch(
      selectedIngredientsProvider,
    );

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
          child: all.when(
            loading: () => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            error: (Object e, _) => _ErrorView(
              onRetry: () => ref.invalidate(ingredientsProvider),
            ),
            data: (List<Ingredient> list) {
              if (list.isEmpty) {
                return _EmptyFridgePrompt(
                  onGoFridge: () {
                    unawaited(HapticFeedback.selectionClick());
                    context.go(AppRoutes.fridge);
                  },
                );
              }
              return _CookContent(
                allIngredients: list,
                category: _category,
                onCategorySelect: (IngredientCategory? c) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _category = c);
                },
                onPotTap: () => SelectedIngredientsSheet.show(context),
                selectedCount: selected.length,
                onGenerate: () => _goToResults(context, selected),
              );
            },
          ),
        ),
      ),
    );
  }

  void _goToResults(BuildContext context, List<Ingredient> selected) {
    unawaited(HapticFeedback.mediumImpact());
    context.push(AppRoutes.recipeResults, extra: selected);
  }
}

class _CookContent extends StatelessWidget {
  const _CookContent({
    required this.allIngredients,
    required this.category,
    required this.onCategorySelect,
    required this.onPotTap,
    required this.selectedCount,
    required this.onGenerate,
  });

  final List<Ingredient> allIngredients;
  final IngredientCategory? category;
  final ValueChanged<IngredientCategory?> onCategorySelect;
  final VoidCallback onPotTap;
  final int selectedCount;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final List<IngredientCategory> availableCategories = IngredientCategory
        .values
        .where(
          (IngredientCategory c) =>
              allIngredients.any((Ingredient i) => i.category == c),
        )
        .toList(growable: false);

    final List<Ingredient> filtered = category == null
        ? allIngredients
        : allIngredients
            .where((Ingredient i) => i.category == category)
            .toList(growable: false);

    return Column(
      children: <Widget>[
        const _Header(),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              CategoryFilterChips(
                availableCategories: availableCategories,
                selected: category,
                onSelect: onCategorySelect,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? const _NoMatchPlaceholder()
                    : _IngredientGrid(items: filtered),
              ),
            ],
          ),
        ),
        const _Divider(),
        Expanded(
          flex: 4,
          child: PotDropZone(onTap: onPotTap),
        ),
        GenerateRecipeCta(count: selectedCount, onPressed: onGenerate),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '조합',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '재료를 항아리에 넣어 레시피를 추천받아 보세요',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.1,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientGrid extends StatelessWidget {
  const _IngredientGrid({required this.items});

  final List<Ingredient> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.sm,
        AppSpacing.xxl,
        AppSpacing.md,
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return DraggableIngredientCard(ingredient: items[index]);
      },
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Divider(height: 1, thickness: 1, color: AppColors.divider),
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
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _EmptyFridgePrompt extends StatelessWidget {
  const _EmptyFridgePrompt({required this.onGoFridge});

  final VoidCallback onGoFridge;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.kitchen_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              '냉장고가 비어있어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '재료를 먼저 추가하면\n여기서 항아리에 넣어볼 수 있어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Material(
              color: AppColors.primary,
              borderRadius: AppRadius.rLg,
              child: InkWell(
                borderRadius: AppRadius.rLg,
                onTap: onGoFridge,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  child: Text(
                    '냉장고로 가기',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
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
