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
}

/// 실제 백엔드 연결 전 사용하는 임시 구현.
///
/// 디자인 시안의 분위기를 빠르게 검증할 수 있도록 카테고리·D-day가
/// 분포된 10개의 샘플을 반환한다. 메모리 상수이므로 추가/삭제는 불가.
class MockIngredientRepository implements IngredientRepository {
  MockIngredientRepository();

  /// `DateTime.now()`를 기준으로 매번 D-day가 일관되게 계산되도록
  /// expiryDate를 동적으로 생성한다.
  @override
  Future<List<Ingredient>> fetchAll() async {
    final DateTime today = DateTime.now();
    DateTime daysFromNow(int n) =>
        DateTime(today.year, today.month, today.day + n);

    final List<Ingredient> items = <Ingredient>[
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
    ];

    items.sort(_byDaysLeftAsc);
    return items;
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
