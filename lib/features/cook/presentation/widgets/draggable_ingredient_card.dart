import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/utils/image_mapper.dart';
import 'package:fridge_meal/features/cook/presentation/providers/selected_ingredients_provider.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';

/// 조합 탭의 재료 카드. 드래그하여 항아리에 떨어뜨릴 수 있다.
///
/// - 이미 항아리에 담긴 재료는 반투명 + 체크 마크.
/// - 드래그 중 원본 자리는 살짝 더 반투명 (childWhenDragging).
/// - feedback 위젯은 살짝 들린 듯 그림자 + scale 1.05.
class DraggableIngredientCard extends ConsumerWidget {
  const DraggableIngredientCard({super.key, required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이 재료의 선택 여부만 watch — 다른 재료 selection 변화엔 rebuild 안 함.
    final bool selected = ref.watch(
      selectedIngredientsProvider.select(
        (List<Ingredient> list) =>
            list.any((Ingredient i) => i.id == ingredient.id),
      ),
    );

    final Widget card = _IngredientCardBody(ingredient: ingredient);

    if (selected) {
      // 선택된 재료는 드래그 불가, 반투명 + 체크.
      return _SelectedOverlay(child: card);
    }

    return LongPressDraggable<Ingredient>(
      data: ingredient,
      delay: const Duration(milliseconds: 150),
      hapticFeedbackOnStart: true,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: _FeedbackCard(ingredient: ingredient),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      onDragStarted: () => HapticFeedback.lightImpact(),
      child: card,
    );
  }
}

class _IngredientCardBody extends StatelessWidget {
  const _IngredientCardBody({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rMd,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Image.asset(
              IngredientImageMapper.resolve(
                name: ingredient.name,
                category: ingredient.category,
              ),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => const Icon(
                Icons.restaurant_outlined,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ingredient.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedOverlay extends StatelessWidget {
  const _SelectedOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Opacity(opacity: 0.35, child: child),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.05,
      child: Material(
        color: Colors.transparent,
        elevation: 12,
        shadowColor: Colors.black26,
        borderRadius: AppRadius.rMd,
        child: SizedBox(
          width: 100,
          height: 110,
          child: _IngredientCardBody(ingredient: ingredient),
        ),
      ),
    );
  }
}
