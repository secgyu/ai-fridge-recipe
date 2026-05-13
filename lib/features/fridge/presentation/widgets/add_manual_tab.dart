import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/data/models/storage_location.dart';
import 'package:fridge_meal/features/fridge/presentation/providers/ingredient_provider.dart';
import 'package:fridge_meal/features/fridge/presentation/screens/add_ingredient_screen.dart';

/// 직접 입력 탭. 자유 텍스트 + 카테고리/유통기한/보관위치 선택.
///
/// 일러스트 매칭은 [IngredientImageMapper]가 처리하므로 사용자가 이름을
/// 정확히 입력하지 못해도 카테고리 폴백으로 자연스럽게 표시된다.
class AddManualTab extends ConsumerStatefulWidget {
  const AddManualTab({super.key});

  @override
  ConsumerState<AddManualTab> createState() => _AddManualTabState();
}

class _AddManualTabState extends ConsumerState<AddManualTab> {
  final TextEditingController _name = TextEditingController();
  IngredientCategory _category = IngredientCategory.vegetable;
  StorageLocation _storage = StorageLocation.fridge;
  DateTime? _expiry;
  bool _saving = false;
  static const Uuid _uuid = Uuid();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final Ingredient created = Ingredient(
      id: _uuid.v4(),
      userId: 'mock-user',
      name: _name.text.trim(),
      category: _category,
      storage: _storage,
      expiryDate: _expiry,
      createdAt: DateTime.now(),
    );
    await ref.read(ingredientsProvider.notifier).addItem(created);
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${created.name}을(를) 냉장고에 넣었어요'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: '유통기한 선택',
      cancelText: '취소',
      confirmText: '완료',
    );
    if (picked != null && mounted) {
      setState(() => _expiry = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AddTabHeader(
          title: '재료 정보를 입력해주세요',
          subtitle: '자유 텍스트로 추가할 수 있어요',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            children: <Widget>[
              const _FieldLabel(label: '이름'),
              _NameField(
                controller: _name,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _FieldLabel(label: '카테고리'),
              _CategoryGrid(
                value: _category,
                onChanged: (IngredientCategory c) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _category = c);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              const _FieldLabel(label: '유통기한'),
              _DateRow(
                value: _expiry,
                onTap: _pickDate,
                onClear: _expiry == null
                    ? null
                    : () => setState(() => _expiry = null),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _FieldLabel(label: '보관 위치'),
              _StorageRow(
                value: _storage,
                onChanged: (StorageLocation v) {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _storage = v);
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.md,
            AppSpacing.xxl,
            AppSpacing.md,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 52,
              child: AnimatedOpacity(
                opacity: _canSave ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 120),
                child: Material(
                  color: AppColors.primary,
                  borderRadius: AppRadius.rLg,
                  child: InkWell(
                    borderRadius: AppRadius.rLg,
                    onTap: _canSave ? _save : null,
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              '냉장고에 넣기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
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

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.rMd,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          hintText: '예) 시금치',
          hintStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.value, required this.onChanged});

  final IngredientCategory value;
  final ValueChanged<IngredientCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: IngredientCategory.values.map((IngredientCategory c) {
        final bool selected = c == value;
        return Material(
          color: selected ? AppColors.primary : AppColors.surfaceSubtle,
          borderRadius: AppRadius.rPill,
          child: InkWell(
            borderRadius: AppRadius.rPill,
            onTap: () => onChanged(c),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              child: Text(
                c.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final String text = value == null
        ? '선택 안 함 (D-day 계산 안 됨)'
        : _formatDate(value!);
    return Material(
      color: AppColors.surfaceSubtle,
      borderRadius: AppRadius.rMd,
      child: InkWell(
        borderRadius: AppRadius.rMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              const Icon(
                Icons.event_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: value == null
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (onClear != null)
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final int diff = d.difference(today).inDays;
    final String abs =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    if (diff == 0) return '$abs · 오늘까지';
    if (diff > 0) return '$abs · D-$diff';
    return '$abs · ${diff.abs()}일 지남';
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({required this.value, required this.onChanged});

  final StorageLocation value;
  final ValueChanged<StorageLocation> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: StorageLocation.values.map((StorageLocation s) {
        final bool selected = s == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: s == StorageLocation.values.last ? 0 : 8,
            ),
            child: Material(
              color: selected
                  ? AppColors.primary
                  : AppColors.surfaceSubtle,
              borderRadius: AppRadius.rMd,
              child: InkWell(
                borderRadius: AppRadius.rMd,
                onTap: () => onChanged(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
