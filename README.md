# 🍳 냉장고 한 끼 (Fridge Meal)

> **냉장고 속 재료가 한 끼가 되다**

스마트 냉장고의 핵심 기능을 스마트폰으로 구현한 AI 레시피 앱.
바코드 스캔/자동완성으로 재료를 등록하고, 항아리에 담은 재료로 AI가 맞춤 레시피를 만들어줍니다.

> 📚 **상세 기획서는 [`docs/`](docs/) 폴더를 참고하세요.**

## 빠른 시작

### 1) 의존성 설치

```bash
flutter pub get
```

### 2) Supabase 프로젝트 셋업

```bash
# Supabase CLI 설치 후
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>
supabase db push                                          # docs/DATA_MODEL.md 참고
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set FOOD_SAFETY_API_KEY=...
supabase functions deploy generate-recipe
supabase functions deploy lookup-barcode
```

### 3) 앱 실행

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
```

### 4) 코드 생성 (Freezed / Riverpod / Hive / json_serializable)

```bash
dart run build_runner build --delete-conflicting-outputs

# 개발 중 watch 모드
dart run build_runner watch --delete-conflicting-outputs
```

### 5) 릴리즈 APK

```bash
flutter build apk --release --target-platform android-arm64 \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## 🔑 환경 변수 / 시크릿

`.env` 파일을 사용하지 않습니다. **API 키는 절대 클라이언트에 두지 마세요.**

| 항목 | 위치 | 노출 가능 |
|---|---|---|
| `SUPABASE_URL` | `--dart-define` | ✅ |
| `SUPABASE_ANON_KEY` | `--dart-define` | ✅ (RLS가 보호) |
| `OPENAI_API_KEY` | Supabase Edge Function 시크릿 | ❌ |
| `FOOD_SAFETY_API_KEY` | Supabase Edge Function 시크릿 | ❌ |

## 📁 프로젝트 구조 (Day 0 시점)

```
fridge_meal/
├── lib/
│   ├── main.dart                       앱 진입점 (Supabase + Hive 초기화)
│   ├── app.dart                        MaterialApp + 임시 화면
│   ├── core/                           공통 인프라
│   │   ├── constants/  router/  theme/  network/  utils/
│   ├── features/                       기능별 (auth, fridge, scan, cook, recipe, history, settings, onboarding)
│   │   └── {feature}/
│   │       ├── data/{models, repositories, services}
│   │       └── presentation/{screens, widgets, providers}
│   └── shared/widgets/
├── assets/
│   ├── images/{ingredients, dishes, categories, pot, onboarding}
│   ├── animations/
│   └── fonts/
├── supabase/
│   ├── functions/{generate-recipe, lookup-barcode, _shared}
│   └── migrations/
├── docs/                               기획 문서
│   └── design/                         디자인 시안 (GPT-Image)
├── test/
├── .cursorrules
├── pubspec.yaml
└── analysis_options.yaml
```

## 📄 문서

- [PRD](docs/PRD.md) — 제품 요구사항 + 확장성 고려
- [Features](docs/FEATURES.md) — 기능 명세 (F-00 ~ F-13)
- [Tech Stack](docs/TECH_STACK.md) — Flutter + Supabase 아키텍처
- [Data Model](docs/DATA_MODEL.md) — Postgres 스키마 + Freezed 모델
- [API Integration](docs/API_INTEGRATION.md) — Edge Function 프록시 가이드
- [UI Flow](docs/UI_FLOW.md) — 화면 플로우
- [Development Plan](docs/DEVELOPMENT_PLAN.md) — 6주 개발 일정
- [Design](docs/design/README.md) — 디자인 시안 인덱스
