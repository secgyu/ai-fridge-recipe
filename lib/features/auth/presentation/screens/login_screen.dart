import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_radius.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/theme/app_typography.dart';
import 'package:fridge_meal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fridge_meal/features/auth/presentation/widgets/social_login_button.dart';
import 'package:fridge_meal/features/auth/presentation/widgets/text_divider.dart';

/// 로그인 화면.
///
/// 카카오 / 네이버 / Apple 소셜 로그인 (UI만, OAuth는 추후 통합),
/// 이메일 로그인 진입점, "가입 없이 둘러보기" 게스트 진입을 제공한다.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  // 브랜드 컬러는 가이드라인 준수를 위해 이 화면 안에서만 하드코딩.
  static const Color _kakaoYellow = Color(0xFFFEE500);
  static const Color _kakaoText = Color(0xFF191919);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: AppSpacing.huge),
              const _Header(),
              const SizedBox(height: AppSpacing.xxxl),
              const TextDivider(text: '소셜 계정으로 빠르게 로그인'),
              const SizedBox(height: AppSpacing.xl),
              SocialLoginButton(
                icon: const KakaoIcon(),
                label: '카카오로 계속하기',
                backgroundColor: _kakaoYellow,
                foregroundColor: _kakaoText,
                onPressed: () => _showComingSoon(context, '카카오 로그인'),
              ),
              const SizedBox(height: AppSpacing.md),
              SocialLoginButton(
                icon: const Icon(
                  Icons.apple,
                  size: 24,
                  color: Colors.white,
                ),
                label: 'Apple로 계속하기',
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onPressed: () => _showComingSoon(context, 'Apple 로그인'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const TextDivider(text: '또는'),
              const SizedBox(height: AppSpacing.xl),
              _AltLoginCard(
                rows: <_AltLoginRowData>[
                  _AltLoginRowData(
                    icon: Icons.mail_outline_rounded,
                    label: '이메일로 로그인',
                    onTap: () => _showComingSoon(context, '이메일 로그인'),
                  ),
                  _AltLoginRowData(
                    icon: Icons.search_rounded,
                    label: '가입 없이 둘러보기',
                    onTap: () async {
                      unawaited(HapticFeedback.lightImpact());
                      await ref
                          .read(authStateProvider.notifier)
                          .continueAsGuest();
                      // 라우터가 redirect로 자동 전환.
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const _TermsFooter(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 64,
          height: 64,
          child: Image.asset(
            'assets/images/splash/splash.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const Text('냉장고 한 끼', style: AppTypo.heroTitle),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          '간편하게 시작해보세요',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.4,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AltLoginRowData {
  const _AltLoginRowData({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _AltLoginCard extends StatelessWidget {
  const _AltLoginCard({required this.rows});

  final List<_AltLoginRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows.length; i++) ...<Widget>[
            _AltLoginRow(data: rows[i]),
            if (i != rows.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Divider(height: 1, thickness: 1, color: AppColors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _AltLoginRow extends StatelessWidget {
  const _AltLoginRow({required this.data});

  final _AltLoginRowData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: AppRadius.rLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Icon(data.icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  data.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: AppColors.textTertiary,
        ),
        children: <InlineSpan>[
          TextSpan(text: '로그인 시 '),
          TextSpan(
            text: '서비스 이용약관',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: ' 및 '),
          TextSpan(
            text: '개인정보 처리방침',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: '에 동의하게 됩니다.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
