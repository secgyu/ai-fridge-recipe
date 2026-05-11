import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

import 'package:fridge_meal/core/theme/app_radius.dart';

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
            border: borderColor != null
                ? Border.all(color: borderColor!)
                : null,
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

/// 카카오 공식 브랜드 마크.
///
/// - 출처: tablecheck-icons (Public Domain) — Kakao 공식 말풍선 형태
/// - 사전 컴파일된 `.svg.vec` 자산을 `VectorGraphic`으로 로드 (런타임 SVG 파싱 없음)
/// - 색상은 [color]로 오버라이드 (기본: 검정 #191919)
///
/// SVG 원본을 수정한 후에는 반드시 다음을 실행해 `.vec`를 재생성하세요:
/// ```bash
/// dart run vector_graphics_compiler --input-dir assets/images/auth --tessellate
/// ```
class KakaoIcon extends StatelessWidget {
  const KakaoIcon({
    super.key,
    this.size = 20,
    this.color = const Color(0xFF191919),
  });

  static const AssetBytesLoader _loader = AssetBytesLoader(
    'assets/images/auth/kakao.svg.vec',
  );

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VectorGraphic(
      loader: _loader,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
