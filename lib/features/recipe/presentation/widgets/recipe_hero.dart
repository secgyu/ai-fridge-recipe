import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

/// 레시피 상세의 히어로 영역.
///
/// 음식 일러스트가 아직 없으므로 카테고리별 그라데이션 + 큰 이모지로 대체.
/// `recipe.imagePath`가 설정되면 우선 사용.
class RecipeHero extends StatelessWidget {
  const RecipeHero({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final List<Color> gradient = _gradientFor(recipe.category);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Stack(
        children: <Widget>[
          if (recipe.imagePath != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: Image.asset(
                  recipe.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      _EmojiCenter(category: recipe.category),
                ),
              ),
            )
          else
            _EmojiCenter(category: recipe.category),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    recipe.category,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    letterSpacing: -0.6,
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _MetaPill(recipe: recipe),
              ],
            ),
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
}

class _EmojiCenter extends StatelessWidget {
  const _EmojiCenter({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: AppSpacing.lg,
      right: AppSpacing.xl,
      child: Text(_emoji(category), style: const TextStyle(fontSize: 96)),
    );
  }

  static String _emoji(String category) {
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

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Item(
            icon: Icons.schedule_rounded,
            text: '${recipe.cookingMinutes}분',
          ),
          const _Dot(),
          _Item(
            icon: Icons.people_outline_rounded,
            text: '${recipe.servings}인분',
          ),
          const _Dot(),
          _Item(
            icon: Icons.local_fire_department_outlined,
            text: recipe.difficulty.label,
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 13, color: AppColors.textPrimary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: const BoxDecoration(
          color: AppColors.textTertiary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
