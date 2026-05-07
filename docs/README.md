# 🍳 냉장고 한 끼

> **냉장고 속 재료가 한 끼가 되다**

스마트 냉장고의 핵심 기능을 스마트폰으로 구현한 AI 레시피 앱.
바코드 스캔/자동완성으로 재료를 등록하고, 드래그앤드롭으로 항아리에 넣으면,
AI가 맞춤 레시피를 만들어줍니다.

## 📱 핵심 기능

- **하이브리드 입력** — 바코드 스캔 + 자동완성(신선식품) + 직접 입력
- **드래그앤드롭 조합** — 재료를 항아리에 넣는 직관적인 인터랙션
- **AI 레시피 생성** — Edge Function 프록시 + 캐싱으로 안전·저비용
- **유통기한 관리** — 임박 재료 우선 알림 + 활용 레시피 추천
- **요리 타이머** — 단계별 자동 타이머
- **오프라인 모드** — Hive 캐시로 네트워크 없이도 즐겨찾기 조회

## 🛠 기술 스택

### Client (Flutter)
- **Framework:** Flutter 3.x · Dart 3.x
- **State:** Riverpod 2.x (코드 생성)
- **Navigation:** GoRouter
- **Local Cache:** hive_ce (Freezed 호환)
- **Camera:** mobile_scanner
- **Animation:** Flutter 내장 + Lottie
- **Model:** Freezed + json_serializable

### Backend (Supabase)
- **Auth:** Supabase Auth (Email + Google OAuth)
- **DB:** Postgres + RLS (멀티테넌트 안전성)
- **AI/외부 API 프록시:** Supabase Edge Functions (Deno)
- **Storage:** (선택) 사용자 업로드 이미지
- **AI Model:** OpenAI GPT-4o-mini (서버에서만 호출)
- **외부 API:** 식품안전나라 바코드 (서버에서만 호출)

### 보안 / 확장성
- API 키는 Edge Function 시크릿에만 존재 → 클라이언트 노출 0
- 전역 레시피 캐시 + 영구 바코드 캐시 → GPT 비용 70% 절감 가능
- 유저별 일일 호출 한도 → DDoS / 비용 폭주 방지
- 모든 사용자 데이터 RLS 적용

## 🎨 디자인

따뜻한 크림 배경(#FFF8F0) + 오렌지 액센트(#FF6B35) + 민트 포인트(#2EC4B6).
귀여운 항아리 마스코트 캐릭터가 앱 전반에 등장합니다.

## 📦 설치 및 실행

### 1) Flutter 프로젝트
```bash
git clone https://github.com/yourname/fridge-meal.git
cd fridge-meal
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2) Supabase 셋업
```bash
# Supabase CLI 설치 후
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>
supabase db push
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set FOOD_SAFETY_API_KEY=...
supabase functions deploy generate-recipe
supabase functions deploy lookup-barcode
```

### 3) 앱 실행 / 빌드
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGc...

# 릴리즈 APK
flutter build apk --release --target-platform android-arm64 \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

> **`.env` 파일은 사용하지 않습니다.** Supabase URL/anon key는 빌드 플래그로 주입하고, 외부 API 키는 Supabase Edge Function 시크릿에만 저장합니다.

## 🔑 환경 변수 / 시크릿

| 항목 | 위치 | 노출 가능 |
|---|---|---|
| `SUPABASE_URL` | `--dart-define` | ✅ |
| `SUPABASE_ANON_KEY` | `--dart-define` | ✅ (RLS가 보호) |
| `OPENAI_API_KEY` | Supabase Edge Function 시크릿 | ❌ |
| `FOOD_SAFETY_API_KEY` | Supabase Edge Function 시크릿 | ❌ |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Function 런타임 (자동 주입) | ❌ |

## 📄 문서

- [PRD](PRD.md) — 제품 요구사항 + 확장성 고려
- [Features](FEATURES.md) — 기능 명세 (F-00 ~ F-13)
- [Tech Stack](TECH_STACK.md) — Flutter + Supabase 아키텍처
- [Data Model](DATA_MODEL.md) — Postgres 스키마 + Freezed 모델
- [API Integration](API_INTEGRATION.md) — Edge Function 프록시 가이드
- [UI Flow](UI_FLOW.md) — 화면 플로우
- [Development Plan](DEVELOPMENT_PLAN.md) — 6주 개발 일정
