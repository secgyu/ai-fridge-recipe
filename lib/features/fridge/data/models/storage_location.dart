/// 재료 보관 위치.
///
/// Postgres에는 enum 이름(`fridge`/`freezer`/`roomTemp`)으로 저장된다.
enum StorageLocation {
  fridge('냉장 보관'),
  freezer('냉동 보관'),
  roomTemp('실온 보관');

  const StorageLocation(this.label);

  final String label;
}
