import 'dart:async';

import 'package:flutter/gestures.dart';
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
/// - 카카오 / Apple 소셜 로그인 (UI만, OAuth는 추후 통합)
/// - 이메일 로그인 진입점
/// - "가입 없이 둘러보기" 게스트 진입
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // 브랜드 컬러는 가이드라인 준수를 위해 이 화면 안에서만 하드코딩.
  static const Color _kakaoYellow = Color(0xFFFEE500);
  static const Color _kakaoText = Color(0xFF191919);

  // 대화면(태블릿) 가독성 상한.
  static const double _maxContentWidth = 480;

  bool _pending = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.huge),
                    const _Header(),
                    const SizedBox(height: AppSpacing.xxxl),
                    const TextDivider(text: '소셜 계정으로 빠르게 로그인'),
                    const SizedBox(height: AppSpacing.xl),
                    Semantics(
                      button: true,
                      label: '카카오 계정으로 계속하기',
                      child: SocialLoginButton(
                        icon: const KakaoIcon(),
                        label: '카카오로 계속하기',
                        backgroundColor: _kakaoYellow,
                        foregroundColor: _kakaoText,
                        onPressed: _pending
                            ? null
                            : () => _showComingSoon('카카오 로그인'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      button: true,
                      label: 'Apple 계정으로 계속하기',
                      child: SocialLoginButton(
                        icon: const Icon(
                          Icons.apple,
                          size: 24,
                          color: Colors.white,
                        ),
                        label: 'Apple로 계속하기',
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        onPressed: _pending
                            ? null
                            : () => _showComingSoon('Apple 로그인'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const TextDivider(text: '또는'),
                    const SizedBox(height: AppSpacing.xl),
                    _AltLoginCard(
                      rows: <_AltLoginRowData>[
                        _AltLoginRowData(
                          icon: Icons.mail_outline_rounded,
                          label: '이메일로 로그인',
                          onTap: _pending
                              ? null
                              : () => _showComingSoon('이메일 로그인'),
                        ),
                        _AltLoginRowData(
                          icon: Icons.search_rounded,
                          label: '가입 없이 둘러보기',
                          trailing: _pending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.textTertiary,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: _pending ? null : _continueAsGuest,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _TermsFooter(
                      onTermsTap: () => _showComingSoon('서비스 이용약관'),
                      onPrivacyTap: () => _showComingSoon('개인정보 처리방침'),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueAsGuest() async {
    if (_pending) return;
    setState(() => _pending = true);
    unawaited(HapticFeedback.lightImpact());
    try {
      await ref.read(authStateProvider.notifier).continueAsGuest();
      // 라우터가 redirect로 자동 전환 → 이 화면은 곧 unmount.
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  void _showComingSoon(String label) {
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
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
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
    final bool enabled = data.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: data.label,
      child: Material(
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
                Icon(
                  data.icon,
                  size: 20,
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      letterSpacing: -0.2,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                data.trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 약관 / 개인정보 처리방침 풋터.
///
/// 각 링크 텍스트는 [TapGestureRecognizer]를 통해 탭 가능.
/// 실제 약관 페이지/URL은 추후 연결되며 현재는 콜백으로 위임한다.
class _TermsFooter extends StatefulWidget {
  const _TermsFooter({required this.onTermsTap, required this.onPrivacyTap});

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  @override
  State<_TermsFooter> createState() => _TermsFooterState();
}

class _TermsFooterState extends State<_TermsFooter> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTermsTap;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onPrivacyTap;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle linkStyle = TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    );

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.5,
          color: AppColors.textTertiary,
        ),
        children: <InlineSpan>[
          const TextSpan(text: '로그인 시 '),
          TextSpan(
            text: '서비스 이용약관',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' 및 '),
          TextSpan(
            text: '개인정보 처리방침',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(text: '에 동의하게 됩니다.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
