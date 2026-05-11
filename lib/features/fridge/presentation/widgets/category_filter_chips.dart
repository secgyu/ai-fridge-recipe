import 'package:flutter/material.dart';

import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 카테고리 필터 칩 리스트. 가로 스크롤.
///
/// 맨 앞에 "전체"가 고정으로 위치하고 그 뒤로 [availableCategories]가 이어진다.
/// 선택된 칩은 primary 배경 + 흰 텍스트로 강조.
class CategoryFilterChips extends StatelessWidget {
  const CategoryFilterChips({
    super.key,
    required this.availableCategories,
    required this.selected,
    required this.onSelect,
  });

  /// 현재 데이터에서 1개 이상 존재하는 카테고리만.
  final List<IngredientCategory> availableCategories;

  /// 현재 선택된 카테고리. `null`이면 "전체".
  final IngredientCategory? selected;

  /// 선택 변경 콜백. `null` 인자는 "전체"를 의미.
  final ValueChanged<IngredientCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        itemCount: availableCategories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _Chip(
              label: '전체',
              selected: selected == null,
              onTap: () => onSelect(null),
            );
          }
          final IngredientCategory category = availableCategories[index - 1];
          return _Chip(
            label: category.label,
            selected: selected == category,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? AppColors.primary : AppColors.surfaceSubtle;
    final Color fg = selected ? Colors.white : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: bg,
        borderRadius: AppRadius.rPill,
        child: InkWell(
          borderRadius: AppRadius.rPill,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.2,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
