import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gaweflutter/core/config/app_config.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();

    // Check session & navigate after delay
    Timer(const Duration(milliseconds: 2200), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;

    // 1. Cek apakah server endpoint sudah dikonfigurasi (.env atau user input)
    final isConfigured = await AppConfig.isServerConfigured();
    if (!isConfigured) {
      if (mounted) {
        context.go('/server-config');
      }
      return;
    }

    // 2. Cek status autentikasi pengguna
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticated) {
      if (mounted) context.go('/dashboard');
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Center Animated Logo & App Title
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Brand Logo from local asset
                        Image.asset(
                          'assets/images/logo.png',
                          width: 105,
                          height: 105,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),

                        // App Title
                        const Text(
                          'GAWE',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Subtitle
                        const Text(
                          'Sistem Presensi & Kepegawaian',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Loading & Copyright
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFEA580C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'adamadifa | Programmer Introvert',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
