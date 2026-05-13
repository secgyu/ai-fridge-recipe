import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';
import 'package:fridge_meal/features/recipe/data/repositories/recipe_repository.dart';

part 'recipe_provider.g.dart';

/// 레시피 Repository (현재 mock, Supabase Edge Function 도입 시 교체).
@Riverpod(keepAlive: true)
RecipeRepository recipeRepository(Ref ref) => MockRecipeRepository();

/// 마지막으로 생성된 레시피 결과를 보관하는 Notifier.
///
/// 결과 화면 진입 시 [generate]를 호출하면 로딩 → 결과 흐름을 노출한다.
/// 화면이 뒤로 나가도 상태가 유지되어, 같은 재료 조합으로 재진입 시
/// 즉시 결과를 보여줄 수 있다(추후 캐싱 최적화 여지).
@Riverpod(keepAlive: true)
class RecipeResults extends _$RecipeResults {
  @override
  Future<List<Recipe>> build() async => const <Recipe>[];

  /// 항아리에 담긴 재료로 새 레시피 추천 요청.
  Future<void> generate(List<Ingredient> ingredients) async {
    state = const AsyncLoading<List<Recipe>>();
    state = await AsyncValue.guard<List<Recipe>>(
      () => ref.read(recipeRepositoryProvider).generateRecipes(ingredients),
    );
  }
}
