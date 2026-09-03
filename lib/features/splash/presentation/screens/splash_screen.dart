import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gaweflutter/core/theme/app_theme_scheme.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:gaweflutter/features/dashboard/presentation/providers/dashboard_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Check session & navigate after delay
    Timer(const Duration(milliseconds: 2200), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final authState = ref.read(authProvider);

    if (authState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final generalSetting = dashboardAsync.value?.generalSetting;
    final themeScheme = generalSetting?.mobileThemeScheme;
    final primaryColor = AppThemeScheme.getPrimary(themeScheme);
    final lightColor = AppThemeScheme.getLight(themeScheme);
    final logoUrl = generalSetting?.logo;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle Background Wave & Geometry Painter
          CustomPaint(
            painter: SplashBackgroundPainter(primaryColor: primaryColor, lightColor: lightColor),
          ),

          // Center Animated Logo & Branding
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Modern Logo Container with soft glow
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: (logoUrl != null && logoUrl.isNotEmpty)
                          ? Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.fingerprint_rounded,
                                size: 54,
                                color: primaryColor,
                              ),
                            )
                          : Icon(
                              Icons.fingerprint_rounded,
                              size: 54,
                              color: primaryColor,
                            ),
                    ),
                    const SizedBox(height: 24),

                    // App Title
                    Text(
                      generalSetting?.namaPerusahaan.toUpperCase() ?? 'HR & PRESENSI MOBILE',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // App Subtitle / Slogan
                    Text(
                      'Smart GPS & Biometric Attendance',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Loading Indicator & Copyright
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'HR & Presensi Mobile',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '© @adamadifa',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SplashBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Color lightColor;

  SplashBackgroundPainter({required this.primaryColor, required this.lightColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLight = Paint()
      ..color = lightColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final paintAccent = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    // Top Right Accent Circle
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), size.width * 0.45, paintLight);

    // Bottom Left Accent Circle
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), size.width * 0.55, paintLight);

    // Subtle Wave
    final wavePath = Path();
    wavePath.moveTo(0, size.height * 0.65);
    wavePath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.55,
      size.width * 0.7,
      size.height * 0.7,
    );
    wavePath.quadraticBezierTo(
      size.width * 0.88,
      size.height * 0.78,
      size.width,
      size.height * 0.75,
    );
    wavePath.lineTo(size.width, size.height);
    wavePath.lineTo(0, size.height);
    wavePath.close();

    canvas.drawPath(wavePath, paintAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
