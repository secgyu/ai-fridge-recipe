# UI_FLOW: 화면 플로우 및 디자인 가이드

## 디자인 컨셉: "따뜻한 키친 + 플레이풀"
- 밝은 크림 배경, 모든 이미지는 플랫 일러스트 (실사 금지)
- 귀여운 민트색 항아리 마스코트
- 게임 같은 드래그앤드롭 인터랙션

---

## 디자인 토큰

### 컬러
```dart
// lib/core/constants/app_colors.dart
class AppColors {
  static const background = Color(0xFFFFF8F0);      // 따뜻한 크림
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFFFF6B35);          // 오렌지
  static const primaryDark = Color(0xFFE55A2B);
  static const secondary = Color(0xFF2EC4B6);        // 민트
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFF2F4F6);

  // 카테고리 배경
  static const categoryVegetable = Color(0xFFE8F5E9);
  static const categoryFruit = Color(0xFFFFF3E0);
  static const categoryMeat = Color(0xFFFCE4EC);
  static const categorySeafood = Color(0xFFE0F7FA);
  static const categoryDairy = Color(0xFFE3F2FD);
  static const categorySeasoning = Color(0xFFEFEBE9);
  static const categoryGrain = Color(0xFFFFF8E1);
  static const categoryOther = Color(0xFFF5F5F5);
}
```

### 타이포그래피
```dart
class AppTypo {
  static const h1 = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.29);
  static const h2 = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, height: 1.36);
  static const h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.44);
  static const body = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.47);
  static const bodyBold = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
  static const caption = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  static const button = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const chip = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const badge = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
}
```

### 스페이싱 & 라운딩
```dart
class AppSpacing {
  static const xs = 4.0, sm = 8.0, md = 12.0;
  static const lg = 16.0, xl = 20.0, xxl = 24.0, xxxl = 32.0;
}

class AppRadius {
  static const sm = 8.0, md = 12.0, lg = 16.0, xl = 24.0;
  static final smBorder = BorderRadius.circular(sm);
  static final mdBorder = BorderRadius.circular(md);
  static final lgBorder = BorderRadius.circular(lg);
}
```

---

## GoRouter 라우트 구조

```dart
// lib/core/router/app_router.dart
final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),  // 바텀 네비
      routes: [
        GoRoute(path: '/fridge', builder: (_, __) => const FridgeScreen()),
        GoRoute(path: '/cook', builder: (_, __) => const CookScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
    
    GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
    GoRoute(path: '/confirm', builder: (_, __) => const ConfirmScreen()),
    GoRoute(path: '/cooking', builder: (_, __) => const CookingLoaderScreen()),
    GoRoute(path: '/results', builder: (_, __) => const ResultsScreen()),
    GoRoute(path: '/recipe/:id', builder: (_, state) => RecipeDetailScreen(
      recipeId: state.pathParameters['id']!,
    )),
  ],
);
```

---

## 화면별 와이어프레임

### 전체 플로우
```
[Splash] → [Onboarding(최초만)] → [내 냉장고(홈)]
                                       ↕
                                 [스캔] → [확인] → [저장]
                                       ↕
                                 [드래그앤드롭 조합]
                                       ↓
                                 [AI 로딩 애니메이션]
                                       ↓
                                 [레시피 결과 3카드]
                                       ↓
                                 [레시피 상세 + 타이머]
```

### 바텀 네비게이션 (4탭)
| 탭 | 아이콘 | 라벨 | path |
|---|---|---|---|
| 1 | Icons.kitchen | 냉장고 | /fridge |
| 2 | 항아리 커스텀 | 조합 | /cook |
| 3 | Icons.menu_book | 기록 | /history |
| 4 | Icons.settings | 설정 | /settings |

### Screen 1: 온보딩 — `PageView` 3페이지, 하단 dots + CTA
### Screen 2: 내 냉장고 — `GridView.count(crossAxisCount: 2)` + `FilterChip` + FAB
### Screen 3: 스캔 — `MobileScanner` 위젯 + 하단 `TabBar` (바코드/OCR/직접)
### Screen 4: 재료 확인 — `Image.asset` + `TextFormField` + `ChoiceChip` + 날짜피커
### Screen 5: 드래그앤드롭 — `Draggable<Ingredient>` + `DragTarget<Ingredient>` (⭐ 핵심)
### Screen 6: AI 로딩 — `Lottie.asset` + `AnimatedSwitcher` (문구) + `LinearProgressIndicator`
### Screen 7: 레시피 결과 — `ListView` 카드 3개 + 하단 재시도/변경 버튼
### Screen 8: 레시피 상세 — `SliverAppBar` 히어로 + 재료 체크 + 단계별 `Stepper` + 타이머

---

## 애니메이션 가이드

### 드래그앤드롭
```dart
// 항아리 하이라이트
AnimatedScale(scale: isHovered ? 1.1 : 1.0, duration: 200ms)
AnimatedContainer(decoration: isHovered ? glowBorder : normalBorder)

// 드롭 성공 시
HapticFeedback.mediumImpact()
// + 항아리 살짝 흔들림 (RotationTransition ±3°)
```

### AI 로딩
```
항아리: Lottie 반복 (pot_bubbling.json)
재료 부유: SlideTransition (Y축 ±10, 2초 loop)
문구 전환: AnimatedSwitcher (3초 간격 fade)
프로그레스: AnimatedContainer (width 0→100%)
```

### 페이지 전환
```
push: SlideTransition (우→좌)
modal: SlideTransition (하→상) — 스캔, 확인 화면
탭: FadeTransition (150ms)
```

---

## 접근성
- 터치 영역: 최소 48x48dp (`SizedBox` 래핑)
- 이미지: `Semantics(label: '토마토 재료')` 필수
- 대비: WCAG AA
- 폰트: `MediaQuery.textScaleFactor` 반영
