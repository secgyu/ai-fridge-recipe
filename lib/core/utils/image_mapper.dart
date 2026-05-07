import 'package:fridge_meal/core/constants/ingredient_category.dart';

/// 재료 이름·카테고리 → 일러스트 에셋 경로 매핑.
///
/// 3-tier 폴백 전략:
/// 1. 직접 매핑: 큐레이션된 핵심 재료 (Phase 1: 30개, Phase 2+: 확장)
/// 2. 카테고리 폴백: 8개 (채소, 과일, 육류, 해산물, 유제품, 곡물/면, 양념, 기타)
/// 3. 일반 폴백: `other.png`
///
/// 경로는 항상 이 클래스를 통해 해결한다. 직접 하드코딩 금지.
class IngredientImageMapper {
  const IngredientImageMapper._();

  static const String _ingredientBase = 'assets/images/ingredients';
  static const String _categoryBase = 'assets/images/categories';

  /// 한국어 재료명(정규화된 키) → 일러스트 경로.
  /// Phase 1 MVP 30종. 추후 사용 데이터 기반으로 확장.
  static const Map<String, String> _ingredientMap = <String, String>{
    // 채소 (10)
    '감자': '$_ingredientBase/potato.png',
    '양파': '$_ingredientBase/onion.png',
    '당근': '$_ingredientBase/carrot.png',
    '마늘': '$_ingredientBase/garlic.png',
    '대파': '$_ingredientBase/green_onion.png',
    '고추': '$_ingredientBase/chili.png',
    '배추': '$_ingredientBase/cabbage.png',
    '무': '$_ingredientBase/radish.png',
    '애호박': '$_ingredientBase/zucchini.png',
    '버섯': '$_ingredientBase/mushroom.png',

    // 육류·해산물 (5)
    '돼지고기': '$_ingredientBase/pork.png',
    '소고기': '$_ingredientBase/beef.png',
    '닭고기': '$_ingredientBase/chicken.png',
    '새우': '$_ingredientBase/shrimp.png',
    '오징어': '$_ingredientBase/squid.png',

    // 유제품·계란 (5)
    '계란': '$_ingredientBase/egg.png',
    '우유': '$_ingredientBase/milk.png',
    '치즈': '$_ingredientBase/cheese.png',
    '버터': '$_ingredientBase/butter.png',
    '요거트': '$_ingredientBase/yogurt.png',

    // 곡물·면·빵 (5)
    '쌀': '$_ingredientBase/rice.png',
    '밀가루': '$_ingredientBase/flour.png',
    '라면': '$_ingredientBase/ramen.png',
    '우동': '$_ingredientBase/udon.png',
    '식빵': '$_ingredientBase/bread.png',

    // 양념·기타 (5)
    '간장': '$_ingredientBase/soy_sauce.png',
    '고추장': '$_ingredientBase/gochujang.png',
    '된장': '$_ingredientBase/doenjang.png',
    '설탕': '$_ingredientBase/sugar.png',
    '두부': '$_ingredientBase/tofu.png',
  };

  static const Map<IngredientCategory, String> _categoryMap =
      <IngredientCategory, String>{
    IngredientCategory.vegetable: '$_categoryBase/vegetable.png',
    IngredientCategory.fruit: '$_categoryBase/fruit.png',
    IngredientCategory.meat: '$_categoryBase/meat.png',
    IngredientCategory.seafood: '$_categoryBase/seafood.png',
    IngredientCategory.dairy: '$_categoryBase/dairy.png',
    IngredientCategory.grain: '$_categoryBase/grain.png',
    IngredientCategory.seasoning: '$_categoryBase/seasoning.png',
    IngredientCategory.other: '$_categoryBase/other.png',
  };

  /// 재료명과 카테고리로부터 가장 적절한 일러스트 경로를 결정한다.
  static String resolve({
    required String name,
    required IngredientCategory category,
  }) {
    final String normalized = name.trim();
    return _ingredientMap[normalized] ??
        _categoryMap[category] ??
        '$_categoryBase/other.png';
  }
}
