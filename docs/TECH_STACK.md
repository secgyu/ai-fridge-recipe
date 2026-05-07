# TECH_STACK: 기술 스택 (Flutter + Supabase)

## 아키텍처 한눈에 보기

```
┌─────────────────────────────────────────┐
│              Flutter App                │
│   UI · Riverpod · Hive(오프라인 캐시)   │
└──────────────┬──────────────────────────┘
               │ supabase_flutter SDK
               ▼
┌─────────────────────────────────────────┐
│              Supabase                   │
│  ├─ Auth        (소셜/이메일 로그인)    │
│  ├─ Postgres    (재료/레시피 원본 DB)   │
│  ├─ Edge Func.  (AI/외부 API 프록시)    │
│  ├─ Storage     (사용자 업로드 이미지)  │
│  └─ RLS         (유저별 데이터 격리)    │
└──────────────┬──────────────────────────┘
               │ (서버 → 서버, 키는 여기에만)
               ▼
┌─────────────────────────────────────────┐
│         외부 API (서버에서만 호출)       │
│  ├─ OpenAI GPT-4o-mini  (레시피 생성)   │
│  └─ 식품안전나라 API    (바코드 조회)   │
└─────────────────────────────────────────┘
```

**핵심 원칙**
1. **외부 API 키는 클라이언트에 절대 두지 않는다.** 모두 Edge Function 경유.
2. **Hive는 source of truth가 아니라 오프라인 캐시다.** 원본은 Supabase Postgres.
3. **모든 테이블에 RLS** 적용. 유저는 자기 데이터만 본다.

---

## 기술 스택 상세

### Core (Flutter)
| 기술 | 버전 | 용도 |
|---|---|---|
| Flutter | 3.x | 모바일 프레임워크 |
| Dart | 3.x | 프로그래밍 언어 |
| GoRouter | ^14.0 | 선언적 라우팅 |

### Backend (Supabase)
| 기술 | 용도 |
|---|---|
| Supabase Auth | 소셜 로그인(Google/Kakao) + 이메일 |
| Supabase Postgres | 원본 DB (ingredients, recipes, favorites, history, recipe_cache, api_usage) |
| Supabase Edge Functions (Deno/TS) | OpenAI/식약처 API 프록시 + Rate Limit + 캐싱 |
| Supabase Storage | (선택) 사용자 업로드 이미지 |
| Postgres RLS | Row Level Security — 유저별 데이터 격리 |

### State & Storage (Client)
| 기술 | 용도 |
|---|---|
| flutter_riverpod + riverpod_annotation | 상태 관리 (코드 생성) |
| supabase_flutter | Supabase 클라이언트 SDK |
| hive_ce + hive_ce_generator | 오프라인 캐시 (Freezed 호환 포크) |
| flutter_secure_storage | Supabase 세션 토큰 안전 저장 |
| connectivity_plus | 네트워크 상태 감지 (오프라인 폴백) |

> **Freezed + Hive 충돌 회피**: 기존 `hive_generator`는 Freezed factory 파라미터의 `@HiveField`를 인식하지 못해 어댑터 생성에 실패한다. 이를 위해 **`hive_ce`** (Freezed 호환 포크)를 사용한다. 모든 어노테이션과 API는 hive와 호환된다.

### Model & Code Generation
| 기술 | 용도 |
|---|---|
| Freezed | 불변 데이터 모델 + sealed class |
| json_serializable | JSON 직렬화/역직렬화 (Postgres ↔ 모델, GPT ↔ 모델) |
| build_runner | 코드 생성 실행 (riverpod + freezed + json + hive_ce) |

### Camera & Scanner
| 기술 | 용도 |
|---|---|
| mobile_scanner | 바코드/QR 인식 |
| google_mlkit_text_recognition | 한글 OCR (v1.1) |
| permission_handler | 카메라 권한 관리 |

### Network
| 기술 | 용도 |
|---|---|
| supabase_flutter | Edge Function 호출, Postgres 쿼리, Auth |
| dio | (예외) Edge Function이 다운됐을 때의 직접 호출 fallback — 평소에는 미사용 |

> **`flutter_dotenv`는 사용하지 않는다.** API 키를 클라이언트에 두지 않으므로 .env가 불필요. Supabase URL과 anon key만 `--dart-define`으로 빌드 시 주입한다 (anon key는 RLS로 보호되므로 노출 OK).

### Animation & Interaction
| 기술 | 용도 |
|---|---|
| Flutter 내장 Draggable/DragTarget | 드래그앤드롭 핵심 |
| Flutter 내장 AnimationController | 커스텀 애니메이션 |
| lottie | 항아리 끓는 애니메이션 |

### Notification
| 기술 | 용도 |
|---|---|
| flutter_local_notifications | 유통기한 알림, 타이머 알림 |
| workmanager | 백그라운드 유통기한 체크 (Android) |

### UI
| 기술 | 용도 |
|---|---|
| cached_network_image | Supabase Storage 이미지 캐싱 |
| fl_chart | 통계 차트 (v1.1) |
| shimmer | 로딩 스켈레톤 |
| google_fonts | Pretendard 폰트 |

---

## 보안 모델

### API 키 노출 방지

| 키 종류 | 어디에 저장 | 클라이언트 노출 | 비고 |
|---|---|---|---|
| Supabase URL | `--dart-define` | OK (공개) | |
| Supabase anon key | `--dart-define` | OK (공개) | RLS가 보호 |
| Supabase service_role key | Edge Function 환경변수만 | ❌ 절대 X | 슈퍼유저 권한 |
| OpenAI API Key | Edge Function 시크릿 | ❌ 절대 X | `Deno.env.get` |
| 식약처 API Key | Edge Function 시크릿 | ❌ 절대 X | `Deno.env.get` |

### 빌드 명령어

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

### Edge Function 시크릿 등록

```bash
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set FOOD_SAFETY_API_KEY=...
```

### RLS 기본 정책 예시

```sql
-- ingredients 테이블: 본인 것만 read/write
ALTER TABLE ingredients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own" ON ingredients
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_insert_own" ON ingredients
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "users_update_own" ON ingredients
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "users_delete_own" ON ingredients
  FOR DELETE USING (auth.uid() = user_id);
```

---

## 프로젝트 구조

```
fridge_meal/
├── lib/
│   ├── main.dart                       # 앱 진입점 (Supabase + Hive 초기화)
│   ├── app.dart                        # MaterialApp + GoRouter + 테마
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_spacing.dart
│   │   │   ├── categories.dart
│   │   │   ├── ingredient_db.dart      # 자동완성용 신선식품 마스터
│   │   │   └── recipes_top.dart        # 인기 요리 50개 (MVP)
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   ├── network/
│   │   │   ├── supabase_client.dart    # Supabase 싱글턴
│   │   │   └── connectivity.dart       # 온/오프라인 감지
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── image_mapper.dart
│   │       └── uuid.dart
│   │
│   ├── features/
│   │   ├── auth/                       # 로그인/회원가입
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository.dart
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   └── splash_screen.dart  # 세션 체크 후 분기
│   │   │       └── providers/
│   │   │           └── auth_provider.dart
│   │   │
│   │   ├── fridge/                     # 내 냉장고
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── ingredient.dart      # 도메인 모델 (Freezed)
│   │   │   │   │   └── ingredient_dto.dart  # Postgres ↔ JSON
│   │   │   │   └── repositories/
│   │   │   │       └── fridge_repository.dart  # Postgres + Hive 캐시
│   │   │   └── presentation/...
│   │   │
│   │   ├── scan/                       # 바코드 스캔 + 자동완성 입력
│   │   │   ├── data/
│   │   │   │   └── services/
│   │   │   │       ├── barcode_proxy_service.dart  # Edge Function 호출
│   │   │   │       └── ingredient_search_service.dart  # 자동완성
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── scan_screen.dart
│   │   │           └── confirm_screen.dart
│   │   │
│   │   ├── cook/                       # 드래그앤드롭 (변경 없음)
│   │   │   └── presentation/...
│   │   │
│   │   ├── recipe/                     # AI 레시피
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   └── recipe.dart
│   │   │   │   ├── services/
│   │   │   │   │   └── recipe_proxy_service.dart  # Edge Function 호출
│   │   │   │   └── repositories/
│   │   │   │       └── recipe_repository.dart
│   │   │   └── presentation/...
│   │   │
│   │   ├── history/
│   │   ├── settings/
│   │   └── onboarding/
│   │
│   └── shared/widgets/
│
├── supabase/                           # Supabase 프로젝트 (Edge Functions + 마이그레이션)
│   ├── functions/
│   │   ├── generate-recipe/            # OpenAI 프록시
│   │   │   └── index.ts
│   │   ├── lookup-barcode/             # 식약처 API 프록시
│   │   │   └── index.ts
│   │   └── _shared/
│   │       ├── cors.ts
│   │       ├── rate_limit.ts
│   │       └── cache.ts
│   ├── migrations/
│   │   ├── 0001_init.sql               # 테이블 생성
│   │   ├── 0002_rls.sql                # RLS 정책
│   │   └── 0003_indexes.sql
│   └── config.toml
│
├── assets/
│   ├── images/
│   │   ├── ingredients/                # 재료 일러스트 (50~60개)
│   │   ├── dishes/                     # 요리 일러스트 (MVP 50개)
│   │   ├── categories/                 # 카테고리 폴백 아이콘 (8개)
│   │   ├── pot/
│   │   └── onboarding/
│   ├── animations/
│   │   └── pot_bubbling.json
│   └── fonts/
│       └── Pretendard-Variable.ttf
│
├── .cursorrules
├── pubspec.yaml
├── analysis_options.yaml
└── docs/
```

---

## pubspec.yaml 핵심 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.8.0

  # State
  flutter_riverpod: ^2.6.0
  riverpod_annotation: ^2.6.0

  # Storage (오프라인 캐시 + 세션)
  hive_ce: ^2.10.0
  hive_ce_flutter: ^2.2.0
  flutter_secure_storage: ^9.2.0

  # Model
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0

  # Navigation
  go_router: ^14.0.0

  # Camera
  mobile_scanner: ^6.0.0
  permission_handler: ^11.3.0

  # Network
  connectivity_plus: ^6.0.0

  # Animation
  lottie: ^3.1.0

  # Notification
  flutter_local_notifications: ^18.0.0
  workmanager: ^0.5.0

  # UI
  cached_network_image: ^3.4.0
  shimmer: ^3.0.0
  google_fonts: ^6.2.0

  # Utility
  uuid: ^4.5.0
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  hive_ce_generator: ^1.7.0
  flutter_lints: ^5.0.0
```

---

## 아키텍처: Feature-First Clean + Repository Pattern

### 데이터 흐름 (온라인)

```
사용자 인터랙션
    ↓
Screen (ConsumerWidget)
    ↓
Provider (Riverpod — 상태 + 비즈니스 로직)
    ↓
Repository (도메인 인터페이스)
    ↓
┌──────────────┬───────────────────┐
↓              ↓                   ↓
Hive (캐시)   Supabase Postgres    Edge Function (AI)
  로컬 우선     원본 데이터          OpenAI 프록시
    ↓              ↓                   ↓
    └──────────────┴───────────────────┘
                  ↓
           UI 자동 리렌더링
```

### Repository 패턴: 온라인 우선 + 오프라인 폴백

```dart
class FridgeRepository {
  final SupabaseClient _supabase;
  final Box<IngredientHiveDto> _cacheBox;
  final Connectivity _connectivity;

  Future<List<Ingredient>> getAll() async {
    if (await _isOnline()) {
      final rows = await _supabase
          .from('ingredients')
          .select()
          .order('expiry_date', ascending: true);
      final items = rows.map(Ingredient.fromJson).toList();
      _writeCache(items);            // 캐시 갱신
      return items;
    }
    return _readCache();              // 오프라인: 캐시 반환
  }

  Future<void> add(Ingredient ingredient) async {
    await _supabase.from('ingredients').insert(ingredient.toJson());
    _writeCacheItem(ingredient);
  }
}
```

### Edge Function 호출 (Flutter 측)

```dart
final response = await Supabase.instance.client.functions.invoke(
  'generate-recipe',
  body: {
    'ingredients': ['감자', '양파', '돼지고기'],
    'servings': 2,
    'max_time_minutes': 30,
  },
);

if (response.status != 200) throw RecipeGenerationException(response.data);
final recipes = (response.data['recipes'] as List)
    .map((j) => Recipe.fromJson(j))
    .toList();
```

> Auth 헤더는 `supabase_flutter`가 자동으로 붙여준다. 별도 처리 불필요.

### Riverpod 사용 패턴 (코드 생성)

```dart
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
}
```

### 코드 생성 명령어

```bash
dart run build_runner build --delete-conflicting-outputs

# 개발 중 watch
dart run build_runner watch --delete-conflicting-outputs
```
