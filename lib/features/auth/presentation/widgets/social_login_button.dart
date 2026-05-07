import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:fridge_meal/core/theme/app_radius.dart';

/// 소셜 로그인 버튼 (카카오 등 커스텀 브랜드 버튼용).
///
/// - 높이 56pt, radius 16
/// - 좌측 24pt 위치에 아이콘, 텍스트는 절대 가운데 정렬
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.borderColor,
  });

  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: AppRadius.rLg,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.rLg,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: AppRadius.rLg,
            border:
                borderColor != null ? Border.all(color: borderColor!) : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -0.2,
                    color: foregroundColor,
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 0,
                bottom: 0,
                child: Center(child: icon),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카카오 공식 브랜드 마크 (SVG).
///
/// - 출처: tablecheck-icons (Public Domain) — Kakao 공식 말풍선 형태
/// - 색상은 [color]로 오버라이드 (기본: 검정 #191919)
class KakaoIcon extends StatelessWidget {
  const KakaoIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF191919),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/auth/kakao.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
