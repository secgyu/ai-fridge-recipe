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
  /// Phase 1 MVP: 핵심 5개로 시작, 톤 검증 후 30개까지 확장.
  static const Map<String, String> _ingredientMap = <String, String>{
    '감자': '$_ingredientBase/potato.png',
    '양파': '$_ingredientBase/onion.png',
    '당근': '$_ingredientBase/carrot.png',
    '계란': '$_ingredientBase/egg.png',
    '돼지고기': '$_ingredientBase/pork.png',
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
