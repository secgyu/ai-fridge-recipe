import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fridge_meal/core/theme/app_colors.dart';
import 'package:fridge_meal/core/theme/app_spacing.dart';
import 'package:fridge_meal/core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1500),
  });

  final VoidCallback onComplete;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _steam;
  late final AnimationController _wave;

  late final Animation<double> _mascotOpacity;
  late final Animation<double> _mascotScale;
  late final Animation<double> _word1;
  late final Animation<double> _word2;
  late final Animation<double> _word3;
  late final Animation<double> _subtitle;
  late final Animation<double> _hint;
  late final Animation<double> _fadeOut;

  bool _completed = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _master = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_onMasterStatus);

    _steam = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _mascotOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );

    _mascotScale =
        TweenSequence<double>(<TweenSequenceItem<double>>[
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 0.72,
              end: 1.05,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 65,
          ),
          TweenSequenceItem<double>(
            tween: Tween<double>(
              begin: 1.05,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 25,
          ),
          TweenSequenceItem<double>(
            tween: ConstantTween<double>(1.0),
            weight: 10,
          ),
        ]).animate(
          CurvedAnimation(parent: _master, curve: const Interval(0.0, 0.4)),
        );

    _word1 = _wordAnim(0.23, 0.40);
    _word2 = _wordAnim(0.27, 0.44);
    _word3 = _wordAnim(0.31, 0.48);

    _subtitle = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.47, 0.65, curve: Curves.easeOutCubic),
    );

    _hint = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.60, 0.78, curve: Curves.easeOut),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.87, 1.0, curve: Curves.easeIn),
      ),
    );

    _master.forward();
  }

  Animation<double> _wordAnim(double begin, double end) {
    return CurvedAnimation(
      parent: _master,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  void _onMasterStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      HapticFeedback.lightImpact();
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _master.removeStatusListener(_onMasterStatus);
    _master.dispose();
    _steam.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 0.95,
            colors: <Color>[Color(0xFFFFFAF7), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeOut,
            child: Stack(
              children: <Widget>[
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _buildMascotWithSteam(),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildTitle(),
                      const SizedBox(height: AppSpacing.md),
                      _buildSubtitle(),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                    child: _buildHint(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMascotWithSteam() {
    return SizedBox(
      width: 220,
      height: 230,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            top: 0,
            child: SizedBox(
              width: 88,
              height: 78,
              child: AnimatedBuilder(
                animation: _steam,
                builder: (_, _) =>
                    CustomPaint(painter: _SteamPainter(progress: _steam.value)),
              ),
            ),
          ),
          FadeTransition(
            opacity: _mascotOpacity,
            child: ScaleTransition(
              scale: _mascotScale,
              child: SizedBox(
                width: 170,
                height: 170,
                child: Image.asset(
                  'assets/images/splash/splash.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        _StaggerWord(animation: _word1, text: '냉장고'),
        const SizedBox(width: 14),
        _StaggerWord(animation: _word2, text: '한'),
        const SizedBox(width: 14),
        _StaggerWord(animation: _word3, text: '끼'),
      ],
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _subtitle,
      builder: (_, _) {
        final double v = _subtitle.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 8),
            child: const Text(
              '냉장고 속 재료가 한 끼가 되다',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
                letterSpacing: -0.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHint() {
    return AnimatedBuilder(
      animation: _hint,
      builder: (_, child) {
        return Opacity(
          opacity: _hint.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _hint.value) * 8),
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DotWave(controller: _wave),
          const SizedBox(width: AppSpacing.md),
          const Text(
            '앱을 준비하고 있어요',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggerWord extends StatelessWidget {
  const _StaggerWord({required this.animation, required this.text});

  final Animation<double> animation;
  final String text;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final double v = animation.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 14),
            child: Text(text, style: AppTypo.heroTitle),
          ),
        );
      },
    );
  }
}

class _DotWave extends StatelessWidget {
  const _DotWave({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 10,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(3, (int i) {
              final double phase = (controller.value + i * 0.18) % 1.0;
              final double scale = _scaleFor(phase);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  double _scaleFor(double phase) {
    if (phase < 0.4) {
      return 0.55 + 0.45 * math.sin(phase / 0.4 * math.pi);
    }
    return 0.55;
  }
}

class _SteamPainter extends CustomPainter {
  _SteamPainter({required this.progress});

  final double progress;

  static const List<_WispSpec> _wisps = <_WispSpec>[
    _WispSpec(xRatio: 0.30, phase: 0.00, amplitude: 7, length: 0.95),
    _WispSpec(xRatio: 0.50, phase: 0.34, amplitude: 5, length: 1.00),
    _WispSpec(xRatio: 0.70, phase: 0.67, amplitude: 6, length: 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final _WispSpec w in _wisps) {
      final double t = (progress + w.phase) % 1.0;
      _paintWisp(canvas, size, w, t);
    }
  }

  void _paintWisp(Canvas canvas, Size size, _WispSpec w, double t) {
    final double opacity = _opacityCurve(t);
    if (opacity <= 0.01) return;

    final double wispLength = size.height * 0.55 * w.length;
    final double travel = size.height + wispLength;
    final double yTop = size.height - t * travel;
    final double baseX = size.width * w.xRatio;

    final Path path = Path();
    const int segments = 12;
    for (int i = 0; i <= segments; i++) {
      final double localT = i / segments;
      final double y = yTop + wispLength * localT;
      final double wave =
          math.sin((localT * 3.0 + t * 3.0) * math.pi) * w.amplitude;
      final double x = baseX + wave;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint paint = Paint()
      ..color = AppColors.primary.withValues(alpha: opacity * 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  double _opacityCurve(double t) {
    if (t < 0.15) return t / 0.15;
    if (t > 0.85) return (1.0 - t) / 0.15;
    return 1.0;
  }

  @override
  bool shouldRepaint(_SteamPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WispSpec {
  const _WispSpec({
    required this.xRatio,
    required this.phase,
    required this.amplitude,
    required this.length,
  });

  final double xRatio;
  final double phase;
  final double amplitude;
  final double length;
}
