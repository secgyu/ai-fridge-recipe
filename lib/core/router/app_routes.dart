/// 앱 전역 라우트 경로 상수.
///
/// 모든 라우트 push/go는 이 클래스의 상수를 통해 호출한다.
/// 문자열 하드코딩 금지 — 오타와 리팩터 비용 방지.
class AppRoutes {
  const AppRoutes._();

  // 진입 / 게이트
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // 메인 셸 4탭 (StatefulShellRoute로 묶여 IndexedStack 유지).
  static const String fridge = '/fridge';
  static const String cook = '/cook';
  static const String history = '/history';
  static const String settings = '/settings';

  // 약관·처리방침은 인증 전에도 접근 가능해야 하므로 최상위에 둔다.
  // 가드 화이트리스트에 포함되어 어떤 상태에서도 push 가능.
  static const String terms = '/terms';
  static const String privacy = '/privacy';

  /// 로그인/스플래시가 가리키는 기본 메인 경로.
  /// 항상 첫 번째 탭(`/fridge`)으로 일치시킨다.
  static const String home = fridge;

  // 추후 추가 예정 (메인 플로우 도입 시)
  // static const String scan = '/scan';
  // static const String confirm = '/confirm';
  // static const String recipe = '/recipe/:id';
}
