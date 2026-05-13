import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/utils/image_mapper.dart';
import 'package:fridge_meal/features/cook/presentation/providers/selected_ingredients_provider.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';

/// 항아리에 담긴 재료 목록 바텀시트.
///
/// 각 항목 우측 X 버튼으로 개별 제거 가능, 하단에 "모두 비우기" 텍스트 버튼.
class SelectedIngredientsSheet extends ConsumerWidget {
  const SelectedIngredientsSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const SelectedIngredientsSheet._(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Ingredient> items = ref.watch(selectedIngredientsProvider);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: AppSpacing.md),
            const _GrabHandle(),
            const SizedBox(height: AppSpacing.lg),
            _Header(count: items.length),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
            Flexible(
              child: items.isEmpty
                  ? const _EmptyMessage()
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: items.length,
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
                        final Ingredient item = items[index];
                        return _SelectedRow(
                          ingredient: item,
                          onRemove: () {
                            unawaited(HapticFeedback.selectionClick());
                            ref
                                .read(selectedIngredientsProvider.notifier)
                                .remove(item.id);
                          },
                        );
                      },
                    ),
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.md,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      unawaited(HapticFeedback.lightImpact());
                      ref
                          .read(selectedIngredientsProvider.notifier)
                          .clear();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '모두 비우기',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _GrabHandle extends StatelessWidget {
  const _GrabHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '항아리에 담긴 재료 ($count)',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            color: AppColors.textSecondary,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '닫기',
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Text(
        '아직 담긴 재료가 없어요',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _SelectedRow extends StatelessWidget {
  const _SelectedRow({required this.ingredient, required this.onRemove});

  final Ingredient ingredient;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 36,
            height: 36,
            child: Image.asset(
              IngredientImageMapper.resolve(
                name: ingredient.name,
                category: ingredient.category,
              ),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: AppRadius.rSm,
                ),
                child: const Icon(
                  Icons.restaurant_outlined,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ingredient.category.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.surfaceSubtle,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
