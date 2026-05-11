import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/features/fridge/data/models/ingredient.dart';
import 'package:fridge_meal/features/fridge/data/models/storage_location.dart';

/// 재료 데이터 접근 추상 계층.
///
/// 향후 [SupabaseIngredientRepository]가 Supabase Postgres + Hive 캐시를
/// 결합한 형태로 구현된다. UI는 이 인터페이스에만 의존하므로 백엔드 도입 시
/// 표시 코드는 수정될 필요가 없다.
abstract class IngredientRepository {
  /// 현재 사용자의 전체 재료 목록을 가져온다.
  ///
  /// 정렬은 유통기한 가까운 순(없는 항목은 맨 뒤).
  Future<List<Ingredient>> fetchAll();

  /// 신규 재료 추가.
  Future<void> add(Ingredient ingredient);

  /// 기존 재료 갱신. `id`로 식별.
  Future<void> update(Ingredient ingredient);

  /// `id`의 재료 삭제.
  Future<void> delete(String id);
}

/// 실제 백엔드 연결 전 사용하는 임시 구현.
///
/// 내부에 가변 [List]를 유지하므로 add/update/delete가 같은 인스턴스 안에서
/// 즉시 반영된다. Provider 레이어에서 invalidateSelf로 UI 동기화.
///
/// 앱이 종료되면 사라지는 in-memory 저장소이며, 영속화는 Supabase가 담당한다.
class MockIngredientRepository implements IngredientRepository {
  MockIngredientRepository() {
    _seed();
  }

  final List<Ingredient> _items = <Ingredient>[];

  void _seed() {
    final DateTime today = DateTime.now();
    DateTime daysFromNow(int n) =>
        DateTime(today.year, today.month, today.day + n);

    _items.addAll(<Ingredient>[
      Ingredient(
        id: 'mock-1',
        userId: 'mock-user',
        name: '돼지고기',
        category: IngredientCategory.meat,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(1),
      ),
      Ingredient(
        id: 'mock-2',
        userId: 'mock-user',
        name: '우유',
        category: IngredientCategory.dairy,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(0),
      ),
      Ingredient(
        id: 'mock-3',
        userId: 'mock-user',
        name: '양파',
        category: IngredientCategory.vegetable,
        storage: StorageLocation.roomTemp,
        expiryDate: daysFromNow(2),
      ),
      Ingredient(
        id: 'mock-4',
        userId: 'mock-user',
        name: '두부',
        category: IngredientCategory.other,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(3),
      ),
      Ingredient(
        id: 'mock-5',
        userId: 'mock-user',
        name: '닭고기',
        category: IngredientCategory.meat,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(4),
      ),
      Ingredient(
        id: 'mock-6',
        userId: 'mock-user',
        name: '당근',
        category: IngredientCategory.vegetable,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(5),
      ),
      Ingredient(
        id: 'mock-7',
        userId: 'mock-user',
        name: '대파',
        category: IngredientCategory.vegetable,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(7),
      ),
      Ingredient(
        id: 'mock-8',
        userId: 'mock-user',
        name: '계란',
        category: IngredientCategory.dairy,
        storage: StorageLocation.fridge,
        expiryDate: daysFromNow(12),
      ),
      Ingredient(
        id: 'mock-9',
        userId: 'mock-user',
        name: '감자',
        category: IngredientCategory.vegetable,
        storage: StorageLocation.roomTemp,
        expiryDate: daysFromNow(15),
      ),
      Ingredient(
        id: 'mock-10',
        userId: 'mock-user',
        name: '간장',
        category: IngredientCategory.seasoning,
        storage: StorageLocation.roomTemp,
        expiryDate: daysFromNow(180),
      ),
    ]);
  }

  @override
  Future<List<Ingredient>> fetchAll() async {
    final List<Ingredient> sorted = List<Ingredient>.from(_items)
      ..sort(_byDaysLeftAsc);
    return sorted;
  }

  @override
  Future<void> add(Ingredient ingredient) async {
    _items.add(ingredient);
  }

  @override
  Future<void> update(Ingredient ingredient) async {
    final int index = _items.indexWhere(
      (Ingredient i) => i.id == ingredient.id,
    );
    if (index == -1) {
      throw StateError('Ingredient ${ingredient.id} not found');
    }
    _items[index] = ingredient;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((Ingredient i) => i.id == id);
  }

  /// D-day 오름차순. `expiryDate`가 null인 항목은 맨 뒤로 밀어낸다.
  static int _byDaysLeftAsc(Ingredient a, Ingredient b) {
    final int? da = a.daysLeft;
    final int? db = b.daysLeft;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }
}
