/// 사용자 식이 제한.
///
/// 레시피 추천 시 Edge Function에 함께 전달되어 결과 필터링/조정.
/// MVP에서는 UI만 구현, F-03 호출부 통합은 Supabase 연동 단계에서.
enum DietaryRestriction {
  vegetarian('vegetarian', '채식', '고기를 먹지 않아요'),
  vegan('vegan', '비건', '동물성 식품 전부 제외'),
  pescatarian('pescatarian', '페스코', '고기 대신 해산물은 OK'),
  glutenFree('gluten_free', '글루텐 프리', '밀가루를 피해요'),
  lactoseFree('lactose_free', '유당 불내증', '유제품 피해요'),
  nuts('nuts', '견과류 알레르기', '땅콩·호두·아몬드 등'),
  shrimp('shrimp', '갑각류 알레르기', '새우·게'),
  egg('egg', '달걀 알레르기', '계란 함유 피해요'),
  soy('soy', '대두 알레르기', '두부·간장·된장 함유 피해요');

  const DietaryRestriction(this.value, this.label, this.description);

  /// Postgres/Edge Function 전송용 안정 식별자.
  final String value;

  /// 칩 텍스트.
  final String label;

  /// 사용자 설명 (subtitle).
  final String description;

  static DietaryRestriction? fromValue(String value) {
    for (final DietaryRestriction r in DietaryRestriction.values) {
      if (r.value == value) return r;
    }
    return null;
  }
}
