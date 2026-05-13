import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/settings/data/models/dietary_restriction.dart';
import 'package:fridge_meal/features/settings/presentation/providers/settings_provider.dart';

/// F-09 식이 제한 설정.
///
/// 다중 선택 chip + "모두 해제" 액션. 토글 즉시 Hive에 영속화.
/// 추후 F-03(`generate-recipe`) 호출 시 함께 전송되어 결과 필터링.
class DietaryRestrictionsScreen extends ConsumerWidget {
  const DietaryRestrictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<DietaryRestriction> selected =
        ref.watch(dietaryRestrictionsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            onPressed: () => Navigator.of(context).pop(),
            tooltip: '뒤로',
          ),
          title: const Text(
            '식이 제한',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: <Widget>[
            if (selected.isNotEmpty)
              TextButton(
                onPressed: () {
                  unawaited(HapticFeedback.lightImpact());
                  ref.read(dietaryRestrictionsProvider.notifier).clear();
                },
                child: const Text(
                  '모두 해제',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.md,
              AppSpacing.xxl,
              AppSpacing.xxxl,
            ),
            children: <Widget>[
              const Text(
                '레시피 추천 시 제외할 항목을 골라주세요',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${selected.length}개 선택됨',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(label: '식습관'),
              _Group(
                items: const <DietaryRestriction>[
                  DietaryRestriction.vegetarian,
                  DietaryRestriction.vegan,
                  DietaryRestriction.pescatarian,
                ],
                selected: selected,
                onToggle: (DietaryRestriction r) => _toggle(ref, r),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(label: '음식 민감성'),
              _Group(
                items: const <DietaryRestriction>[
                  DietaryRestriction.glutenFree,
                  DietaryRestriction.lactoseFree,
                ],
                selected: selected,
                onToggle: (DietaryRestriction r) => _toggle(ref, r),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(label: '알레르기'),
              _Group(
                items: const <DietaryRestriction>[
                  DietaryRestriction.nuts,
                  DietaryRestriction.shrimp,
                  DietaryRestriction.egg,
                  DietaryRestriction.soy,
                ],
                selected: selected,
                onToggle: (DietaryRestriction r) => _toggle(ref, r),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(WidgetRef ref, DietaryRestriction r) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(ref.read(dietaryRestrictionsProvider.notifier).toggle(r));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final List<DietaryRestriction> items;
  final Set<DietaryRestriction> selected;
  final ValueChanged<DietaryRestriction> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < items.length; i++) ...<Widget>[
            _Row(
              item: items[i],
              selected: selected.contains(items[i]),
              onToggle: () => onToggle(items[i]),
            ),
            if (i < items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.selected,
    required this.onToggle,
  });

  final DietaryRestriction item;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _CheckBubble(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBubble extends StatelessWidget {
  const _CheckBubble({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.borderStrong,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : null,
    );
  }
}
