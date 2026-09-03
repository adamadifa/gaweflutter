import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/app/routes/app_router.dart';
import 'package:gaweflutter/core/constants/app_constants.dart';
import 'package:gaweflutter/core/services/mock_location_service.dart';
import 'package:gaweflutter/features/security/presentation/screens/fake_gps_block_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:gaweflutter/core/theme/app_theme_scheme.dart';
import 'package:gaweflutter/features/dashboard/presentation/providers/dashboard_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFakeGps();
    // Periodic check every 8 seconds
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _checkFakeGps();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkFakeGps();
    }
  }

  Future<void> _checkFakeGps() async {
    final mockService = ref.read(mockLocationServiceProvider);
    final isMock = await mockService.checkIsMockLocation();
    if (mounted) {
      final currentDetection = ref.read(isMockLocationDetectedProvider);
      if (currentDetection != isMock) {
        ref.read(isMockLocationDetectedProvider.notifier).setDetected(isMock);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final isFakeGpsDetected = ref.watch(isMockLocationDetectedProvider);
    final themeScheme = dashboardAsync.value?.generalSetting?.mobileThemeScheme;
    final primaryColor = AppThemeScheme.getPrimary(themeScheme);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          surface: AppThemeScheme.getBg(themeScheme),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E6152),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        if (isFakeGpsDetected) {
          return const FakeGpsBlockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
      routerConfig: router,
    );
  }
}
