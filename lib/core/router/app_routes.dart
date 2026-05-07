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

  // 메인
  static const String home = '/';

  // 추후 추가 예정 (메인 플로우 도입 시)
  // static const String fridge = '/fridge';
  // static const String cook = '/cook';
  // static const String recipe = '/recipe/:id';
  // static const String settings = '/settings';
}
