import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';

part 'selected_ingredients_provider.g.dart';

/// 항아리에 담긴 재료(F-02 드래그앤드롭의 핵심 상태).
///
/// 화면 떠나도 유지되어 사용자가 재료를 추가하다가 다른 탭에 다녀와도
/// 진행 상태가 그대로 남도록 [keepAlive] 설정. F-03 레시피 생성 후
/// 결과 화면 또는 사용자가 명시적으로 비우기 전까지 유지.
@Riverpod(keepAlive: true)
class SelectedIngredients extends _$SelectedIngredients {
  @override
  List<Ingredient> build() => const <Ingredient>[];

  /// 같은 id 재료는 무시 (중복 추가 방지).
  void add(Ingredient ingredient) {
    if (state.any((Ingredient i) => i.id == ingredient.id)) return;
    state = <Ingredient>[...state, ingredient];
  }

  void remove(String id) {
    state = state.where((Ingredient i) => i.id != id).toList(growable: false);
  }

  void clear() => state = const <Ingredient>[];
}
