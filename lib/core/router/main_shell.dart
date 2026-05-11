import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';

/// 메인 4탭 셸.
///
/// `StatefulShellRoute.indexedStack`이 제공하는 [navigationShell]로
/// 각 탭의 네비게이션 스택이 독립 유지된다. 탭 전환은 즉시(IndexedStack).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    unawaited(HapticFeedback.selectionClick());
    // 같은 탭을 다시 탭하면 해당 탭의 스택을 루트로 pop.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: _goBranch,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const List<_NavSpec> _items = <_NavSpec>[
    _NavSpec(
      label: '냉장고',
      icon: Icons.kitchen_outlined,
      selectedIcon: Icons.kitchen_rounded,
    ),
    _NavSpec(
      label: '조합',
      icon: Icons.soup_kitchen_outlined,
      selectedIcon: Icons.soup_kitchen_rounded,
    ),
    _NavSpec(
      label: '기록',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book_rounded,
    ),
    _NavSpec(
      label: '설정',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    spec: _items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? AppColors.primary : AppColors.textTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightShape: BoxShape.circle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(selected ? spec.selectedIcon : spec.icon, size: 24, color: fg),
              const SizedBox(height: 4),
              Text(
                spec.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  height: 1.2,
                  letterSpacing: -0.2,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
