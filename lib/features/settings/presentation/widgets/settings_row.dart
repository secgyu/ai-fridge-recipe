import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 설정 행 공통 레이아웃.
///
/// 디자인:
/// - 좌: 라벨 (15pt / 600 / textPrimary), 선택적 보조 텍스트
/// - 우: trailing 위젯 (chevron, switch, stepper, 값 텍스트 등)
/// - 탭 가능한 경우 onTap을 받음
///
/// 변종들은 같은 파일 안의 팩토리 위젯(SwitchRow / StepperRow / ValueRow)로 제공.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.foregroundColor,
  });

  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// 라벨 색 오버라이드 (예: 로그아웃의 danger 톤).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = foregroundColor ?? AppColors.textPrimary;
    final Widget content = Padding(
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
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.2,
                    color: labelColor,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) {
      return SizedBox(width: double.infinity, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // Section의 카드 라운딩을 살리려면 첫/끝 row만 살짝 둥글게 해야하지만
        // 시각적 차이가 미미해 전체 sm radius로 통일.
        borderRadius: AppRadius.rSm,
        child: SizedBox(width: double.infinity, child: content),
      ),
    );
  }
}

/// trailing이 chevron(>) + 우측 값 텍스트.
class ValueRow extends StatelessWidget {
  const ValueRow({
    super.key,
    required this.label,
    this.value,
    this.subtitle,
    this.onTap,
    this.foregroundColor,
  });

  final String label;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: label,
      subtitle: subtitle,
      onTap: onTap,
      foregroundColor: foregroundColor,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );
  }
}

/// trailing이 Cupertino-style switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: label,
      subtitle: subtitle,
      onTap: () => onChanged(!value),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

/// trailing이 [- N +] 스테퍼.
class StepperRow extends StatelessWidget {
  const StepperRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onDecrement,
    required this.onIncrement,
    this.unit = '',
  });

  final String label;
  final String? subtitle;
  final int value;
  final int min;
  final int max;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      label: label,
      subtitle: subtitle,
      trailing: _StepperControl(
        value: value,
        canDecrement: value > min,
        canIncrement: value < max,
        onDecrement: onDecrement,
        onIncrement: onIncrement,
        unit: unit,
      ),
    );
  }
}

class _StepperControl extends StatelessWidget {
  const _StepperControl({
    required this.value,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
    required this.unit,
  });

  final int value;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _IconButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: onDecrement,
            semanticsLabel: '감소',
          ),
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                unit.isEmpty ? '$value' : '$value$unit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          _IconButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onTap: onIncrement,
            semanticsLabel: '증가',
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 18,
              color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
