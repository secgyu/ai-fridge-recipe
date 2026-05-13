import 'package:fridge_meal/core/constants/ingredient_category.dart';

/// 자동완성에 노출되는 신선식품 마스터 항목.
///
/// Phase 1 MVP에서는 코드 내 정적 리스트 ([kIngredientMasters])를 사용한다.
/// 데이터가 늘어나면 별도 JSON 자산 또는 Edge Function으로 분리 검토.
class IngredientMaster {
  const IngredientMaster({
    required this.name,
    required this.category,
    this.aliases = const <String>[],
    this.defaultExpiryDays,
  });

  /// 사용자에게 보일 표준 한국어명. (예: "양파")
  final String name;

  final IngredientCategory category;

  /// 검색 매칭용 별칭/철자 변형. (예: "양파" → ["양파", "어니언"])
  final List<String> aliases;

  /// 등록 시 D-day 미입력이면 이 값으로 자동 채움. null이면 미설정.
  final int? defaultExpiryDays;

  /// 입력 텍스트가 [name] 또는 [aliases] 중 하나의 prefix 또는 contains
  /// 매칭이면 true. 공백·대소문자 정규화.
  bool matches(String query) {
    final String q = query.trim();
    if (q.isEmpty) return false;
    if (name.contains(q)) return true;
    return aliases.any((String a) => a.contains(q));
  }
}

/// 30개 큐레이션된 신선식품 자동완성 마스터.
///
/// 일러스트 매칭이 보장된 재료만 1차로 노출. [image_mapper]의 키와 1:1 대응.
const List<IngredientMaster> kIngredientMasters = <IngredientMaster>[
  // 채소
  IngredientMaster(
    name: '감자',
    category: IngredientCategory.vegetable,
    aliases: <String>['감자', 'potato'],
    defaultExpiryDays: 21,
  ),
  IngredientMaster(
    name: '양파',
    category: IngredientCategory.vegetable,
    aliases: <String>['양파', '어니언', 'onion'],
    defaultExpiryDays: 21,
  ),
  IngredientMaster(
    name: '당근',
    category: IngredientCategory.vegetable,
    aliases: <String>['당근', 'carrot'],
    defaultExpiryDays: 14,
  ),
  IngredientMaster(
    name: '마늘',
    category: IngredientCategory.vegetable,
    aliases: <String>['마늘', '깐마늘', 'garlic'],
    defaultExpiryDays: 30,
  ),
  IngredientMaster(
    name: '대파',
    category: IngredientCategory.vegetable,
    aliases: <String>['대파', '파', 'green onion'],
    defaultExpiryDays: 10,
  ),
  IngredientMaster(
    name: '고추',
    category: IngredientCategory.vegetable,
    aliases: <String>['고추', '청양고추', '풋고추', 'chili'],
    defaultExpiryDays: 7,
  ),
  IngredientMaster(
    name: '배추',
    category: IngredientCategory.vegetable,
    aliases: <String>['배추', '알배기배추', 'cabbage'],
    defaultExpiryDays: 14,
  ),
  IngredientMaster(
    name: '무',
    category: IngredientCategory.vegetable,
    aliases: <String>['무', '무우', 'radish'],
    defaultExpiryDays: 21,
  ),
  IngredientMaster(
    name: '애호박',
    category: IngredientCategory.vegetable,
    aliases: <String>['애호박', '호박', 'zucchini'],
    defaultExpiryDays: 7,
  ),
  IngredientMaster(
    name: '버섯',
    category: IngredientCategory.vegetable,
    aliases: <String>['버섯', '느타리', '팽이', 'mushroom'],
    defaultExpiryDays: 5,
  ),

  // 육류·해산물
  IngredientMaster(
    name: '돼지고기',
    category: IngredientCategory.meat,
    aliases: <String>['돼지고기', '돼지', '삼겹살', '목살', 'pork'],
    defaultExpiryDays: 3,
  ),
  IngredientMaster(
    name: '소고기',
    category: IngredientCategory.meat,
    aliases: <String>['소고기', '쇠고기', '한우', 'beef'],
    defaultExpiryDays: 3,
  ),
  IngredientMaster(
    name: '닭고기',
    category: IngredientCategory.meat,
    aliases: <String>['닭고기', '닭', '닭가슴살', 'chicken'],
    defaultExpiryDays: 2,
  ),
  IngredientMaster(
    name: '새우',
    category: IngredientCategory.seafood,
    aliases: <String>['새우', 'shrimp'],
    defaultExpiryDays: 2,
  ),
  IngredientMaster(
    name: '오징어',
    category: IngredientCategory.seafood,
    aliases: <String>['오징어', 'squid'],
    defaultExpiryDays: 2,
  ),

  // 유제품·계란
  IngredientMaster(
    name: '계란',
    category: IngredientCategory.dairy,
    aliases: <String>['계란', '달걀', 'egg'],
    defaultExpiryDays: 21,
  ),
  IngredientMaster(
    name: '우유',
    category: IngredientCategory.dairy,
    aliases: <String>['우유', 'milk'],
    defaultExpiryDays: 7,
  ),
  IngredientMaster(
    name: '치즈',
    category: IngredientCategory.dairy,
    aliases: <String>['치즈', 'cheese'],
    defaultExpiryDays: 14,
  ),
  IngredientMaster(
    name: '버터',
    category: IngredientCategory.dairy,
    aliases: <String>['버터', 'butter'],
    defaultExpiryDays: 30,
  ),
  IngredientMaster(
    name: '요거트',
    category: IngredientCategory.dairy,
    aliases: <String>['요거트', '요구르트', 'yogurt'],
    defaultExpiryDays: 14,
  ),

  // 곡물·면·빵
  IngredientMaster(
    name: '쌀',
    category: IngredientCategory.grain,
    aliases: <String>['쌀', '백미', 'rice'],
    defaultExpiryDays: 90,
  ),
  IngredientMaster(
    name: '밀가루',
    category: IngredientCategory.grain,
    aliases: <String>['밀가루', '강력분', '박력분', 'flour'],
    defaultExpiryDays: 180,
  ),
  IngredientMaster(
    name: '라면',
    category: IngredientCategory.grain,
    aliases: <String>['라면', '신라면', 'ramen'],
    defaultExpiryDays: 180,
  ),
  IngredientMaster(
    name: '우동',
    category: IngredientCategory.grain,
    aliases: <String>['우동', 'udon'],
    defaultExpiryDays: 30,
  ),
  IngredientMaster(
    name: '식빵',
    category: IngredientCategory.grain,
    aliases: <String>['식빵', '빵', 'bread'],
    defaultExpiryDays: 5,
  ),

  // 양념·기타
  IngredientMaster(
    name: '간장',
    category: IngredientCategory.seasoning,
    aliases: <String>['간장', 'soy sauce'],
    defaultExpiryDays: 365,
  ),
  IngredientMaster(
    name: '고추장',
    category: IngredientCategory.seasoning,
    aliases: <String>['고추장', 'gochujang'],
    defaultExpiryDays: 365,
  ),
  IngredientMaster(
    name: '된장',
    category: IngredientCategory.seasoning,
    aliases: <String>['된장', 'doenjang'],
    defaultExpiryDays: 365,
  ),
  IngredientMaster(
    name: '설탕',
    category: IngredientCategory.seasoning,
    aliases: <String>['설탕', 'sugar'],
    defaultExpiryDays: 365,
  ),
  IngredientMaster(
    name: '두부',
    category: IngredientCategory.other,
    aliases: <String>['두부', 'tofu'],
    defaultExpiryDays: 7,
  ),
];

/// 부분일치 기반 자동완성 검색. 결과는 최대 [limit]개.
List<IngredientMaster> searchIngredientMasters(
  String query, {
  int limit = 8,
}) {
  final String q = query.trim();
  if (q.isEmpty) return const <IngredientMaster>[];
  final List<IngredientMaster> hits = kIngredientMasters
      .where((IngredientMaster m) => m.matches(q))
      .toList(growable: false);
  return hits.length <= limit ? hits : hits.sublist(0, limit);
}
