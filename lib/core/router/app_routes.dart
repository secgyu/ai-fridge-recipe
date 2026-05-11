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

  // 메인 — 현재는 단일 화면(`FridgeScreen`)이 `/`에 렌더링된다.
  // 추후 ShellRoute + 바텀 네비 도입 시 이 경로는 냉장고 탭으로 옮겨질 수 있다.
  static const String home = '/';

  // 추후 추가 예정 (메인 플로우 도입 시)
  // static const String cook = '/cook';
  // static const String history = '/history';
  // static const String recipe = '/recipe/:id';
  // static const String settings = '/settings';
}
