import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/cook/presentation/providers/selected_ingredients_provider.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';

/// 항아리 표정(이미지 변화) 상태.
enum _PotMood { idle, excited, satisfied }

/// 항아리(냄비) 드롭 존. 재료를 끌어 떨어뜨리면 추가된다.
///
/// 시각 효과:
/// - 기본 상태(idle): `pot_idle.png` — 평온한 표정
/// - 드래그 hover(excited): `pot_excited.png` + 1.1x scale + 오렌지 glow
/// - 드롭 성공 후 1.5초(satisfied): `pot_satisfied.png` + squash bounce
class PotDropZone extends ConsumerStatefulWidget {
  const PotDropZone({super.key, required this.onTap});

  /// 항아리 탭 시 호출 — 보통 SelectedIngredientsSheet 노출.
  final VoidCallback onTap;

  @override
  ConsumerState<PotDropZone> createState() => _PotDropZoneState();
}

class _PotDropZoneState extends ConsumerState<PotDropZone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  bool _hovering = false;
  bool _justAccepted = false;
  Timer? _satisfiedTimer;

  static const Duration _satisfiedDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _satisfiedTimer?.cancel();
    _bounce.dispose();
    super.dispose();
  }

  void _onAccept(Ingredient ingredient) {
    unawaited(HapticFeedback.mediumImpact());
    ref.read(selectedIngredientsProvider.notifier).add(ingredient);
    _satisfiedTimer?.cancel();
    setState(() {
      _hovering = false;
      _justAccepted = true;
    });
    _bounce.forward(from: 0);
    _satisfiedTimer = Timer(_satisfiedDuration, () {
      if (mounted) setState(() => _justAccepted = false);
    });
  }

  _PotMood get _mood {
    if (_hovering) return _PotMood.excited;
    if (_justAccepted) return _PotMood.satisfied;
    return _PotMood.idle;
  }

  @override
  Widget build(BuildContext context) {
    final List<Ingredient> selected = ref.watch(
      selectedIngredientsProvider,
    );

    return DragTarget<Ingredient>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (DragTargetDetails<Ingredient> details) {
        _onAccept(details.data);
      },
      builder: (BuildContext context, _, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: selected.isEmpty
              ? null
              : () {
                  unawaited(HapticFeedback.selectionClick());
                  widget.onTap();
                },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _PotImage(mood: _mood, bounce: _bounce),
              const SizedBox(height: AppSpacing.md),
              _PotCaption(mood: _mood, selectedCount: selected.length),
            ],
          ),
        );
      },
    );
  }
}

class _PotImage extends StatelessWidget {
  const _PotImage({required this.mood, required this.bounce});

  final _PotMood mood;
  final Animation<double> bounce;

  static const Map<_PotMood, String> _assets = <_PotMood, String>{
    _PotMood.idle: 'assets/images/pot/pot_idle.png',
    _PotMood.excited: 'assets/images/pot/pot_excited.png',
    _PotMood.satisfied: 'assets/images/pot/pot_satisfied.png',
  };

  @override
  Widget build(BuildContext context) {
    final bool hovering = mood == _PotMood.excited;

    return AnimatedScale(
      scale: hovering ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: hovering
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: AnimatedBuilder(
          animation: bounce,
          builder: (BuildContext context, Widget? child) {
            final double t = bounce.value;
            final double squashY = t < 0.3
                ? 1.0 - (t / 0.3) * 0.08
                : t < 0.7
                    ? 0.92 + ((t - 0.3) / 0.4) * 0.12
                    : 1.04 - ((t - 0.7) / 0.3) * 0.04;
            final double squashX = 2.0 - squashY; // 부피 보존 느낌
            return Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..scaleByDouble(squashX, squashY, 1, 1),
              child: child,
            );
          },
          child: SizedBox(
            width: 180,
            height: 180,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Image.asset(
                _assets[mood]!,
                key: ValueKey<_PotMood>(mood),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PotCaption extends StatelessWidget {
  const _PotCaption({required this.mood, required this.selectedCount});

  final _PotMood mood;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _buildCaption(),
    );
  }

  Widget _buildCaption() {
    if (mood == _PotMood.excited) {
      return const Text(
        '여기에 떨어뜨려요!',
        key: ValueKey<String>('hovering'),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.primary,
        ),
      );
    }
    if (mood == _PotMood.satisfied) {
      return Text(
        '맛있겠다! 재료 $selectedCount개 담았어요',
        key: const ValueKey<String>('satisfied'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
          color: AppColors.primary,
        ),
      );
    }
    if (selectedCount == 0) {
      return const Text(
        '재료를 끌어서 넣어주세요',
        key: ValueKey<String>('empty'),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: AppColors.textTertiary,
        ),
      );
    }
    return Column(
      key: const ValueKey<String>('count'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '재료 $selectedCount개 담았어요',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '항아리를 탭하면 목록을 볼 수 있어요',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
