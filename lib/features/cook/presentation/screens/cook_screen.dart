import 'package:flutter/material.dart';

import 'package:fridge_meal/shared/widgets/coming_soon_screen.dart';

/// 조합 탭 placeholder.
///
/// F-02 드래그앤드롭 + 항아리 + AI 레시피 생성이 통합되는 핵심 화면.
class CookScreen extends StatelessWidget {
  const CookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      title: '조합',
      icon: Icons.soup_kitchen_outlined,
      description: '재료를 항아리에 드래그해서\nAI 레시피를 받아볼 수 있어요.',
    );
  }
}
