import 'package:flutter/material.dart';

import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/utils/image_mapper.dart';
import 'package:fridge_meal/shared/widgets/ingredient_list_item.dart';

/// Onboarding Page 2 에서 노출되는 정적 미리보기 카드.
///
/// 실제 냉장고 화면과 동일한 [IngredientListItem] 위젯을 사용한다.
/// → 디자인 토큰 변경 시 온보딩과 실제 화면이 자동으로 동기화된다.
class IngredientStackPreview extends StatelessWidget {
  const IngredientStackPreview({super.key});

  static const List<_PreviewItem> _items = <_PreviewItem>[
    _PreviewItem(
      name: '감자',
      category: IngredientCategory.vegetable,
      daysLeft: 8,
    ),
    _PreviewItem(
      name: '양파',
      category: IngredientCategory.vegetable,
      daysLeft: 5,
    ),
    _PreviewItem(
      name: '돼지고기',
      category: IngredientCategory.meat,
      daysLeft: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rLg,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < _items.length; i++) ...<Widget>[
            IngredientListItem(
              name: _items[i].name,
              imagePath: IngredientImageMapper.resolve(
                name: _items[i].name,
                category: _items[i].category,
              ),
              daysLeft: _items[i].daysLeft,
            ),
            const _PreviewDivider(),
          ],
          const _AddRow(),
        ],
      ),
    );
  }
}

class _PreviewItem {
  const _PreviewItem({
    required this.name,
    required this.category,
    required this.daysLeft,
  });

  final String name;
  final IngredientCategory category;
  final int daysLeft;
}

class _AddRow extends StatelessWidget {
  const _AddRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: AppRadius.rSm,
            ),
            child: const Icon(
              Icons.add,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Text(
            '재료 추가',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewDivider extends StatelessWidget {
  const _PreviewDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Divider(height: 1, thickness: 1, color: AppColors.border),
    );
  }
}
