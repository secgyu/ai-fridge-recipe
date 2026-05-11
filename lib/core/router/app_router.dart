import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/core/router/app_routes.dart';
import 'package:fridge_meal/features/auth/data/repositories/auth_repository.dart';
import 'package:fridge_meal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fridge_meal/features/auth/presentation/screens/login_screen.dart';
import 'package:fridge_meal/features/fridge/presentation/screens/fridge_screen.dart';
import 'package:fridge_meal/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:fridge_meal/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:fridge_meal/features/splash/presentation/screens/splash_screen.dart';

part 'app_router.g.dart';

/// 앱 라이프타임 동안 유지되는 단일 GoRouter 인스턴스.
///
/// 가드 정책:
/// - `/splash`는 어떤 redirect에도 가로채이지 않음 (시작 지점, 자체적으로 onComplete 시 `/`로 이동).
/// - 온보딩 미완료 + 다른 경로 시도 → `/onboarding` 강제.
/// - 온보딩 완료 + `/onboarding` 진입 시도 → `/` 강제.
///
/// 추후 인증 가드(F-00)가 도입되면 같은 redirect 안에 추가한다.
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

      // 스플래시는 항상 통과. 자체 타이머가 끝나면 onComplete → go(/).
      if (loc == AppRoutes.splash) return null;

      final bool onboardingDone = ref.read(onboardingCompletedProvider);
      if (!onboardingDone) {
        return loc == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // 온보딩 완료 후 인증 가드.
      final AuthMode authMode = ref.read(authStateProvider);
      final bool isLoggedIn = authMode == AuthMode.authenticated ||
          authMode == AuthMode.guest;

      if (!isLoggedIn) {
        return loc == AppRoutes.login ? null : AppRoutes.login;
      }

      // 이미 로그인된 사용자는 onboarding/login 진입 차단.
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
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage(
          state: state,
          child: const FridgeScreen(),
        ),
      ),
    ],
  );
}

/// 모든 페이지에 적용되는 280ms 부드러운 fade 트랜지션.
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
