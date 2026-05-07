/// 재료 카테고리.
///
/// 이미지 폴백, 필터, 통계 등 도메인 전반에서 사용된다.
/// 사용자 입력을 자동 분류하는 책임은 서버(`generate-recipe` Edge Function)에 있다.
enum IngredientCategory {
  vegetable('채소'),
  fruit('과일'),
  meat('육류'),
  seafood('해산물'),
  dairy('유제품'),
  grain('곡물/면'),
  seasoning('양념'),
  other('기타');

  const IngredientCategory(this.label);

  final String label;
}
