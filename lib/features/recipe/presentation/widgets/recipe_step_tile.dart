import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

/// 레시피 상세의 단계 하나.
///
/// `step.timerSeconds`가 있으면 시작/정지 버튼으로 카운트다운 가능.
/// 완료 시 [HapticFeedback.heavyImpact]로 알림.
/// MVP에서는 화면이 떠 있는 동안만 동작 (백그라운드 알림은 v1.1).
class RecipeStepTile extends StatefulWidget {
  const RecipeStepTile({super.key, required this.step});

  final RecipeStep step;

  @override
  State<RecipeStepTile> createState() => _RecipeStepTileState();
}

class _RecipeStepTileState extends State<RecipeStepTile> {
  Timer? _ticker;
  int _remaining = 0;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.step.timerSeconds ?? 0;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isRunning => _ticker?.isActive ?? false;

  void _toggleTimer() {
    if (_isRunning) {
      _pause();
    } else {
      _start();
    }
  }

  void _start() {
    if (_remaining <= 0) {
      _remaining = widget.step.timerSeconds ?? 0;
      _completed = false;
    }
    unawaited(HapticFeedback.selectionClick());
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) {
          _remaining = 0;
          _completed = true;
          _ticker?.cancel();
          unawaited(HapticFeedback.heavyImpact());
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _ticker?.cancel();
    unawaited(HapticFeedback.selectionClick());
    setState(() {});
  }

  void _reset() {
    _ticker?.cancel();
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _remaining = widget.step.timerSeconds ?? 0;
      _completed = false;
    });
  }

  String _format(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: _completed ? AppColors.success : AppColors.border,
          width: _completed ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StepBadge(index: widget.step.index, completed: _completed),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.step.description,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.step.timerSeconds != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _TimerRow(
              remaining: _remaining,
              total: widget.step.timerSeconds!,
              isRunning: _isRunning,
              completed: _completed,
              formatted: _format(_remaining),
              onToggle: _toggleTimer,
              onReset: _reset,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.index, required this.completed});

  final int index;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: completed ? AppColors.success : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: completed
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '$index',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class _TimerRow extends StatelessWidget {
  const _TimerRow({
    required this.remaining,
    required this.total,
    required this.isRunning,
    required this.completed,
    required this.formatted,
    required this.onToggle,
    required this.onReset,
  });

  final int remaining;
  final int total;
  final bool isRunning;
  final bool completed;
  final String formatted;
  final VoidCallback onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : 1 - (remaining / total);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.rMd,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: completed ? 1.0 : progress,
              strokeWidth: 2.4,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                completed ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            formatted,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontFeatures: const <FontFeature>[
                FontFeature.tabularFigures(),
              ],
              color: completed ? AppColors.success : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (remaining < total)
            _IconButton(
              icon: Icons.refresh_rounded,
              onPressed: onReset,
              tooltip: '초기화',
            ),
          const SizedBox(width: 4),
          _PrimaryAction(
            label: completed
                ? '완료'
                : isRunning
                    ? '일시정지'
                    : remaining < total
                        ? '재개'
                        : '시작',
            icon: completed
                ? Icons.check_rounded
                : isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
            enabled: !completed,
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.refresh_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.success,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
