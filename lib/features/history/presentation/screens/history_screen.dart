import 'package:flutter/material.dart';

import 'package:fridge_meal/shared/widgets/coming_soon_screen.dart';

/// 기록 탭 placeholder.
///
/// 즐겨찾기 레시피 + 만든 요리 히스토리(F-07)를 위한 자리.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: '기록',
      icon: Icons.menu_book_outlined,
      description: '즐겨찾은 레시피와\n만든 요리의 기록이 여기에 쌓여요.',
    );
  }
}
