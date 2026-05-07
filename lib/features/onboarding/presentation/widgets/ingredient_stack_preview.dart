import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// Onboarding Page 2 에서 노출되는 정적 미리보기 카드.
///
/// 실제 `IngredientCard` 위젯이 만들어지면 그 컴포넌트를 그대로 끼워 쓰도록
/// 구조를 단순한 데이터 + 행으로 분리.
class IngredientStackPreview extends StatelessWidget {
  const IngredientStackPreview({super.key});

  static const List<_PreviewItem> _items = <_PreviewItem>[
    _PreviewItem(name: '감자', dDay: 'D-5', color: AppColors.success),
    _PreviewItem(name: '양파', dDay: 'D-8', color: AppColors.warning),
    _PreviewItem(name: '돼지고기', dDay: 'D-1', color: AppColors.danger),
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
            _PreviewRow(item: _items[i]),
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
    required this.dDay,
    required this.color,
  });

  final String name;
  final String dDay;
  final Color color;
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.item});

  final _PreviewItem item;

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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            item.dDay,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.1,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }
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
        children: const <Widget>[
          Icon(
            Icons.add_circle_outline,
            size: 16,
            color: AppColors.textTertiary,
          ),
          SizedBox(width: AppSpacing.md),
          Text(
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
