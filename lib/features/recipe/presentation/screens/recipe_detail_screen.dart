import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/history/presentation/providers/cook_history_provider.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';
import 'package:fridge_meal/features/recipe/presentation/providers/favorite_recipe_provider.dart';
import 'package:fridge_meal/features/recipe/presentation/widgets/recipe_hero.dart';
import 'package:fridge_meal/features/recipe/presentation/widgets/recipe_ingredient_list.dart';
import 'package:fridge_meal/features/recipe/presentation/widgets/recipe_step_tile.dart';

/// F-05 레시피 상세.
///
/// - 히어로: 카테고리 그라데이션 + 큰 이모지 + 요리명/메타
/// - 재료: 보유/미보유 체크리스트
/// - 단계: 인덱스 배지 + 설명 + 타이머 토글
/// - 팁: 카드로 묶어 강조
/// - 즐겨찾기(F-07): 상단 ❤️ 토글 → Hive `favorites` 박스 영속화
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  Future<void> _markCompleted() async {
    unawaited(HapticFeedback.mediumImpact());
    await ref
        .read(cookHistoryProvider.notifier)
        .addCompleted(widget.recipe);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.recipe.name} 만들었어요! 기록에 저장했어요'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _toggleFavorite() async {
    unawaited(HapticFeedback.lightImpact());
    final bool added = await ref
        .read(favoriteRecipesProvider.notifier)
        .toggle(widget.recipe);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(added ? '즐겨찾기에 추가했어요' : '즐겨찾기에서 제거했어요'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFavorite = ref.watch(
      favoriteRecipesProvider.select(
        (List<Recipe> list) =>
            list.any((Recipe r) => r.id == widget.recipe.id),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
                onPressed: () => Navigator.of(context).pop(),
                tooltip: '뒤로',
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    color: isFavorite
                        ? AppColors.danger
                        : AppColors.textPrimary,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
            SliverToBoxAdapter(child: RecipeHero(recipe: widget.recipe)),
            SliverToBoxAdapter(
              child: _SectionTitle(label: '필요한 재료'),
            ),
            SliverToBoxAdapter(
              child: RecipeIngredientList(
                ingredients: widget.recipe.ingredients,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xl),
            ),
            SliverToBoxAdapter(child: _SectionTitle(label: '조리 순서')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.sm,
                AppSpacing.xxl,
                AppSpacing.md,
              ),
              sliver: SliverList.separated(
                itemCount: widget.recipe.steps.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (BuildContext context, int index) {
                  return RecipeStepTile(step: widget.recipe.steps[index]);
                },
              ),
            ),
            if (widget.recipe.tips.isNotEmpty) ...<Widget>[
              SliverToBoxAdapter(child: _SectionTitle(label: '셰프의 팁')),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.sm,
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                ),
                sliver: SliverList.separated(
                  itemCount: widget.recipe.tips.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (BuildContext context, int index) {
                    return _TipBubble(text: widget.recipe.tips[index]);
                  },
                ),
              ),
            ] else
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxl),
              ),
          ],
        ),
        bottomNavigationBar: _CompleteCta(onPressed: _markCompleted),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.sm,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompleteCta extends StatelessWidget {
  const _CompleteCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0x00FFFFFF), AppColors.background],
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
          child: Material(
            color: AppColors.primary,
            borderRadius: AppRadius.rLg,
            child: InkWell(
              borderRadius: AppRadius.rLg,
              onTap: onPressed,
              child: const Center(
                child: Text(
                  '요리 완료!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
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
