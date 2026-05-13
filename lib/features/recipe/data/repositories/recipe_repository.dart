import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe_difficulty.dart';

/// 레시피 생성 / 조회 인터페이스.
///
/// 실제 구현은 Supabase Edge Function `generate-recipe`를 호출한다.
/// 지금은 입력 재료 목록을 받아 정해진 mock 응답을 반환.
abstract class RecipeRepository {
  /// 항아리에 담긴 재료들로 레시피 추천 받기.
  ///
  /// 백엔드 연결 전까지는 mock 데이터를 1.6초 지연 후 반환 (로딩 UX 검증).
  Future<List<Recipe>> generateRecipes(List<Ingredient> ingredients);

  /// 결과 리스트에서 카드 탭 시 상세 조회.
  /// MVP에서는 결과 list를 그대로 들고 상세로 전달하므로 별도 fetch 없음.
  /// (Supabase 도입 후 즐겨찾기에서 복원할 때 사용)
  Future<Recipe?> findById(String id);
}

class MockRecipeRepository implements RecipeRepository {
  MockRecipeRepository();

  static const Duration _latency = Duration(milliseconds: 1600);

  @override
  Future<List<Recipe>> generateRecipes(List<Ingredient> ingredients) async {
    await Future<void>.delayed(_latency);

    final Set<String> ownedNames =
        ingredients.map((Ingredient i) => i.name).toSet();

    bool owned(String name) => ownedNames.contains(name);

    final List<Recipe> all = <Recipe>[
      Recipe(
        id: 'potato_stir_fry',
        name: '감자채 볶음',
        category: '볶음',
        difficulty: RecipeDifficulty.easy,
        cookingMinutes: 15,
        servings: 2,
        tagline: '아삭아삭, 한 그릇 뚝딱',
        ingredients: <RecipeIngredient>[
          RecipeIngredient(name: '감자', amount: '2개', isOwned: owned('감자')),
          RecipeIngredient(name: '양파', amount: '1/2개', isOwned: owned('양파')),
          RecipeIngredient(name: '당근', amount: '1/4개', isOwned: owned('당근')),
          const RecipeIngredient(name: '식용유', amount: '2큰술'),
          const RecipeIngredient(name: '소금', amount: '약간'),
        ],
        steps: const <RecipeStep>[
          RecipeStep(
            index: 1,
            description: '감자는 채 썰어 찬물에 5분간 담가 전분기를 뺀 뒤 물기를 제거해요.',
            timerSeconds: 300,
          ),
          RecipeStep(index: 2, description: '양파와 당근도 얇게 채 썰어 준비해요.'),
          RecipeStep(
            index: 3,
            description: '팬에 식용유를 두르고 중불에서 양파를 30초간 볶아 향을 내요.',
            timerSeconds: 30,
          ),
          RecipeStep(
            index: 4,
            description: '감자채와 당근을 넣고 4~5분간 볶다가 소금으로 간을 맞춰 마무리해요.',
            timerSeconds: 270,
          ),
        ],
        tips: const <String>[
          '감자채를 물에 담가두면 볶을 때 들러붙지 않아요.',
          '센 불에서 빠르게 볶으면 아삭한 식감이 살아요.',
        ],
      ),
      Recipe(
        id: 'egg_roll',
        name: '계란말이',
        category: '반찬',
        difficulty: RecipeDifficulty.easy,
        cookingMinutes: 10,
        servings: 2,
        tagline: '도시락에 빠지면 섭섭한 그것',
        ingredients: <RecipeIngredient>[
          RecipeIngredient(name: '계란', amount: '4개', isOwned: owned('계란')),
          RecipeIngredient(name: '양파', amount: '1/4개', isOwned: owned('양파')),
          RecipeIngredient(name: '당근', amount: '약간', isOwned: owned('당근')),
          const RecipeIngredient(name: '소금', amount: '한 꼬집'),
          const RecipeIngredient(name: '식용유', amount: '1큰술'),
        ],
        steps: const <RecipeStep>[
          RecipeStep(index: 1, description: '양파와 당근을 잘게 다져요.'),
          RecipeStep(index: 2, description: '계란 4개를 풀어 다진 채소와 소금을 넣고 잘 섞어요.'),
          RecipeStep(
            index: 3,
            description: '약한 불 팬에 기름을 살짝 두르고 계란물 1/3을 부어 익을 때까지 기다려요.',
            timerSeconds: 60,
          ),
          RecipeStep(
            index: 4,
            description: '한쪽부터 돌돌 말아주고, 빈 자리에 계란물을 추가로 부어 다시 말아요. 두 번 반복.',
          ),
          RecipeStep(index: 5, description: '한 김 식힌 후 1cm 두께로 썰어 완성해요.'),
        ],
        tips: const <String>[
          '약한 불에서 천천히 익혀야 갈라지지 않아요.',
          '식힌 후 잘라야 단면이 깔끔해요.',
        ],
      ),
      Recipe(
        id: 'onion_soup',
        name: '양파 수프',
        category: '국·수프',
        difficulty: RecipeDifficulty.medium,
        cookingMinutes: 35,
        servings: 2,
        tagline: '추운 날 속을 데워주는 한 그릇',
        ingredients: <RecipeIngredient>[
          RecipeIngredient(name: '양파', amount: '큰 것 2개', isOwned: owned('양파')),
          const RecipeIngredient(name: '버터', amount: '2큰술'),
          const RecipeIngredient(name: '물', amount: '500ml'),
          const RecipeIngredient(name: '소금', amount: '약간'),
          const RecipeIngredient(name: '후추', amount: '약간'),
        ],
        steps: const <RecipeStep>[
          RecipeStep(index: 1, description: '양파를 얇게 채 썰어요.'),
          RecipeStep(
            index: 2,
            description: '냄비에 버터를 녹이고 양파를 15분간 갈색이 될 때까지 충분히 볶아요.',
            timerSeconds: 900,
          ),
          RecipeStep(
            index: 3,
            description: '물 500ml를 붓고 15분간 약불에서 끓여요.',
            timerSeconds: 900,
          ),
          RecipeStep(index: 4, description: '소금과 후추로 간을 맞춰 완성해요.'),
        ],
        tips: const <String>[
          '양파를 충분히 갈색이 될 때까지 볶아야 깊은 단맛이 나요.',
          '빵 한 조각을 띄우면 정통 프렌치 어니언 수프 느낌.',
        ],
      ),
    ];

    // 보유 매칭 점수 기준 내림차순. 같으면 짧은 요리 시간 우선.
    all.sort((Recipe a, Recipe b) {
      final int sa = a.ingredientMatch.owned * 10 - a.cookingMinutes;
      final int sb = b.ingredientMatch.owned * 10 - b.cookingMinutes;
      return sb.compareTo(sa);
    });

    return all;
  }

  @override
  Future<Recipe?> findById(String id) async {
    final List<Recipe> all = await generateRecipes(<Ingredient>[]);
    try {
      return all.firstWhere((Recipe r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
