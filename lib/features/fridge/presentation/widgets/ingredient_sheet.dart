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

/// 재료 추가/편집 통합 바텀시트.
///
/// - `ingredient == null` → 추가 모드 (제목 "재료 추가", 삭제 버튼 숨김, 자동 포커스)
/// - `ingredient != null` → 편집 모드 (제목 "재료 편집", 삭제 버튼 노출, 자동 포커스 없음)
class IngredientSheet extends ConsumerStatefulWidget {
  const IngredientSheet._({this.ingredient});

  final Ingredient? ingredient;

  /// 신규 재료 추가용. 완료(저장) 시 `true`, 취소 시 `null`.
  static Future<bool?> showAdd(BuildContext context) {
    return _show(context, null);
  }

  /// 기존 재료 편집용. 완료(저장/삭제) 시 `true`, 취소 시 `null`.
  static Future<bool?> showEdit(BuildContext context, Ingredient ingredient) {
    return _show(context, ingredient);
  }

  static Future<bool?> _show(BuildContext context, Ingredient? ingredient) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) =>
          IngredientSheet._(ingredient: ingredient),
    );
  }

  @override
  ConsumerState<IngredientSheet> createState() => _IngredientSheetState();
}

class _IngredientSheetState extends ConsumerState<IngredientSheet> {
  static const Uuid _uuid = Uuid();

  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;
  late IngredientCategory _category;
  late StorageLocation _storage;
  late DateTime? _expiryDate;
  bool _saving = false;

  bool get _isEdit => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    final Ingredient? src = widget.ingredient;
    _nameController = TextEditingController(text: src?.name ?? '');
    _nameFocus = FocusNode();
    _category = src?.category ?? IngredientCategory.vegetable;
    _storage = src?.storage ?? StorageLocation.fridge;
    _expiryDate = src?.expiryDate;

    // 추가 모드에서는 시트 등장 직후 키보드 자동 노출.
    if (!_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_isValid || _saving) return;
    setState(() => _saving = true);
    unawaited(HapticFeedback.lightImpact());

    final String name = _nameController.text.trim();

    try {
      if (_isEdit) {
        final Ingredient updated = widget.ingredient!.copyWith(
          name: name,
          category: _category,
          storage: _storage,
          expiryDate: _expiryDate,
        );
        await ref.read(ingredientsProvider.notifier).updateItem(updated);
      } else {
        // TODO(auth): Supabase 연동 후 실제 userId로 교체.
        final Ingredient created = Ingredient(
          id: _uuid.v4(),
          userId: 'mock-user',
          name: name,
          category: _category,
          storage: _storage,
          expiryDate: _expiryDate,
          createdAt: DateTime.now(),
        );
        await ref.read(ingredientsProvider.notifier).addItem(created);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final Ingredient? src = widget.ingredient;
    if (src == null || _saving) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        title: const Text('이 재료를 삭제할까요?'),
        content: Text('"${src.name}"이(가) 냉장고에서 사라져요.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _saving = true);
    unawaited(HapticFeedback.mediumImpact());

    try {
      await ref.read(ingredientsProvider.notifier).deleteItem(src.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickExpiryDate() async {
    final DateTime today = DateTime.now();
    final DateTime initial =
        _expiryDate ?? DateTime(today.year, today.month, today.day + 7);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
      helpText: '유통기한 선택',
      cancelText: '취소',
      confirmText: '확인',
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              const _GrabHandle(),
              const SizedBox(height: AppSpacing.lg),
              _SheetHeader(title: _isEdit ? '재료 편집' : '재료 추가'),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('이름'),
              const SizedBox(height: AppSpacing.sm),
              _NameField(
                controller: _nameController,
                focusNode: _nameFocus,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('카테고리'),
              const SizedBox(height: AppSpacing.sm),
              _CategoryPicker(
                selected: _category,
                onSelect: (IngredientCategory c) =>
                    setState(() => _category = c),
              ),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('보관 위치'),
              const SizedBox(height: AppSpacing.sm),
              _StoragePicker(
                selected: _storage,
                onSelect: (StorageLocation s) => setState(() => _storage = s),
              ),
              const SizedBox(height: AppSpacing.xl),

              const _FieldLabel('유통기한'),
              const SizedBox(height: AppSpacing.sm),
              _ExpiryPickerRow(
                expiryDate: _expiryDate,
                onPick: _pickExpiryDate,
                onClear: _expiryDate == null
                    ? null
                    : () => setState(() => _expiryDate = null),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              _ActionRow(
                isEdit: _isEdit,
                onDelete: _saving ? null : _confirmDelete,
                onSave: (_isValid && !_saving) ? _save : null,
                saving: _saving,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 하위 위젯들
// ---------------------------------------------------------------------------

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

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: '예: 두부, 양파, 우유',
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: AppColors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rMd,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelect});

  final IngredientCategory selected;
  final ValueChanged<IngredientCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final IngredientCategory c in IngredientCategory.values)
          _ChoiceChip(
            label: c.label,
            selected: selected == c,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onSelect(c);
            },
          ),
      ],
    );
  }
}

class _StoragePicker extends StatelessWidget {
  const _StoragePicker({required this.selected, required this.onSelect});

  final StorageLocation selected;
  final ValueChanged<StorageLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final StorageLocation s in StorageLocation.values)
          _ChoiceChip(
            label: s.label,
            selected: selected == s,
            onTap: () {
              unawaited(HapticFeedback.selectionClick());
              onSelect(s);
            },
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = selected ? AppColors.primarySoft : AppColors.surfaceSubtle;
    final Color fg = selected ? AppColors.primary : AppColors.textSecondary;
    final Color? borderColor = selected ? AppColors.primary : null;

    return Material(
      color: bg,
      borderRadius: AppRadius.rPill,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rPill,
            border: borderColor != null
                ? Border.all(color: borderColor)
                : null,
          ),
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
                color: fg,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiryPickerRow extends StatelessWidget {
  const _ExpiryPickerRow({
    required this.expiryDate,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? expiryDate;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  String get _displayText {
    final DateTime? d = expiryDate;
    if (d == null) return '미설정';
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Material(
            color: AppColors.surfaceSubtle,
            borderRadius: AppRadius.rMd,
            child: InkWell(
              borderRadius: AppRadius.rMd,
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _displayText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: expiryDate == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onClear != null) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text(
              '지우기',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isEdit,
    required this.onDelete,
    required this.onSave,
    required this.saving,
  });

  final bool isEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    // 추가 모드: 저장 버튼만 풀폭. 편집 모드: 삭제(1) + 저장(2) 비율.
    if (!isEdit) {
      return SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: onSave,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.borderStrong,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
          ),
          child: saving
              ? const _SavingSpinner()
              : const Text(
                  '냉장고에 추가',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.border),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.rMd,
                ),
              ),
              child: const Text(
                '삭제',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.borderStrong,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.rMd,
                ),
              ),
              child: saving
                  ? const _SavingSpinner()
                  : const Text(
                      '저장',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavingSpinner extends StatelessWidget {
  const _SavingSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}
