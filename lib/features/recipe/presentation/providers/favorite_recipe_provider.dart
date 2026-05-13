import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/recipe/data/models/recipe.dart';
import 'package:fridge_meal/features/recipe/data/repositories/favorite_recipe_repository.dart';

part 'favorite_recipe_provider.g.dart';

@Riverpod(keepAlive: true)
FavoriteRecipeRepository favoriteRecipeRepository(Ref ref) {
  return FavoriteRecipeRepository(Hive.box<String>('favorites'));
}

/// 즐겨찾기 레시피 목록 + 토글 액션.
///
/// 토글 후 자체적으로 새 리스트로 state를 갱신해 watch 중인 모든 위젯이
/// 즉시 반영되도록 한다. (Hive 자체는 ChangeNotifier가 아니라 명시 갱신 필요)
@Riverpod(keepAlive: true)
class FavoriteRecipes extends _$FavoriteRecipes {
  @override
  List<Recipe> build() {
    return ref.read(favoriteRecipeRepositoryProvider).readAll();
  }

  /// 토글 후 등록 상태(`true`면 추가됨)를 반환.
  Future<bool> toggle(Recipe recipe) async {
    final FavoriteRecipeRepository repo =
        ref.read(favoriteRecipeRepositoryProvider);
    final bool added = await repo.toggle(recipe);
    state = repo.readAll();
    return added;
  }

  bool isFavorite(String recipeId) {
    return state.any((Recipe r) => r.id == recipeId);
  }
}
