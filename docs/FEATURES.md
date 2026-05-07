# FEATURES: 기능 명세서

## 기능 ID 체계
- `F-00`: 인증 (MVP 필수, 모든 기능의 전제)
- `F-01` ~ `F-05`: 핵심 기능 (MVP 필수)
- `F-06` ~ `F-09`: 보조 기능 (MVP 포함)
- `F-10` ~ `F-13`: 확장 기능 (v1.1+)

---

## F-00: 인증 (Supabase Auth) ⭐

### 설명
앱 첫 진입 시 로그인. 이메일 + Google/Kakao 소셜 로그인 지원. 이후 모든 데이터는 사용자 계정에 귀속된다.

### 상세 플로우
1. 첫 실행 → Splash → 세션 체크
2. 세션 있음 → `/fridge`로 이동
3. 세션 없음 → `/login` 화면
4. 로그인 옵션:
   - 이메일 + 비밀번호
   - Google OAuth (`supabase.auth.signInWithOAuth(Provider.google)`)
   - Kakao OAuth
5. 첫 로그인 시 → 온보딩 화면으로 이동
6. 재로그인 시 → 홈으로 직행

### 기술 요구사항
- `supabase_flutter` Auth API
- `flutter_secure_storage` (자동 세션 저장은 SDK가 처리)
- `auth.uid()` 기반 RLS로 데이터 격리
- 로그아웃 시 Hive 캐시도 클리어

### 우선순위: P0 (MVP 필수)

---

---

## F-01: 재료 등록 (하이브리드 입력) ⭐

### 설명
세 가지 방식으로 재료를 등록한다. 가공식품은 바코드, 신선식품은 자동완성, 그 외는 직접 입력.

### 입력 방식 3가지 (탭 전환, MVP 모두 포함)
| 탭 | 설명 | 정확도 | 대상 |
|---|---|---|---|
| **바코드 스캔** | Edge Function → 식약처 DB 조회 | 100% (DB 등록분) | 가공식품 |
| **자동완성 입력** | 신선식품 마스터에서 검색 + 일러스트 매칭 | 100% | 양파, 사과, 우유 등 |
| **직접 입력** | 자유 텍스트 + 카테고리 선택 | 사용자 책임 | 기타 |

### 바코드 플로우
1. 사용자가 [+ 재료 추가] FAB 버튼 탭
2. 입력 화면 진입 (탭 3개: 바코드 / 자동완성 / 직접)
3. 바코드 탭: `MobileScanner` → 인식 성공 시 하단 슬라이드업
4. **`lookup-barcode` Edge Function 호출** (식약처 API 키는 서버에만)
5. 응답으로 자동 채움: 제품명, 카테고리, 식품유형
6. 사용자 입력: 유통기한, 수량, 보관 위치
7. [냉장고에 추가] → Postgres `INSERT` + Hive 캐시 갱신

### 자동완성 플로우 (신선식품 — MVP 필수)
1. 자동완성 탭 진입
2. 검색창에 2글자 이상 입력 (예: "양파")
3. `ingredient_db.dart` 마스터에서 부분일치 검색 → 칩 리스트 표시
4. 사용자가 칩 탭 → 자동 채움 (이름, 카테고리, 일러스트)
5. 유통기한/수량/보관 위치 입력
6. [냉장고에 추가] → Postgres 저장

```dart
// 자동완성 위젯 예시
Autocomplete<IngredientMaster>(
  optionsBuilder: (text) {
    if (text.text.length < 2) return const [];
    return ingredientMasterList
        .where((m) => m.name.contains(text.text))
        .take(8);
  },
  displayStringForOption: (m) => m.name,
  onSelected: (m) => _fillForm(m),
)
```

### 직접 입력 플로우
1. 자유 텍스트 입력 → 카테고리 `ChoiceChip` 선택 → 유통기한 등 → 저장
2. 일러스트는 카테고리 폴백 아이콘 사용

### 유통기한 처리
- 식약처 응답의 `POG_DAYCNT`(제조일~소비기한)는 **참고용 기본값**으로 표시
- 사용자가 직접 입력한 값을 우선 (스캔 시점 ≠ 제조일)
- 미입력 시 D-day 계산에서 제외 (정렬 맨 뒤)

### 기술 요구사항
- `mobile_scanner` ^6.0.0 (바코드 + QR)
- `Autocomplete<T>` 위젯 (Flutter 내장)
- `permission_handler` (카메라 권한)
- `BarcodeProxyService` (Edge Function 호출)

### 우선순위: P0 (MVP 필수)

---

## F-02: 드래그앤드롭 재료 조합 ⭐ (최대 차별점)

### 설명
등록된 재료를 드래그하여 항아리 캐릭터에 드롭하면, 선택된 재료 목록이 구성된다.

### 상세 플로우
1. 화면 상단 60%: 내 냉장고 재료 칩/카드 (카테고리 필터)
2. 화면 하단 40%: 항아리 캐릭터 (드롭 존)
3. 재료 칩을 길게 눌러 드래그 시작
4. 항아리 위로 가져가면 → 항아리 하이라이트 (스케일 1.1 + 글로우)
5. 드롭하면 → 햅틱 + 파티클 + 항아리 안에 재료 아이콘 추가
6. 이미 넣은 재료는 상단에서 반투명 + 체크 표시
7. 항아리 탭 → 넣은 재료 리스트 바텀시트 (개별 제거)
8. 재료 2개 이상 → [요리 시작!] 버튼 활성화

### Flutter 드래그앤드롭 구현
```dart
// 드래그 가능한 재료
Draggable<Ingredient>(
  data: ingredient,
  feedback: Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(12),
    child: IngredientChip(ingredient, isDragging: true),
  ),
  childWhenDragging: Opacity(
    opacity: 0.3,
    child: IngredientChip(ingredient),
  ),
  child: IngredientChip(ingredient),
)

// 항아리 드롭 존
DragTarget<Ingredient>(
  onWillAcceptWithDetails: (details) {
    // 항아리 하이라이트 ON
    setState(() => _isHighlighted = true);
    return true;
  },
  onLeave: (_) => setState(() => _isHighlighted = false),
  onAcceptWithDetails: (details) {
    HapticFeedback.mediumImpact();
    ref.read(potProvider.notifier).addIngredient(details.data);
    setState(() => _isHighlighted = false);
  },
  builder: (context, candidateData, rejectedData) {
    return AnimatedScale(
      scale: _isHighlighted ? 1.1 : 1.0,
      duration: Duration(milliseconds: 200),
      child: PotWidget(items: potItems),
    );
  },
)
```

### 기술 요구사항
- Flutter 내장 `Draggable` + `DragTarget` 위젯
- `HapticFeedback` (진동 피드백)
- `AnimatedScale`, `AnimatedContainer` (하이라이트 효과)
- Lottie/Rive (항아리 파티클 이펙트, 선택)

### 우선순위: P0

---

## F-03: AI 레시피 생성 ⭐

### 설명
항아리에 넣은 재료 목록을 **`generate-recipe` Edge Function**에 전달한다. 서버가 캐시 조회 → Rate Limit 검사 → OpenAI 호출 순으로 처리한다.

### 호출 흐름
```
[Flutter] supabase.functions.invoke('generate-recipe', {ingredients})
    ↓
[Edge Function]
  1) JWT 검증
  2) Rate Limit 검사 (api_usage 일일 10회)
  3) recipe_cache 조회 (SHA-256(정렬재료))
  4) 캐시 적중 → 즉시 반환 (source: 'cache')
  5) 캐시 미스 → OpenAI 호출 → 캐시 저장 → 반환 (source: 'openai')
    ↓
[Flutter] List<Recipe> 매핑 → ResultsScreen
```

### AI 프롬프트 전략 (MVP)
- **인기 요리 50개 카탈로그**로 제약 → 이미지 매칭 보장
- GPT-4o-mini, `response_format: json_object`
- 시스템 프롬프트는 Edge Function에 하드코딩 (`recipes_top.ts`)
- 응답: 요리명, 카테고리, 난이도, 시간, 재료(보유여부), 단계별 가이드, 팁

### 이미지 매칭
```
AI가 "감자채 볶음" (id: potato_stir_fry) 추천
    ↓
assets/images/dishes/potato_stir_fry.png 매칭
    ↓
매칭 실패 시 → assets/images/categories/stir_fry.png 폴백
```

### Rate Limit 초과 시 UX
- 다이얼로그: "오늘 요리 추천을 다 썼어요. 자정에 초기화돼요."
- [즐겨찾기 보기] 버튼 → 오프라인 캐시된 레시피 표시
- (v1.1) 광고 시청 → 1회 추가 등 비즈니스 모델 여지

### 로딩 문구 (랜덤)
- "감자와 양파가 만나고 있어요..."
- "AI 셰프가 고민 중이에요..."
- "거의 완성! 맛을 보고 있어요..."

### 캐시 적중 시 UX 차이
- 응답이 **<300ms** → 로딩 애니메이션을 짧게 보여주고 결과로 이동
- 적중 표시는 내부 로깅용으로만, 사용자에게는 노출하지 않음

### 우선순위: P0

---

## F-04: 내 냉장고 (홈 화면)

### 구성
- 상단: "내 냉장고" 타이틀 + 총 재료 수 + 알림 벨
- 유통기한 임박 경고 배너
- 카테고리 필터 칩 (가로 스크롤)
- 재료 카드 2열 그리드 (일러스트 + 이름 + D-day 뱃지)
- 하단 고정: [요리 시작] 버튼
- FAB: [+ 재료 스캔]
- 바텀 네비: 냉장고 / 조합 / 기록 / 설정

### 재료 카드 인터랙션
- 탭: 수정 바텀시트
- 롱프레스: 삭제 확인
- 스와이프 좌: `Dismissible`로 빠른 삭제

### 우선순위: P0

---

## F-05: 레시피 상세 + 요리 타이머

### 구성
- 히어로: 요리 일러스트
- 정보: 시간, 인분, 난이도
- 필요 재료 (✅ 냉장고에 있음 / ⚠️ 없음)
- 단계별 가이드 + 타이머 버튼
- 여러 타이머 동시 실행 가능
- 백그라운드 알림 (`flutter_local_notifications`)

### 우선순위: P0

---

## F-06: 유통기한 알림

### 알림 규칙
| 시점 | 메시지 |
|---|---|
| D-3 | "🥕 당근 유통기한 3일 남았어요!" |
| D-1 | "⚠️ 돼지고기 내일까지예요!" |
| D-Day | "🚨 우유 유통기한 오늘까지!" |

### 알림 탭 시: 해당 재료 기반 AI 추천 레시피 표시
### 기술: `flutter_local_notifications` + `workmanager` (백그라운드)
### 우선순위: P1

---

## F-07: 즐겨찾기 / 요리 히스토리

- 레시피 상세에서 ❤️ 탭 → Hive 저장
- 기록 탭에서 날짜별 조회
- 즐겨찾기 레시피는 오프라인 조회 가능
### 우선순위: P1

---

## F-08: 온보딩

- 3단계: 스캔 → 항아리 → AI 레시피
- 최초 실행 시만 (Hive 플래그)
- 하단: 도트 인디케이터 + [다음]/[시작하기] 버튼
### 우선순위: P1

---

## F-09: 설정

- 알림 ON/OFF, 기본 인분 수
- 식이 제한 (채식/비건/알레르기)
- 데이터 초기화, 앱 정보
### 우선순위: P1

---

## F-10: 텍스트 OCR (v1.1)
- `google_mlkit_text_recognition` 한글 OCR
- 바코드 없는 가공식품용 보조 입력
### 우선순위: P2

## F-11: 요리 완료 시 재료 자동 차감 (v1.1)
- 레시피 상세에서 [요리 완료] 버튼
- 사용된 재료 수량 자동 감소 / 0이 되면 삭제 확인
### 우선순위: P2

## F-12: 통계 대시보드 (v1.1)
- `fl_chart` 패키지
- 월별 요리 횟수, 가장 많이 만든 카테고리, 절약된 식재료 수 등
### 우선순위: P2

## F-13: 가족 냉장고 공유 (v1.1)
- Supabase Realtime + 그룹(워크스페이스) 모델
- 한 냉장고를 여러 유저가 공유 → 실시간 동기화
- RLS 정책 변경: `auth.uid() IN (SELECT user_id FROM fridge_members WHERE fridge_id = ...)`
### 우선순위: P2
