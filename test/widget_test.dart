import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fridge_meal/app.dart';

void main() {
  testWidgets('Day 0 setup screen renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: FridgeMealApp()),
    );

    expect(find.text('냉장고 한 끼'), findsOneWidget);
    expect(find.text('Day 0 셋업 완료\nDay 1부터 디자인 시스템 시작'), findsOneWidget);
  });
}
