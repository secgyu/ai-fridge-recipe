import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

/// F-03 결과 화면 카드.
///
/// 디자인:
/// - 상단: 카테고리별 그라데이션 + 큰 이모지 + 매칭 배지
/// - 본문: 요리명 + 태그라인 + 메타(시간/인분/난이도)
/// - 음식 일러스트가 추후 추가되면 그라데이션 자리에 이미지 표시.
class RecipeCard extends StatelessWidget {
  const RecipeCard({super.key, required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.rXl,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rXl,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Hero(recipe: recipe),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (recipe.tagline != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        recipe.tagline!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _MetaRow(recipe: recipe),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient = _gradientFor(recipe.category);
    return SizedBox(
      height: 130,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              _emojiFor(recipe.category),
              style: const TextStyle(fontSize: 56),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            child: _MatchBadge(match: recipe.ingredientMatch),
          ),
          Positioned(
            top: AppSpacing.md,
            right: AppSpacing.md,
            child: _CategoryChip(label: recipe.category),
          ),
        ],
      ),
    );
  }

  static List<Color> _gradientFor(String category) {
    switch (category) {
      case '국·수프':
      case '국':
      case '찌개':
        return const <Color>[Color(0xFFFFF1E6), Color(0xFFFFDDC2)];
      case '볶음':
        return const <Color>[Color(0xFFFFE9DF), Color(0xFFFFB897)];
      case '반찬':
        return const <Color>[Color(0xFFFFF8E1), Color(0xFFFFE082)];
      case '밥·면':
        return const <Color>[Color(0xFFFFF3D6), Color(0xFFFFD89B)];
      default:
        return const <Color>[Color(0xFFFFEEE5), Color(0xFFFFCBAE)];
    }
  }

  static String _emojiFor(String category) {
    switch (category) {
      case '국·수프':
      case '국':
      case '찌개':
        return '🍲';
      case '볶음':
        return '🍳';
      case '반찬':
        return '🥢';
      case '밥·면':
        return '🍚';
      default:
        return '🍽️';
    }
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.match});

  final ({int owned, int total}) match;

  @override
  Widget build(BuildContext context) {
    final bool fullMatch = match.owned == match.total;
    final Color bg = fullMatch
        ? AppColors.success.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.95);
    final Color fg = fullMatch ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            fullMatch
                ? Icons.check_circle_rounded
                : Icons.shopping_basket_rounded,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            fullMatch ? '재료 다 있어요' : '재료 ${match.owned}/${match.total}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _MetaItem(
          icon: Icons.schedule_rounded,
          text: '${recipe.cookingMinutes}분',
        ),
        const SizedBox(width: AppSpacing.md),
        _MetaItem(
          icon: Icons.people_outline_rounded,
          text: '${recipe.servings}인분',
        ),
        const SizedBox(width: AppSpacing.md),
        _MetaItem(
          icon: Icons.local_fire_department_outlined,
          text: recipe.difficulty.label,
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
