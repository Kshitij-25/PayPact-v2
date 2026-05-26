import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:paypact/core/navigation/app_router.dart';
import 'package:paypact/design_system/tokens/typography.dart';
import 'package:paypact/features/splash/cubit/splash_cubit.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashCubit()..start(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashDone) {
            if (state.isAuthenticated) {
              context.go(AppRoutes.home);
            } else {
              context.go(AppRoutes.onboarding);
            }
          }
        },
        child: const _SplashBody(),
      ),
    );
  }
}

class _SplashBody extends StatefulWidget {
  const _SplashBody();

  @override
  State<_SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<_SplashBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _wordmarkFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _markScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.32, curve: Curves.easeOut)),
    );
    _markFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );
    _wordmarkFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.24, 0.44, curve: Curves.easeOut),
    );
    _taglineFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.30, 0.50, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.32, 0.96, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1F1B16);
    const ink = Color(0xFFFAF7F1);
    const clay = Color(0xFFC77556);

    return Scaffold(
      backgroundColor: surface,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -80,
            child: _glow(clay.withValues(alpha: 0.32), 420),
          ),
          Positioned(
            bottom: -120,
            right: -100,
            child:
                _glow(const Color(0xFF7DA37C).withValues(alpha: 0.18), 380),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _markFade,
                  child: ScaleTransition(
                    scale: _markScale,
                    child: _PactMark(
                        size: 92, ringColor: clay, inkColor: ink),
                  ),
                ),
                const SizedBox(height: 38),
                FadeTransition(
                  opacity: _wordmarkFade,
                  child: Text(
                    'PayPact',
                    style: PayPactTypography.displayLg.copyWith(
                      color: ink,
                      letterSpacing: -0.04 * 28,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _taglineFade,
                  child: SizedBox(
                    width: 240,
                    child: Text(
                      'Quiet money between people who matter.',
                      textAlign: TextAlign.center,
                      style: PayPactTypography.bodyLg.copyWith(
                        color: ink.withValues(alpha: 0.55),
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (_, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: clay,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'V 2.0 · WARMING UP',
                  style: PayPactTypography.label.copyWith(
                    color: ink.withValues(alpha: 0.35),
                    fontSize: 10,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color c, double s) => Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [c, c.withValues(alpha: 0)], stops: const [0, 0.7]),
        ),
      );
}

class _PactMark extends StatelessWidget {
  const _PactMark(
      {required this.size, required this.ringColor, required this.inkColor});
  final double size;
  final Color ringColor;
  final Color inkColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PactPainter(ringColor, inkColor)),
    );
  }
}

class _PactPainter extends CustomPainter {
  _PactPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.033;
    final r = size.width * 0.305;
    final pa = Paint()
      ..color = a
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final pb = Paint()
      ..color = b.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(Offset(size.width * 0.39, size.height * 0.5), r, pa);
    canvas.drawCircle(Offset(size.width * 0.61, size.height * 0.5), r, pb);
  }

  @override
  bool shouldRepaint(_) => false;
}
