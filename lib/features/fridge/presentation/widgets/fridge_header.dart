import 'package:flutter/material.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 냉장고 화면 상단 헤더.
///
/// - 제목 "내 냉장고" + 보유 재료 개수
/// - 우측: 알림 벨 + 재료 추가(+) 버튼
class FridgeHeader extends StatelessWidget {
  const FridgeHeader({
    super.key,
    required this.count,
    required this.onNotificationTap,
    required this.onAddTap,
  });

  final int count;
  final VoidCallback onNotificationTap;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '내 냉장고',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '총 $count개 재료',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    letterSpacing: -0.1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.notifications_none_rounded,
            semanticsLabel: '알림',
            onTap: onNotificationTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          _CircleIconButton(
            icon: Icons.add_rounded,
            semanticsLabel: '재료 추가',
            onTap: onAddTap,
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: AppColors.surfaceSubtle,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
