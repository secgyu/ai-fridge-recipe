import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fridge_meal/features/recipe/data/models/recipe_difficulty.dart';

part 'recipe.freezed.dart';
part 'recipe.g.dart';

/// AI가 추천한 레시피 한 건.
///
/// MVP에서는 Edge Function `generate-recipe`의 응답을 그대로 매핑한다.
/// 결과 화면(F-03) → 상세(F-05)로 그대로 전달되며, 즐겨찾기 시 Hive에 저장.
@freezed
abstract class Recipe with _$Recipe {
  const Recipe._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Recipe({
    /// 카탈로그 ID (`assets/images/dishes/{id}.png` 매칭용).
    /// 예: `potato_stir_fry`, `egg_roll`.
    required String id,
    required String name,

    /// 자유 카테고리 텍스트 ("볶음", "국", "찌개" 등).
    required String category,
    required RecipeDifficulty difficulty,
    required int cookingMinutes,
    required int servings,

    /// 메인 일러스트 자리. 미존재시 카테고리/이모지 폴백 사용.
    /// 예: `assets/images/dishes/potato_stir_fry.png`.
    String? imagePath,
    required List<RecipeIngredient> ingredients,
    required List<RecipeStep> steps,
    @Default(<String>[]) List<String> tips,

    /// 캐릭터를 살리는 짧은 한 줄 설명 (선택).
    String? tagline,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  /// 보유 재료 수 / 총 재료 수. 결과 카드의 매칭률 표시용.
  ({int owned, int total}) get ingredientMatch {
    final int owned = ingredients.where((RecipeIngredient i) => i.isOwned).length;
    return (owned: owned, total: ingredients.length);
  }
}

/// 레시피 한 건의 재료 한 줄.
@freezed
abstract class RecipeIngredient with _$RecipeIngredient {
  const factory RecipeIngredient({
    required String name,
    required String amount,

    /// 사용자 냉장고에 있는 재료인지. 결과 화면 매칭 표시 + 상세 체크리스트.
    @Default(false) bool isOwned,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
}

/// 레시피 한 단계.
@freezed
abstract class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    /// 1부터 시작.
    required int index,
    required String description,

    /// 이 단계에서 사용할 타이머 길이(초). `null`이면 타이머 없음.
    int? timerSeconds,
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);
}
