# DEVELOPMENT_PLAN: 개발 일정 (6주, Flutter + Supabase)

## 전체 로드맵

| 주차 | 테마 | 핵심 산출물 |
|---|---|---|
| **Week 0** (Day 0~2) | 셋업 + 에셋 | Flutter 초기화, 디자인 토큰, 카테고리 일러스트 |
| **Week 1** (Day 3~9) | **Supabase 백엔드 ⭐** | Postgres 스키마, RLS, Auth, Edge Function 2개 |
| **Week 2** (Day 10~16) | 내 냉장고 + 입력 | 홈 화면, 바코드/자동완성/직접 입력 3종 |
| **Week 3** (Day 17~23) | 드래그앤드롭 ⭐ | 핵심 인터랙션, 항아리 애니메이션 |
| **Week 4** (Day 24~30) | AI 레시피 | Edge Function 연동, 로딩, 레시피 카드/상세 |
| **Week 5** (Day 31~37) | 보조 기능 + 폴리싱 | 알림, 즐겨찾기, 히스토리, 오프라인, 버그 |
| **Week 6** (Day 38~42) | 배포 + 포폴 | APK 빌드, 포폴 PDF, README, 운영 문서 |

---

## Week 0: 프로젝트 셋업 (Day 0~2)

### Day 0: 프로젝트 초기화
- [x] `flutter create . --project-name fridge_meal --org com.fridgemeal --platforms android`
- [x] pubspec.yaml 의존성 추가 (supabase_flutter, riverpod, hive_ce, freezed, mobile_scanner, go_router, lottie, connectivity_plus 등)
- [x] `flutter pub get`
- [x] `analysis_options.yaml` strict 린트 설정 (`strict-casts`, `strict-inference`, `prefer_single_quotes`, `unawaited_futures` 등)
- [x] `.gitignore` 보강 (`.env`, `*.g.dart`, `*.freezed.dart`, `supabase/.env`)
- [x] `docs/` 폴더 유지 (기획 문서)
- [x] `.cursorrules` 프로젝트 루트에 배치
- [x] 폴더 구조 생성 (`lib/core`, `lib/features/{auth,fridge,scan,cook,recipe,history,settings,onboarding}`, `lib/shared`, `assets/`, `supabase/functions`, `supabase/migrations`)
- [x] `lib/main.dart` + `lib/app.dart` + `lib/core/network/env.dart` 진입점 보일러플레이트
- [x] 헬스체크: `flutter analyze` (0 issues) + `flutter test` (1/1 passed)

### Day 1: 디자인 시스템 + 기본 UI
- [ ] `lib/core/constants/` — 컬러, 타이포, 스페이싱 토큰
- [ ] `lib/core/theme/app_theme.dart` — ThemeData
- [ ] `lib/shared/widgets/` — AppButton, AppChip, AppCard, AppBadge
- [ ] GoRouter 라우트 정의 (Splash → Login → Onboarding → Main)
- [ ] 바텀 네비게이션 4탭 (`MainShell`)
- [ ] Pretendard 폰트 등록

### Day 2: 에셋 준비 (MVP 50개)
- [ ] **카테고리 일러스트 8개** (vegetable, fruit, meat, seafood, dairy, seasoning, grain, beverage)
- [ ] **재료 일러스트 30개** (자취생 빈도 Top 30)
- [ ] **요리 일러스트 50개** (인기 한식 50개) — Week 4와 병렬 진행 가능
- [ ] 배경 제거 (remove.bg) + 파일명 통일
- [ ] `assets/images/` 배치 + pubspec.yaml 등록
- [ ] 항아리 마스코트 + 온보딩 일러스트 3장

---

## Week 1: Supabase 백엔드 ⭐ (Day 3~9)

### Day 3: Supabase 프로젝트 셋업
- [ ] Supabase 프로젝트 생성 (https://supabase.com/dashboard)
- [ ] Supabase CLI 설치 + 로그인 (`supabase login`)
- [ ] 로컬 프로젝트 연결 (`supabase init`, `supabase link`)
- [ ] `--dart-define`으로 SUPABASE_URL, SUPABASE_ANON_KEY 주입 설정
- [ ] `lib/core/network/supabase_client.dart` — 싱글턴 초기화
- [ ] `main.dart`에서 `Supabase.initialize` 호출

### Day 4: Postgres 스키마 + RLS
- [ ] `supabase/migrations/0001_init.sql` — 7개 테이블 생성
  - ingredients, recipes, cook_history, recipe_cache, barcode_cache, api_usage, (auth.users는 자동)
- [ ] `supabase/migrations/0002_rls.sql` — 3개 사용자 테이블 RLS
- [ ] `supabase/migrations/0003_indexes.sql` — 인덱스 추가
- [ ] `supabase db push` 실행 → 원격 DB에 반영
- [ ] Supabase Studio에서 테이블/정책 확인

### Day 5: Auth (F-00)
- [ ] Supabase Dashboard → Authentication → Providers 활성화 (Email + Google)
- [ ] (선택) Kakao OAuth는 Custom OIDC 또는 v1.1로 미룸
- [ ] `auth_repository.dart` — signIn / signUp / signOut / sessionStream
- [ ] `auth_provider.dart` — Riverpod
- [ ] `splash_screen.dart` — 세션 체크 후 `/login` or `/fridge` 분기
- [ ] `login_screen.dart` — 이메일 + Google 버튼
- [ ] GoRouter `redirect`로 미인증 시 `/login` 강제

### Day 6: Edge Function `lookup-barcode`
- [ ] `supabase secrets set FOOD_SAFETY_API_KEY=...`
- [ ] `supabase/functions/lookup-barcode/index.ts` 작성
- [ ] `supabase/functions/_shared/cors.ts` 작성
- [ ] 로컬 테스트: `supabase functions serve lookup-barcode`
- [ ] 배포: `supabase functions deploy lookup-barcode`
- [ ] Postman/curl로 테스트

### Day 7~8: Edge Function `generate-recipe`
- [ ] `supabase secrets set OPENAI_API_KEY=...`
- [ ] `supabase/functions/_shared/rate_limit.ts` 작성
- [ ] `supabase/functions/_shared/recipes_top.ts` (50개 요리 카탈로그)
- [ ] `supabase/functions/generate-recipe/index.ts` — 캐시 + Rate Limit + OpenAI
- [ ] 시스템 프롬프트 튜닝 (3~5회 반복)
- [ ] 동일 재료 셋 2회 호출 → 두 번째는 cache 응답 확인
- [ ] Rate Limit 초과 시 429 확인
- [ ] 배포: `supabase functions deploy generate-recipe`

### Day 9: Flutter 측 서비스 + 통합 테스트
- [ ] `BarcodeProxyService` — Edge Function 호출
- [ ] `RecipeProxyService` — Edge Function 호출
- [ ] 더미 화면에서 두 함수 호출 + 응답 확인
- [ ] 에러 케이스 (401, 429, 5xx, 오프라인) 시나리오 검증

---

## Week 2: 내 냉장고 + 재료 입력 (Day 10~16)

### Day 10~11: 데이터 레이어
- [ ] Freezed 모델 (`Ingredient`, `IngredientCategory`, `StorageType`, `IngredientSource`)
- [ ] `dart run build_runner build --delete-conflicting-outputs`
- [ ] hive_ce Adapter 등록 (main.dart)
- [ ] `FridgeRepository` — Postgres + Hive 캐시
- [ ] `FridgeNotifier` (Riverpod)
- [ ] `date_utils.dart`, `image_mapper.dart`

### Day 12~13: 내 냉장고 화면
- [ ] `FridgeScreen` — 메인 화면
- [ ] `IngredientCard` + 2열 그리드
- [ ] `CategoryFilter` 칩 (가로 스크롤)
- [ ] `ExpiryBanner` 임박 경고
- [ ] 카드 탭 → 수정 바텀시트
- [ ] `Dismissible` 스와이프 삭제
- [ ] 빈 상태 화면

### Day 14: 바코드 스캔
- [ ] `ScanScreen` — `MobileScanner` + 탭 3개
- [ ] 카메라 권한
- [ ] 인식 성공 → `lookup-barcode` 호출 → 슬라이드업 미리보기
- [ ] 인식 실패 → 자동완성/직접 입력 안내

### Day 15: 자동완성 입력
- [ ] `ingredient_db.dart` — 신선식품 마스터 (100~150개)
- [ ] `Autocomplete` 위젯
- [ ] 칩 선택 → 폼 자동 채움 + 일러스트 미리보기

### Day 16: 재료 확인 + 등록
- [ ] `ConfirmScreen` — 자동 채움 + 사용자 입력
- [ ] 유통기한 DatePicker
- [ ] 수량 +/- 카운터
- [ ] 보관 위치 `ChoiceChip`
- [ ] [냉장고에 추가] → Postgres INSERT + 캐시 갱신 → `/fridge`

---

## Week 3: 드래그앤드롭 ⭐ (Day 17~23)

### Day 17~18: 드래그 기본 구현
- [ ] `DraggableIngredient` — `Draggable<Ingredient>` 래핑
- [ ] feedback 위젯 (elevation + scale)
- [ ] childWhenDragging (반투명 + 체크)
- [ ] 드래그 시작/종료 `HapticFeedback`

### Day 19~20: 드롭 존 (항아리)
- [ ] `PotDropZone` — `DragTarget<Ingredient>`
- [ ] `onWillAcceptWithDetails` → 항아리 하이라이트
- [ ] `onAcceptWithDetails` → 재료 추가 + 햅틱
- [ ] `PotWidget` — 항아리 + 내부 재료 아이콘
- [ ] 카운터 뱃지

### Day 21~22: 조합 화면 통합
- [ ] `CookScreen` — 상단 재료 + 하단 항아리
- [ ] `PotNotifier` (Riverpod)
- [ ] 카테고리 필터 연동
- [ ] 이미 넣은 재료 비주얼 구분
- [ ] 항아리 탭 → 바텀시트 (개별 제거)
- [ ] [요리 시작!] 버튼 (2개 이상 활성)

### Day 23: 애니메이션 폴리싱
- [ ] 항아리 글로우 (`AnimatedContainer` + `BoxShadow`)
- [ ] 항아리 흔들림 (`RotationTransition` ±3°)
- [ ] 드롭 성공 파티클 (Lottie 또는 커스텀)
- [ ] 60fps 확인 (DevTools Performance, `RepaintBoundary`)

---

## Week 4: AI 레시피 (Day 24~30)

### Day 24~25: 레시피 화면 구성
- [ ] Freezed 모델 (`Recipe`, `RecipeIngredient`, `RecipeStep`, `RecipeCategory`)
- [ ] `RecipeProxyService` 호출 → `RecipeNotifier`
- [ ] 에러 처리 (RateLimit, 네트워크, 파싱)
- [ ] 응답 캐시 (Hive `favorites_cache` 활용)

### Day 26: AI 로딩 화면
- [ ] `CookingLoaderScreen` — 항아리 Lottie + 로딩 문구
- [ ] `AnimatedSwitcher` 문구 롤링 (3초 간격)
- [ ] `LinearProgressIndicator` (오렌지)
- [ ] 캐시 적중 시 단축 (300ms 노출)

### Day 27: 레시피 결과
- [ ] `ResultsScreen` — 3개 카드 리스트
- [ ] `RecipeCard` — 일러스트 + 정보 + 매칭률
- [ ] 이미지 매핑 (`getDishImage` + 폴백)
- [ ] [다시 추천받기] / [재료 변경]

### Day 28~29: 레시피 상세
- [ ] `RecipeDetailScreen` — `CustomScrollView` + `SliverAppBar`
- [ ] 히어로 이미지 + 즐겨찾기 ❤️ → Postgres `recipes` 저장
- [ ] 재료 체크 (✅ 있음 / ⚠️ 없음)
- [ ] 단계별 가이드 + `TimerButton`
- [ ] 타이머 (여러 개 동시, 백그라운드 알림)
- [ ] `flutter_local_notifications` 연동

### Day 30: 통합 테스트
- [ ] Rate Limit 초과 시 다이얼로그 + 즐겨찾기 안내
- [ ] 오프라인 시 캐시된 즐겨찾기 표시
- [ ] 전체 [스캔→항아리→레시피→상세→타이머] 플로우 E2E

---

## Week 5: 보조 기능 + 폴리싱 (Day 31~37)

### Day 31~32: 온보딩 + 알림
- [ ] `OnboardingScreen` — `PageView` 3단계
- [ ] Hive `settings` 박스 플래그
- [ ] `NotificationService` — 유통기한 알림 스케줄링
- [ ] D-3, D-1, D-Day 알림
- [ ] `workmanager` 백그라운드 체크

### Day 33~34: 히스토리 + 즐겨찾기
- [ ] `HistoryScreen` — 탭 전환 (히스토리/즐겨찾기)
- [ ] `CookHistory` Postgres + Hive 캐시
- [ ] 날짜별 그룹핑
- [ ] 즐겨찾기 오프라인 조회

### Day 35: 설정
- [ ] `SettingsScreen` — 알림, 인분, 식이제한, 데이터 초기화
- [ ] 로그아웃 (Supabase signOut + Hive clear)
- [ ] 앱 정보 (버전, 라이선스)

### Day 36: 오프라인 모드 강화
- [ ] `connectivity_plus` 전역 리스너
- [ ] 오프라인 배너
- [ ] Repository 폴백 검증

### Day 37: 버그 수정 + 성능
- [ ] 전체 플로우 E2E 수동 테스트
- [ ] 대량 재료 (50+) 성능 (`RepaintBoundary`)
- [ ] DevTools Memory 검증
- [ ] Shimmer 로딩 적용

---

## Week 6: 배포 + 포폴 (Day 38~42)

### Day 38~39: APK 빌드 + 베타 배포
- [ ] `--dart-define` 빌드 명령어 정리
- [ ] `flutter build apk --release --target-platform android-arm64 --dart-define=...`
- [ ] 실기기 테스트
- [ ] 가족/지인 베타 배포 + 피드백
- [ ] 크리티컬 버그 수정

### Day 40: 운영 문서
- [ ] `docs/OPERATIONS.md` — Supabase 운영 가이드
  - secret 갱신 방법
  - migration 추가 방법
  - 로그/모니터링
  - 비용 추적 쿼리

### Day 41: 포폴 PDF
- [ ] 포폴 PDF 작성:
  - 기획 배경 (스마트 냉장고 → 모바일 일반화)
  - 경쟁 분석
  - 기술 도전 (Supabase Edge Function, RLS, 캐싱, Rate Limit)
  - **확장성 고려 (100만 유저 가정)**
  - 스크린샷 + 목업
- [ ] GPT 목업 이미지 (3대 폰)

### Day 42: GitHub + 배포
- [ ] README.md 최종 (스크린샷 포함)
- [ ] GitHub Releases에 APK 업로드
- [ ] Supabase 시크릿 관련 정보는 `.env.example` 형태로만 노출
- [ ] 커밋 히스토리 정리

---

## 리스크 대응

| 리스크 | 대응 |
|---|---|
| 식약처 API 승인 지연 | Mock 데이터로 개발, 승인 후 시크릿 교체만 |
| Supabase Auth Kakao 연동 복잡 | MVP는 Email + Google만, Kakao는 v1.1 |
| Freezed/hive_ce 빌드 충돌 | `dart run build_runner build --delete-conflicting-outputs` |
| Edge Function 콜드 스타트 | Lottie 로딩 화면이 자연스럽게 마스킹 |
| OpenAI Rate Limit (계정 단위) | 캐시 적중률 + 일일 유저 한도로 보호 |
| 드래그앤드롭 성능 | `RepaintBoundary` 래핑, 재료 수 50개 제한 |
| GPT 파싱 실패 | JSON mode + 재시도 (temperature 0.3) → 폴백 |
| 50개 일러스트 품질 편차 | 레퍼런스 이미지 첨부 + 스타일 프롬프트 고정 |

---

## 일정 요약

- **총 6주 (42일)** — 기존 5주 + Supabase 셋업 1주 추가
- 일러스트 200개 → **MVP 50개** (요리 50 + 재료 30 + 카테고리 8)
- 일러스트 추가 200개는 v1.1 점진 확장
- Auth는 MVP 필수 (포폴 어필 핵심)
