import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/utils/image_mapper.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient_master.dart';
import 'package:fridge_meal/features/fridge/data/models/storage_location.dart';
import 'package:fridge_meal/features/fridge/presentation/providers/ingredient_provider.dart';
import 'package:fridge_meal/features/fridge/presentation/screens/add_ingredient_screen.dart';

/// 신선식품 자동완성 탭.
///
/// 흐름:
/// 1. 검색창 입력 → 2글자 이상이면 마스터에서 부분일치
/// 2. 추천 칩 노출 (이미지 + 이름 + 카테고리)
/// 3. 칩 탭 → 하단 시트로 수량/유통기한/보관위치 확인 → 저장
class AddAutocompleteTab extends ConsumerStatefulWidget {
  const AddAutocompleteTab({super.key});

  @override
  ConsumerState<AddAutocompleteTab> createState() =>
      _AddAutocompleteTabState();
}

class _AddAutocompleteTabState extends ConsumerState<AddAutocompleteTab> {
  final TextEditingController _query = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<IngredientMaster> hits = searchIngredientMasters(_q);
    final bool emptyQuery = _q.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AddTabHeader(
          title: '재료 이름을 검색해주세요',
          subtitle: '예) 양파, 닭고기, 우유',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _SearchField(
            controller: _query,
            onChanged: (String v) => setState(() => _q = v),
            onClear: () {
              _query.clear();
              setState(() => _q = '');
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: emptyQuery
              ? const _PopularSuggestions()
              : hits.isEmpty
                  ? const _NoMatch()
                  : _MasterList(
                      items: hits,
                      onPick: (IngredientMaster m) => _onPick(context, m),
                    ),
        ),
      ],
    );
  }

  Future<void> _onPick(BuildContext context, IngredientMaster m) async {
    unawaited(HapticFeedback.selectionClick());
    final bool? saved = await _ConfirmSheet.show(context, m);
    if (saved == true && mounted) {
      _query.clear();
      setState(() => _q = '');
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.rMd,
      ),
      child: TextField(
        controller: controller,
        autofocus: true,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '재료 이름 검색',
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.textTertiary,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _PopularSuggestions extends StatelessWidget {
  const _PopularSuggestions();

  static const List<String> _picks = <String>[
    '양파', '감자', '계란', '당근', '돼지고기', '대파', '두부', '우유',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '인기 재료',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _picks.map((String p) => _Suggestion(label: p)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final IngredientMaster? master = kIngredientMasters.where(
      (IngredientMaster m) => m.name == label,
    ).firstOrNull;
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.rPill,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: master == null
            ? null
            : () async {
                unawaited(HapticFeedback.selectionClick());
                await _ConfirmSheet.show(context, master);
              },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rPill,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MasterList extends StatelessWidget {
  const _MasterList({required this.items, required this.onPick});

  final List<IngredientMaster> items;
  final void Function(IngredientMaster) onPick;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.xxxl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.divider,
      ),
      itemBuilder: (BuildContext context, int index) {
        final IngredientMaster m = items[index];
        return InkWell(
          onTap: () => onPick(m),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.asset(
                    IngredientImageMapper.resolve(
                      name: m.name,
                      category: m.category,
                    ),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        m.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.category.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NoMatch extends StatelessWidget {
  const _NoMatch();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Spacer(),
          const Icon(
            Icons.search_off_rounded,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            '검색 결과가 없어요',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '"직접 입력" 탭에서 자유롭게 추가해주세요',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textTertiary,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// 자동완성 결과 칩을 탭하면 뜨는 확인 시트.
/// 이름·카테고리는 잠금, 유통기한/보관위치만 조정 가능.
class _ConfirmSheet extends ConsumerStatefulWidget {
  const _ConfirmSheet({required this.master});

  final IngredientMaster master;

  static Future<bool?> show(BuildContext context, IngredientMaster master) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => _ConfirmSheet(master: master),
    );
  }

  @override
  ConsumerState<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends ConsumerState<_ConfirmSheet> {
  late DateTime? _expiry;
  StorageLocation _storage = StorageLocation.fridge;
  bool _saving = false;
  static const Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    final int? days = widget.master.defaultExpiryDays;
    _expiry = days == null
        ? null
        : DateTime.now().add(Duration(days: days));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final Ingredient created = Ingredient(
      id: _uuid.v4(),
      userId: 'mock-user',
      name: widget.master.name,
      category: widget.master.category,
      storage: _storage,
      expiryDate: _expiry,
      createdAt: DateTime.now(),
    );
    await ref.read(ingredientsProvider.notifier).addItem(created);
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.master.name}을(를) 냉장고에 넣었어요'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _expiry ?? now.add(const Duration(days: 7));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    IngredientImageMapper.resolve(
                      name: widget.master.name,
                      category: widget.master.category,
                    ),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.master.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.master.category.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SheetField(
              label: '유통기한',
              value: _expiry == null
                  ? '선택 안 함'
                  : _formatDate(_expiry!),
              onTap: _pickDate,
              icon: Icons.event_rounded,
            ),
            const SizedBox(height: AppSpacing.sm),
            _StorageSelector(
              value: _storage,
              onChanged: (StorageLocation v) {
                unawaited(HapticFeedback.selectionClick());
                setState(() => _storage = v);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              height: 52,
              child: Material(
                color: AppColors.primary,
                borderRadius: AppRadius.rLg,
                child: InkWell(
                  borderRadius: AppRadius.rLg,
                  onTap: _saving ? null : _save,
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
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final int diff = d.difference(DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    )).inDays;
    final String absDate =
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    if (diff == 0) return '$absDate · 오늘까지';
    if (diff > 0) return '$absDate · D-$diff';
    return '$absDate · ${diff.abs()}일 지남';
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
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
}

class _StorageSelector extends StatelessWidget {
  const _StorageSelector({required this.value, required this.onChanged});

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
