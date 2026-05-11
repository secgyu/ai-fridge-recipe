import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/core/router/app_routes.dart';
import 'package:fridge_meal/core/router/main_shell.dart';
import 'package:fridge_meal/features/auth/data/repositories/auth_repository.dart';
import 'package:fridge_meal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fridge_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:fridge_meal/features/cook/presentation/screens/cook_screen.dart';
import 'package:fridge_meal/features/fridge/presentation/screens/fridge_screen.dart';
import 'package:fridge_meal/features/history/presentation/screens/history_screen.dart';
import 'package:fridge_meal/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:fridge_meal/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:fridge_meal/features/settings/presentation/screens/privacy_screen.dart';
import 'package:fridge_meal/features/settings/presentation/screens/settings_screen.dart';
import 'package:fridge_meal/features/settings/presentation/screens/terms_screen.dart';
import 'package:fridge_meal/features/splash/presentation/screens/splash_screen.dart';

part 'app_router.g.dart';

/// 앱 라이프타임 동안 유지되는 단일 GoRouter 인스턴스.
///
/// 가드 정책:
/// - `/splash`는 어떤 redirect에도 가로채이지 않음 (시작 지점).
/// - 온보딩 미완료 → `/onboarding` 강제.
/// - 미로그인 → `/login` 강제.
/// - 로그인 + 게이트(`/onboarding`/`/login`) 시도 → `/fridge` 강제.
///
/// 메인 셸:
/// - `StatefulShellRoute.indexedStack`로 4탭(`/fridge`/`/cook`/`/history`/`/settings`).
/// - 각 탭은 독립 네비게이션 스택을 유지. 탭 재선택 시 해당 탭의 스택 루트로 pop.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // GoRouter는 ChangeNotifier를 구독하므로 Riverpod 상태 변화를
  // ValueNotifier로 브릿징해 redirect를 재평가시킨다.
  final ValueNotifier<Object?> refresh = ValueNotifier<Object?>(null);
  ref.onDispose(refresh.dispose);

  ref.listen(onboardingCompletedProvider, (_, _) {
    refresh.value = Object();
  });
  ref.listen(authStateProvider, (_, _) {
    refresh.value = Object();
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      final String loc = state.matchedLocation;

      // 스플래시는 항상 통과. 자체 타이머 종료 후 → go(home).
      if (loc == AppRoutes.splash) return null;

      final bool onboardingDone = ref.read(onboardingCompletedProvider);
      if (!onboardingDone) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      final AuthMode authMode = ref.read(authStateProvider);
      final bool isLoggedIn = authMode == AuthMode.authenticated ||
          authMode == AuthMode.guest;
      if (!isLoggedIn) {
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }

      // 로그인된 사용자는 게이트(onboarding/login) 진입 차단.
      if (loc == AppRoutes.onboarding || loc == AppRoutes.login) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage(
          state: state,
          child: SplashScreen(
            onComplete: () => context.go(AppRoutes.home),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.fridge,
                pageBuilder: _branchPageBuilder(const FridgeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.cook,
                pageBuilder: _branchPageBuilder(const CookScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.history,
                pageBuilder: _branchPageBuilder(const HistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: _branchPageBuilder(const SettingsScreen()),
                routes: <RouteBase>[
                  GoRoute(
                    path: 'terms',
                    builder: (BuildContext context, GoRouterState state) =>
                        const TermsScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (BuildContext context, GoRouterState state) =>
                        const PrivacyScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// 셸 내부 탭 페이지는 push 전환이 아니라 IndexedStack이므로
/// 페이지 전환 애니메이션이 필요 없다. NoTransitionPage로 안전하게 처리.
GoRouterPageBuilder _branchPageBuilder(Widget child) {
  return (BuildContext context, GoRouterState state) =>
      NoTransitionPage<void>(key: state.pageKey, child: child);
}

/// 게이트(스플래시/온보딩/로그인)에 적용되는 280ms 부드러운 fade 트랜지션.
CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
