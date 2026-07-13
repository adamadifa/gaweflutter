import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/app/routes/app_router.dart';
import 'package:gaweflutter/core/constants/app_constants.dart';

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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
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
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
