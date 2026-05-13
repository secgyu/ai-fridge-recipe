import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/utils/image_mapper.dart';
import 'package:fridge_meal/features/fridge/data/models/barcode_product.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/data/models/storage_location.dart';
import 'package:fridge_meal/features/fridge/presentation/providers/ingredient_provider.dart';

/// 바코드 스캔 탭.
///
/// 흐름:
/// 1. 카메라 권한 요청 (`MobileScanner` 내부 처리)
/// 2. 바코드 감지 → 일시정지 + mock 조회
/// 3. 매칭 성공 → 확인 시트, 매칭 실패 → 다이얼로그로 다시 스캔 안내
class AddBarcodeTab extends ConsumerStatefulWidget {
  const AddBarcodeTab({super.key});

  @override
  ConsumerState<AddBarcodeTab> createState() => _AddBarcodeTabState();
}

class _AddBarcodeTabState extends ConsumerState<AddBarcodeTab>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _busy = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      formats: <BarcodeFormat>[
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.qrCode,
      ],
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 백그라운드 진입 시 카메라 해제, 복귀 시 재시작.
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_controller.stop());
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final List<Barcode> codes = capture.barcodes;
    if (codes.isEmpty) return;
    final String? raw = codes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _busy = true);
    unawaited(_controller.stop());
    unawaited(HapticFeedback.mediumImpact());

    final BarcodeProduct? product = lookupBarcode(raw);

    if (!mounted) return;
    if (product == null) {
      await _showNotFound(raw);
    } else {
      await _BarcodeConfirmSheet.show(context, product);
    }

    if (!mounted) return;
    setState(() => _busy = false);
    unawaited(_controller.start());
  }

  Future<void> _showNotFound(String barcode) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('찾지 못한 바코드예요'),
          content: Text(
            '바코드 ($barcode)에 해당하는 상품 정보가 없어요.\n'
            '"직접 입력" 탭에서 추가해주세요.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('다시 스캔'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (
              BuildContext context,
              MobileScannerException error,
              Widget? child,
            ) {
              _lastError = error.errorCode.toString();
              return _PermissionDenied(error: error);
            },
            fit: BoxFit.cover,
          ),
        ),
        // 가독성을 위한 상단/하단 어두운 오버레이.
        const Positioned.fill(child: _ScanOverlay()),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.xxxl,
          child: _BottomHint(busy: _busy, error: _lastError),
        ),
      ],
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            width: 240,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomHint extends StatelessWidget {
  const _BottomHint({required this.busy, required this.error});

  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    String text = '가공식품 바코드를 사각 안에 맞춰주세요';
    if (busy) text = '인식했어요...';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final bool isPermission =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPermission
                  ? Icons.no_photography_rounded
                  : Icons.error_outline_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            isPermission ? '카메라 권한이 필요해요' : '카메라를 열 수 없어요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isPermission
                ? '설정에서 카메라 권한을 허용하면\n바코드를 자동으로 인식할 수 있어요'
                : '잠시 후 다시 시도하거나\n"직접 입력" 탭을 이용해주세요',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 바코드 매칭 성공 시 노출되는 확인 시트.
class _BarcodeConfirmSheet extends ConsumerStatefulWidget {
  const _BarcodeConfirmSheet({required this.product});

  final BarcodeProduct product;

  static Future<bool?> show(BuildContext context, BarcodeProduct product) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) =>
          _BarcodeConfirmSheet(product: product),
    );
  }

  @override
  ConsumerState<_BarcodeConfirmSheet> createState() =>
      _BarcodeConfirmSheetState();
}

class _BarcodeConfirmSheetState
    extends ConsumerState<_BarcodeConfirmSheet> {
  late DateTime? _expiry;
  StorageLocation _storage = StorageLocation.fridge;
  bool _saving = false;
  static const Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    final int? d = widget.product.defaultExpiryDays;
    _expiry = d == null ? null : DateTime.now().add(Duration(days: d));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final Ingredient created = Ingredient(
      id: _uuid.v4(),
      userId: 'mock-user',
      name: widget.product.name,
      category: widget.product.category,
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
          content: Text('${widget.product.name}을(를) 냉장고에 넣었어요'),
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
            const Text(
              '바코드 인식 성공',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.asset(
                    IngredientImageMapper.resolve(
                      name: widget.product.name,
                      category: widget.product.category,
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
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.product.category.label,
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
              value: _expiry == null ? '선택 안 함' : _formatDate(_expiry!),
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
