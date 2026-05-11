import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/data/repositories/ingredient_repository.dart';

part 'ingredient_provider.g.dart';

/// 재료 데이터 소스. 현재는 Mock, Day 3+ Supabase 연결 시 교체.
@Riverpod(keepAlive: true)
IngredientRepository ingredientRepository(Ref ref) {
  return MockIngredientRepository();
}

/// 현재 사용자의 전체 재료 목록 + mutate 액션.
///
/// Repository 호출 후 [ref.invalidateSelf]로 상태를 다시 빌드한다.
/// Mock은 동기적으로 끝나서 거의 즉시 반영되며, Supabase 도입 시에도
/// 동일 패턴(요청 성공 시 invalidate)으로 동작한다.
@Riverpod(keepAlive: true)
class Ingredients extends _$Ingredients {
  @override
  Future<List<Ingredient>> build() {
    return ref.watch(ingredientRepositoryProvider).fetchAll();
  }

  Future<void> addItem(Ingredient ingredient) async {
    await ref.read(ingredientRepositoryProvider).add(ingredient);
    ref.invalidateSelf();
  }

  Future<void> updateItem(Ingredient ingredient) async {
    await ref.read(ingredientRepositoryProvider).update(ingredient);
    ref.invalidateSelf();
  }

  Future<void> deleteItem(String id) async {
    await ref.read(ingredientRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}

/// 카테고리 필터 상태.
///
/// `null`이면 "전체" 선택.
@riverpod
class SelectedCategoryFilter extends _$SelectedCategoryFilter {
  @override
  IngredientCategory? build() => null;

  void select(IngredientCategory? category) => state = category;
}

/// 현재 데이터에서 1개 이상 존재하는 카테고리만 반환.
///
/// 필터 칩에 더미 카테고리가 노출되는 것을 막는다.
/// 결과는 `IngredientCategory` 선언 순서를 따른다.
@riverpod
List<IngredientCategory> availableCategories(Ref ref) {
  final AsyncValue<List<Ingredient>> all = ref.watch(ingredientsProvider);
  return all.maybeWhen(
    data: (List<Ingredient> list) {
      final Set<IngredientCategory> present = list
          .map((Ingredient i) => i.category)
          .toSet();
      return IngredientCategory.values
          .where((IngredientCategory c) => present.contains(c))
          .toList();
    },
    orElse: () => const <IngredientCategory>[],
  );
}

/// 필터가 적용된 재료 목록.
@riverpod
AsyncValue<List<Ingredient>> filteredIngredients(Ref ref) {
  final AsyncValue<List<Ingredient>> raw = ref.watch(ingredientsProvider);
  final IngredientCategory? filter = ref.watch(
    selectedCategoryFilterProvider,
  );
  return raw.whenData((List<Ingredient> list) {
    if (filter == null) return list;
    return list
        .where((Ingredient i) => i.category == filter)
        .toList(growable: false);
  });
}

/// 유통기한 임박(D-3 이내) 재료 수.
///
/// 배너 노출 조건에 사용. 필터 무관 전체 기준.
@riverpod
int expirySoonCount(Ref ref) {
  final AsyncValue<List<Ingredient>> all = ref.watch(ingredientsProvider);
  return all.maybeWhen(
    data: (List<Ingredient> list) =>
        list.where((Ingredient i) => i.isExpirySoon).length,
    orElse: () => 0,
  );
}
