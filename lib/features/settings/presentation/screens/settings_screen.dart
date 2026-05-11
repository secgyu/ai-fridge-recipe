import 'package:flutter/material.dart';

import 'package:fridge_meal/shared/widgets/coming_soon_screen.dart';

/// 설정 탭 placeholder.
///
/// 알림 ON/OFF, 기본 인분 수, 식이 제한, 로그아웃 등 (F-09).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: '설정',
      icon: Icons.settings_outlined,
      description: '알림, 인분 수, 알레르기 등\n맞춤 설정이 곧 추가돼요.',
    );
  }
}
