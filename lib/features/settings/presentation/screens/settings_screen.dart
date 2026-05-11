import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/features/auth/data/repositories/auth_repository.dart';
import 'package:fridge_meal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fridge_meal/features/settings/presentation/providers/settings_provider.dart';
import 'package:fridge_meal/features/settings/presentation/widgets/settings_row.dart';
import 'package:fridge_meal/features/settings/presentation/widgets/settings_section.dart';

/// 설정 탭.
///
/// MVP 범위:
/// - 계정: 모드 표시 + 로그아웃/게스트 종료
/// - 알림: 유통기한 알림 토글
/// - 요리 기본값: 기본 인분 수
/// - 정보: 약관/처리방침/앱 버전
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthMode authMode = ref.watch(authStateProvider);
    final bool expiryOn = ref.watch(expiryNotificationEnabledProvider);
    final int servings = ref.watch(defaultServingsProvider);
    final AsyncValue<String> version = ref.watch(appVersionProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.huge,
            ),
            children: <Widget>[
              const Text(
                '설정',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.6,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 계정
              SettingsSection(
                title: '계정',
                children: <Widget>[
                  SettingsRow(
                    label: _accountLabel(authMode),
                    subtitle: _accountSubtitle(authMode),
                  ),
                  ValueRow(
                    label: authMode == AuthMode.guest ? '게스트 모드 종료' : '로그아웃',
                    foregroundColor: AppColors.danger,
                    onTap: () => _confirmSignOut(context, ref, authMode),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // 알림
              SettingsSection(
                title: '알림',
                children: <Widget>[
                  SwitchRow(
                    label: '유통기한 알림',
                    subtitle: 'D-3 / D-Day에 푸시로 알려드려요',
                    value: expiryOn,
                    onChanged: (_) {
                      unawaited(HapticFeedback.selectionClick());
                      unawaited(
                        ref
                            .read(expiryNotificationEnabledProvider.notifier)
                            .toggle(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // 요리 기본값
              SettingsSection(
                title: '요리 기본값',
                children: <Widget>[
                  StepperRow(
                    label: '기본 인분 수',
                    subtitle: '레시피 추천 시 기본으로 사용',
                    value: servings,
                    min: 1,
                    max: 6,
                    unit: '인분',
                    onDecrement: () {
                      unawaited(HapticFeedback.selectionClick());
                      unawaited(
                        ref.read(defaultServingsProvider.notifier).decrement(),
                      );
                    },
                    onIncrement: () {
                      unawaited(HapticFeedback.selectionClick());
                      unawaited(
                        ref.read(defaultServingsProvider.notifier).increment(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // 정보
              SettingsSection(
                title: '정보',
                children: <Widget>[
                  ValueRow(
                    label: '서비스 이용약관',
                    onTap: () => _showComingSoon(context, '서비스 이용약관'),
                  ),
                  ValueRow(
                    label: '개인정보 처리방침',
                    onTap: () => _showComingSoon(context, '개인정보 처리방침'),
                  ),
                  ValueRow(
                    label: '앱 버전',
                    value: version.maybeWhen(
                      data: (String v) => v,
                      orElse: () => '–',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _accountLabel(AuthMode mode) {
    switch (mode) {
      case AuthMode.unauthenticated:
        return '로그인이 필요해요';
      case AuthMode.guest:
        return '게스트로 둘러보는 중';
      case AuthMode.authenticated:
        return '로그인 됨';
    }
  }

  static String? _accountSubtitle(AuthMode mode) {
    switch (mode) {
      case AuthMode.unauthenticated:
        return null;
      case AuthMode.guest:
        return '로그인하면 여러 기기에서 동기화돼요';
      case AuthMode.authenticated:
        // TODO(supabase): Supabase Auth 연동 후 사용자 이메일 표시.
        return null;
    }
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AuthMode mode,
  ) async {
    final bool isGuest = mode == AuthMode.guest;
    final String title = isGuest ? '둘러보기를 끝낼까요?' : '로그아웃 할까요?';
    const String message = '계정 정보로 다시 돌아갈 수 있어요';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.rLg),
        title: Text(title),
        content: const Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              isGuest ? '종료' : '로그아웃',
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    unawaited(HapticFeedback.lightImpact());
    await ref.read(authStateProvider.notifier).signOut();
    // 라우터 redirect가 /login으로 자동 이동시킴.
  }

  void _showComingSoon(BuildContext context, String label) {
    unawaited(HapticFeedback.selectionClick());
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label은 곧 만나실 수 있어요'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.rMd),
        ),
      );
  }
}
