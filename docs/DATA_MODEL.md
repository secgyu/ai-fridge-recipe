# DATA_MODEL: 데이터 모델 (Postgres + Freezed + hive_ce)

## 데이터 레이어 구조

```
┌─────────────────────────────────────┐
│  Domain Model (Freezed)             │  비즈니스 로직 + UI
│  - Ingredient, Recipe, CookHistory  │
└──────────┬──────────────────────────┘
           │
   ┌───────┴────────────┐
   ▼                    ▼
[Postgres DTO]     [Hive Cache (hive_ce)]
JSON serializable   오프라인 폴백
   ▲                    ▲
   │                    │
[Supabase Postgres]  [Local Hive Boxes]
   원본 (source)        캐시
```

> **Freezed + Hive 충돌은 `hive_ce` 사용으로 해결.**
> hive_ce는 Hive의 active fork로 Freezed factory 파라미터의 `@HiveField` 어노테이션을 정상 인식한다. `hive_generator` 대신 `hive_ce_generator`를 사용한다.

---

## 1. Postgres 스키마

### `supabase/migrations/0001_init.sql`

```sql
-- ============================================
-- 1) ingredients (재료)
-- ============================================
CREATE TABLE ingredients (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        text NOT NULL,
  barcode     text,
  category    text NOT NULL,           -- vegetable | fruit | meat | seafood | dairy | seasoning | grain | beverage | other
  quantity    int  NOT NULL DEFAULT 1,
  unit        text NOT NULL DEFAULT '개',
  expiry_date date,
  storage_type text NOT NULL DEFAULT 'refrigerator',  -- refrigerator | freezer | room
  image_asset text NOT NULL,           -- 'tomato' 같은 키
  source      text NOT NULL DEFAULT 'manual',         -- barcode | ocr | manual
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_ingredients_user_expiry
  ON ingredients (user_id, expiry_date NULLS LAST);

-- ============================================
-- 2) recipes (즐겨찾기 + 생성 이력)
-- ============================================
CREATE TABLE recipes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id     text NOT NULL,         -- 'potato_stir_fry' (카탈로그 키)
  name          text NOT NULL,
  category      text NOT NULL,
  difficulty    text NOT NULL,
  time_minutes  int  NOT NULL,
  servings      int  NOT NULL,
  match_rate    int  NOT NULL,
  ingredients   jsonb NOT NULL,
  steps         jsonb NOT NULL,
  tips          text,
  is_favorite   boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_recipes_user_favorite
  ON recipes (user_id, is_favorite) WHERE is_favorite = true;

-- ============================================
-- 3) cook_history (요리 완료 기록)
-- ============================================
CREATE TABLE cook_history (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id         text NOT NULL,
  recipe_name       text NOT NULL,
  used_ingredients  text[] NOT NULL,
  cooked_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cook_history_user_date
  ON cook_history (user_id, cooked_at DESC);

-- ============================================
-- 4) recipe_cache (전역 캐시 — 모든 사용자가 공유)
-- ============================================
CREATE TABLE recipe_cache (
  cache_key           text PRIMARY KEY,         -- SHA-256(ingredients_sorted)
  ingredients_sorted  text[] NOT NULL,
  recipes             jsonb  NOT NULL,
  hit_count           int    NOT NULL DEFAULT 0,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_recipe_cache_created ON recipe_cache (created_at DESC);

-- ============================================
-- 5) barcode_cache (전역 캐시 — 바코드는 변하지 않음)
-- ============================================
CREATE TABLE barcode_cache (
  barcode                       text PRIMARY KEY,
  name                          text NOT NULL,
  food_type                     text,
  manufacturer                  text,
  expiry_days_from_manufacture  int,
  category                      text NOT NULL,
  found                         boolean NOT NULL DEFAULT true,
  created_at                    timestamptz NOT NULL DEFAULT now()
);

-- ============================================
-- 6) api_usage (Rate Limit 추적)
-- ============================================
CREATE TABLE api_usage (
  id                 bigserial PRIMARY KEY,
  user_id            uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  function_name      text NOT NULL,
  cost_estimate_usd  numeric(10, 6) NOT NULL DEFAULT 0,
  created_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_api_usage_user_func_date
  ON api_usage (user_id, function_name, created_at);

-- ============================================
-- 7) 트리거: updated_at 자동 갱신
-- ============================================
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ingredients_updated
  BEFORE UPDATE ON ingredients
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

### `supabase/migrations/0002_rls.sql`

```sql
-- ingredients: 본인 것만
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ingredients_own" ON ingredients FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- recipes: 본인 것만
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "recipes_own" ON recipes FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- cook_history: 본인 것만
ALTER TABLE cook_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "history_own" ON cook_history FOR ALL
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- recipe_cache, barcode_cache: 클라이언트 직접 접근 차단 (Edge Function만)
ALTER TABLE recipe_cache  ENABLE ROW LEVEL SECURITY;
ALTER TABLE barcode_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_usage     ENABLE ROW LEVEL SECURITY;
-- 정책 미등록 = 모든 클라이언트 접근 차단, service_role만 접근 가능
```

---

## 2. Domain Model (Freezed)

### `lib/features/fridge/data/models/ingredient.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

@freezed
@HiveType(typeId: 0)
class Ingredient with _$Ingredient {
  const factory Ingredient({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String name,
    @HiveField(3) String? barcode,
    @HiveField(4) required IngredientCategory category,
    @HiveField(5) @Default(1) int quantity,
    @HiveField(6) @Default('개') String unit,
    @HiveField(7) String? expiryDate,           // ISO 'YYYY-MM-DD'
    @HiveField(8) @Default(StorageType.refrigerator) StorageType storageType,
    @HiveField(9) required String imageAsset,
    @HiveField(10) @Default(IngredientSource.manual) IngredientSource source,
    @HiveField(11) required String createdAt,    // ISO timestamp
    @HiveField(12) required String updatedAt,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}

@HiveType(typeId: 1)
enum IngredientCategory {
  @HiveField(0) @JsonValue('vegetable') vegetable,
  @HiveField(1) @JsonValue('fruit')      fruit,
  @HiveField(2) @JsonValue('meat')       meat,
  @HiveField(3) @JsonValue('seafood')    seafood,
  @HiveField(4) @JsonValue('dairy')      dairy,
  @HiveField(5) @JsonValue('seasoning')  seasoning,
  @HiveField(6) @JsonValue('grain')      grain,
  @HiveField(7) @JsonValue('beverage')   beverage,
  @HiveField(8) @JsonValue('other')      other;
}

@HiveType(typeId: 2)
enum StorageType {
  @HiveField(0) @JsonValue('refrigerator') refrigerator,
  @HiveField(1) @JsonValue('freezer')      freezer,
  @HiveField(2) @JsonValue('room')         room,
}

@HiveType(typeId: 3)
enum IngredientSource {
  @HiveField(0) @JsonValue('barcode') barcode,
  @HiveField(1) @JsonValue('ocr')     ocr,
  @HiveField(2) @JsonValue('manual')  manual,
}
```

### Postgres ↔ Domain 매핑

Postgres는 snake_case, Dart는 camelCase. `json_serializable`의 `@JsonKey` 또는 `fieldRename`으로 처리:

```dart
@freezed
class Ingredient with _$Ingredient {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Ingredient({...}) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);
}
```

이렇게 하면 Postgres에서 가져온 row를 그대로 `Ingredient.fromJson`에 넘길 수 있다.

### `lib/features/recipe/data/models/recipe.dart`

```dart
@freezed
@HiveType(typeId: 4)
class Recipe with _$Recipe {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Recipe({
    @HiveField(0) required String id,
    @HiveField(1) String? userId,                 // 즐겨찾기 시에만 채움
    @HiveField(2) required String recipeId,        // 'potato_stir_fry'
    @HiveField(3) required String name,
    @HiveField(4) required RecipeCategory category,
    @HiveField(5) required String difficulty,
    @HiveField(6) required int timeMinutes,
    @HiveField(7) required int servings,
    @HiveField(8) required int matchRate,
    @HiveField(9) required List<RecipeIngredient> ingredients,
    @HiveField(10) required List<RecipeStep> steps,
    @HiveField(11) String? tips,
    @HiveField(12) @Default(false) bool isFavorite,
    @HiveField(13) required String createdAt,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) =>
      _$RecipeFromJson(json);
}

@freezed
@HiveType(typeId: 5)
class RecipeIngredient with _$RecipeIngredient {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RecipeIngredient({
    @HiveField(0) required String name,
    @HiveField(1) required String amount,
    @HiveField(2) required bool inFridge,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
}

@freezed
@HiveType(typeId: 6)
class RecipeStep with _$RecipeStep {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory RecipeStep({
    @HiveField(0) required int step,
    @HiveField(1) required String instruction,
    @HiveField(2) int? timerSeconds,
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);
}

@HiveType(typeId: 7)
enum RecipeCategory {
  @HiveField(0) @JsonValue('stir_fry')   stirFry,
  @HiveField(1) @JsonValue('soup')        soup,
  @HiveField(2) @JsonValue('rice')        rice,
  @HiveField(3) @JsonValue('noodle')      noodle,
  @HiveField(4) @JsonValue('grill')       grill,
  @HiveField(5) @JsonValue('salad')       salad,
  @HiveField(6) @JsonValue('side_dish')   sideDish,
  @HiveField(7) @JsonValue('dessert')     dessert,
}
```

### `lib/features/history/data/models/cook_history.dart`

```dart
@freezed
@HiveType(typeId: 8)
class CookHistory with _$CookHistory {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CookHistory({
    @HiveField(0) required String id,
    @HiveField(1) required String userId,
    @HiveField(2) required String recipeId,
    @HiveField(3) required String recipeName,
    @HiveField(4) required List<String> usedIngredients,
    @HiveField(5) required String cookedAt,
  }) = _CookHistory;

  factory CookHistory.fromJson(Map<String, dynamic> json) =>
      _$CookHistoryFromJson(json);
}
```

---

## 3. 초기화 (main.dart)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  // 2) Hive (오프라인 캐시)
  await Hive.initFlutter();
  Hive.registerAdapter(IngredientAdapter());
  Hive.registerAdapter(IngredientCategoryAdapter());
  Hive.registerAdapter(StorageTypeAdapter());
  Hive.registerAdapter(IngredientSourceAdapter());
  Hive.registerAdapter(RecipeAdapter());
  Hive.registerAdapter(RecipeIngredientAdapter());
  Hive.registerAdapter(RecipeStepAdapter());
  Hive.registerAdapter(RecipeCategoryAdapter());
  Hive.registerAdapter(CookHistoryAdapter());

  await Hive.openBox<Ingredient>('ingredients_cache');
  await Hive.openBox<Recipe>('favorites_cache');
  await Hive.openBox<CookHistory>('history_cache');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: FridgeMealApp()));
}
```

---

## 4. Repository 패턴 (Postgres + Hive 캐시)

### `FridgeRepository`

```dart
class FridgeRepository {
  final SupabaseClient _supabase;
  final Box<Ingredient> _cache;
  final Connectivity _connectivity;

  FridgeRepository(this._supabase, this._cache, this._connectivity);

  Future<List<Ingredient>> getAll() async {
    final online = await _isOnline();
    if (online) {
      try {
        final rows = await _supabase
            .from('ingredients')
            .select()
            .order('expiry_date', ascending: true, nullsFirst: false);
        final items = (rows as List)
            .map((r) => Ingredient.fromJson(r as Map<String, dynamic>))
            .toList();
        await _replaceCache(items);
        return items;
      } catch (_) {
        return _readCache();
      }
    }
    return _readCache();
  }

  Future<void> add(Ingredient ingredient) async {
    final inserted = await _supabase
        .from('ingredients')
        .insert(ingredient.toJson()..remove('id'))
        .select()
        .single();
    final saved = Ingredient.fromJson(inserted);
    await _cache.put(saved.id, saved);
  }

  Future<void> update(Ingredient ingredient) async {
    await _supabase
        .from('ingredients')
        .update(ingredient.toJson())
        .eq('id', ingredient.id);
    await _cache.put(ingredient.id, ingredient);
  }

  Future<void> remove(String id) async {
    await _supabase.from('ingredients').delete().eq('id', id);
    await _cache.delete(id);
  }

  Future<bool> _isOnline() async {
    final r = await _connectivity.checkConnectivity();
    return !r.contains(ConnectivityResult.none);
  }

  List<Ingredient> _readCache() {
    final list = _cache.values.toList()
      ..sort((a, b) => _compareExpiry(a.expiryDate, b.expiryDate));
    return list;
  }

  Future<void> _replaceCache(List<Ingredient> items) async {
    await _cache.clear();
    for (final item in items) {
      await _cache.put(item.id, item);
    }
  }

  int _compareExpiry(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
```

---

## 5. Riverpod Providers

```dart
@Riverpod(keepAlive: true)
SupabaseClient supabase(Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
FridgeRepository fridgeRepository(Ref ref) => FridgeRepository(
      ref.watch(supabaseProvider),
      Hive.box<Ingredient>('ingredients_cache'),
      Connectivity(),
    );

@riverpod
class FridgeNotifier extends _$FridgeNotifier {
  @override
  Future<List<Ingredient>> build() async {
    return ref.read(fridgeRepositoryProvider).getAll();
  }

  Future<void> add(Ingredient ingredient) async {
    await ref.read(fridgeRepositoryProvider).add(ingredient);
    ref.invalidateSelf();
  }

  Future<void> update(Ingredient ingredient) async {
    await ref.read(fridgeRepositoryProvider).update(ingredient);
    ref.invalidateSelf();
  }

  Future<void> remove(String id) async {
    await ref.read(fridgeRepositoryProvider).remove(id);
    ref.invalidateSelf();
  }

  List<Ingredient> getExpiringSoon(int days) {
    final list = state.valueOrNull ?? const [];
    return list.where((i) => _getDday(i.expiryDate) <= days).toList();
  }
}

@riverpod
class PotNotifier extends _$PotNotifier {
  @override
  List<Ingredient> build() => const [];

  void add(Ingredient ingredient) {
    if (state.any((i) => i.id == ingredient.id)) return;
    state = [...state, ingredient];
  }

  void remove(String id) =>
      state = state.where((i) => i.id != id).toList();

  void clear() => state = const [];

  bool isInPot(String id) => state.any((i) => i.id == id);
  bool get canCook => state.length >= 2;
}
```

---

## 6. D-day & 이미지 매퍼 유틸 (변경 없음)

```dart
// lib/core/utils/date_utils.dart
int getDday(String? expiryDate) {
  if (expiryDate == null) return 999;
  final expiry = DateTime.parse(expiryDate);
  final today = DateTime.now();
  return expiry.difference(today).inDays;
}

Color getDdayColor(int dday) {
  if (dday <= 3) return const Color(0xFFEF4444);
  if (dday <= 7) return const Color(0xFFF59E0B);
  return const Color(0xFF10B981);
}

String getDdayText(int dday) {
  if (dday < 0) return 'D+${-dday}';
  if (dday == 0) return 'D-Day';
  return 'D-$dday';
}
```

```dart
// lib/core/utils/image_mapper.dart
String getIngredientImage(String name, IngredientCategory category) {
  final assetName = _ingredientMap[name];
  if (assetName != null) return 'assets/images/ingredients/$assetName.png';
  return 'assets/images/categories/${category.name}.png';
}

String getDishImage(String recipeId, RecipeCategory category) {
  return 'assets/images/dishes/$recipeId.png';
  // 런타임에 AssetImage 존재 확인 후 폴백 → category 아이콘
}

const _ingredientMap = {
  '토마토': 'tomato', '감자': 'potato', '양파': 'onion', '당근': 'carrot',
  '달걀': 'egg',     '버섯': 'mushroom', '마늘': 'garlic', '돼지고기': 'pork',
  '우유': 'milk',    '치즈': 'cheese',   '청양고추': 'chili', '간장': 'soy_sauce',
  // ... 50~60개
};
```

---

## 7. 자동완성용 신선식품 마스터

`lib/core/constants/ingredient_db.dart` — 자동완성/검색에 사용. 일러스트 없는 항목은 카테고리 폴백 이미지 사용.

```dart
class IngredientMaster {
  final String name;
  final IngredientCategory category;
  final String? imageAsset;

  const IngredientMaster(this.name, this.category, [this.imageAsset]);
}

const ingredientMasterList = <IngredientMaster>[
  IngredientMaster('양파', IngredientCategory.vegetable, 'onion'),
  IngredientMaster('대파', IngredientCategory.vegetable),
  IngredientMaster('감자', IngredientCategory.vegetable, 'potato'),
  IngredientMaster('당근', IngredientCategory.vegetable, 'carrot'),
  IngredientMaster('마늘', IngredientCategory.vegetable, 'garlic'),
  IngredientMaster('애호박', IngredientCategory.vegetable),
  IngredientMaster('사과', IngredientCategory.fruit),
  IngredientMaster('바나나', IngredientCategory.fruit),
  IngredientMaster('달걀', IngredientCategory.dairy, 'egg'),
  IngredientMaster('우유', IngredientCategory.dairy, 'milk'),
  IngredientMaster('두부', IngredientCategory.vegetable),
  IngredientMaster('돼지고기', IngredientCategory.meat, 'pork'),
  IngredientMaster('소고기', IngredientCategory.meat),
  IngredientMaster('닭가슴살', IngredientCategory.meat),
  IngredientMaster('고등어', IngredientCategory.seafood),
  // ... 100~150개
];
```
