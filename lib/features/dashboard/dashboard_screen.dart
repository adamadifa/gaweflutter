import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:gaweflutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:gaweflutter/data/models/dashboard_model.dart';
import 'package:gaweflutter/features/profil/presentation/screens/profile_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/presensi_gps_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/riwayat_presensi_screen.dart';
import 'package:gaweflutter/features/profil/presentation/screens/idcard_screen.dart';
import 'package:gaweflutter/data/models/riwayat_model.dart';
import 'package:gaweflutter/features/izin/presentation/screens/izin_list_screen.dart';
import 'package:gaweflutter/features/slip_gaji/presentation/screens/slip_gaji_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/lembur_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/kunjungan_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/face_recognition_registration_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/aktivitas_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/lainnya_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/absen_istirahat_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/lembur_presensi_screen.dart';
import 'package:gaweflutter/core/theme/app_theme_scheme.dart';


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _historiNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _izinNavigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _settingNavigatorKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState>? _getCurrentNavigator() {
    switch (_currentIndex) {
      case 0: return _homeNavigatorKey;
      case 1: return _historiNavigatorKey;
      case 3: return _izinNavigatorKey;
      case 4: return _settingNavigatorKey;
      default: return null;
    }
  }

  late Timer _timer;
  String _timeString = '00:00:00';
  String _dateString = '';
  int _historyActiveTab = 0; // 0 for Presensi, 1 for Lembur
  final PageController _pageController = PageController();
  int _activeAlertPage = 0;
  int _totalAlertPages = 0;
  Timer? _sliderTimer;
  String _currentLocationName = 'Mencari lokasi...';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _fetchCurrentLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _sliderTimer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
      if (_pageController.hasClients && _totalAlertPages > 1) {
        final int nextPage = (_activeAlertPage + 1) % _totalAlertPages;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentLocationName = 'GPS tidak aktif';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentLocationName = 'Izin lokasi ditolak';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentLocationName = 'Izin lokasi ditolak permanen';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      final dio = Dio();
      dio.options.headers['User-Agent'] = 'GaweFlutter/1.0';
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'format': 'json',
          'lat': position.latitude,
          'lon': position.longitude,
          'zoom': 18,
          'addressdetails': 1,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final address = response.data['address'];
        String? displayName = response.data['display_name'];
        String locationText = '';
        if (address != null) {
          final road = address['road'] ?? address['suburb'] ?? address['village'] ?? '';
          final city = address['city'] ?? address['regency'] ?? address['municipality'] ?? '';
          if (road.isNotEmpty && city.isNotEmpty) {
            locationText = '$road, $city';
          } else if (displayName != null) {
            final parts = displayName.split(',');
            if (parts.length > 2) {
              locationText = '${parts[0].trim()}, ${parts[1].trim()}';
            } else {
              locationText = displayName;
            }
          }
        }
        if (locationText.isEmpty && displayName != null) {
          locationText = displayName;
        }
        if (mounted) {
          setState(() {
            _currentLocationName = locationText.isNotEmpty ? locationText : 'Lokasi tidak diketahui';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentLocationName = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocationName = 'Gagal mendapatkan lokasi';
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = DateFormat('HH:mm:ss').format(now);
    final String dayName = _getDayNameIndo(now.weekday);
    final String monthName = _getMonthNameIndo(now.month);
    final String formattedDate = 'Hari ini : $dayName, ${now.day} $monthName ${now.year}';

    if (mounted) {
      setState(() {
        _timeString = formattedTime;
        _dateString = formattedDate;
      });
    }
  }

  String _getDayNameIndo(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Senin';
      case DateTime.tuesday: return 'Selasa';
      case DateTime.wednesday: return 'Rabu';
      case DateTime.thursday: return 'Kamis';
      case DateTime.friday: return 'Jumat';
      case DateTime.saturday: return 'Sabtu';
      case DateTime.sunday: return 'Minggu';
      default: return '';
    }
  }

  String _getMonthNameIndo(int month) {
    switch (month) {
      case 1: return 'Januari';
      case 2: return 'Februari';
      case 3: return 'Maret';
      case 4: return 'April';
      case 5: return 'Mei';
      case 6: return 'Juni';
      case 7: return 'Juli';
      case 8: return 'Agustus';
      case 9: return 'September';
      case 10: return 'Oktober';
      case 11: return 'November';
      case 12: return 'Desember';
      default: return '';
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final generalSetting = dashboardAsync.value?.generalSetting;

    final Color primaryColor = AppThemeScheme.getPrimary(generalSetting?.mobileThemeScheme);
    final Color bodyBgColor = AppThemeScheme.getBg(generalSetting?.mobileThemeScheme);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          final navigator = _getCurrentNavigator();
          if (navigator != null && navigator.currentState != null && navigator.currentState!.canPop()) {
            navigator.currentState!.pop();
          } else {
            if (_currentIndex != 0) {
              setState(() {
                _currentIndex = 0;
              });
            } else {
              SystemNavigator.pop();
            }
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: [
            Navigator(
              key: _homeNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => _buildHomeTab(),
              ),
            ),
            Navigator(
              key: _historiNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const RiwayatPresensiScreen(),
              ),
            ),
            PresensiGpsScreen(
              isActive: _currentIndex == 2,
              onBackToHome: () {
                setState(() {
                  _currentIndex = 0;
                });
                ref.invalidate(dashboardProvider);
                ref.invalidate(lemburListProvider);
              },
            ),
            Navigator(
              key: _izinNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const IzinListScreen(),
              ),
            ),
            Navigator(
              key: _settingNavigatorKey,
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          setState(() {
            _currentIndex = 2; // Switch to Presensi/Fingerprint tab
          });
        },
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.fingerprint_rounded, size: 36, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        padding: EdgeInsets.zero,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home', primaryColor),
            _buildBottomNavItem(1, Icons.description_outlined, Icons.description_rounded, 'Histori', primaryColor),
            const SizedBox(width: 48), // Spacer for central FAB
            _buildBottomNavItem(3, Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Ajuan Izin', primaryColor),
            _buildBottomNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Setting', primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData iconOutline, IconData iconFilled, String label, Color primaryColor) {
    final bool isActive = _currentIndex == index;
    final Color itemColor = isActive ? primaryColor : const Color(0xFF64748B);

    return InkWell(
      onTap: () {
        if (_currentIndex == index) {
          final navigator = _getCurrentNavigator();
          if (navigator != null && navigator.currentState != null) {
            navigator.currentState!.popUntil((route) => route.isFirst);
          }
        } else {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            ref.invalidate(dashboardProvider);
            ref.invalidate(lemburListProvider);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 65,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconFilled : iconOutline,
              size: 22,
              color: itemColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: itemColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final dashboardState = ref.watch(dashboardProvider);
    final lemburListAsync = ref.watch(lemburListProvider);

    final Color primaryColor = AppThemeScheme.getPrimary(dashboardState.value?.generalSetting?.mobileThemeScheme);
    final Color bodyBgColor = AppThemeScheme.getBg(dashboardState.value?.generalSetting?.mobileThemeScheme);

    final int notifLembur = lemburListAsync.when(
      data: (list) {
        return list.where((item) {
          final status = int.tryParse(item['status']?.toString() ?? '0') ?? 0;
          final String? lemburIn = item['lembur_in'];
          final String? lemburOut = item['lembur_out'];
          return (status == 0 || status == 1) && (lemburIn == null || lemburOut == null);
        }).length;
      },
      loading: () => 0,
      error: (_, __) => 0,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(authProvider.notifier).refreshProfile();
        ref.invalidate(dashboardProvider);
        ref.invalidate(lemburListProvider);
        await _fetchCurrentLocation();
      },
      color: primaryColor,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== HERO SECTION =====
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          AppThemeScheme.getLight(dashboardState.value?.generalSetting?.mobileThemeScheme)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Fluid Wave Ornaments
                        Positioned.fill(
                          child: CustomPaint(
                            painter: HeaderWavePainter(),
                          ),
                        ),
                        // Main content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 50, 20, 72),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                      onPressed: () {},
                                    ),
                                  ),
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                                      onPressed: _showLogoutConfirmation,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.name ?? 'Nama Karyawan',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${user?.jabatan ?? "-"} (${user?.departemen ?? "-"})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _currentIndex = 4),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 82,
                                          height: 82,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: 0.15),
                                          ),
                                        ),
                                        Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2.5),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 8,
                                                offset: Offset(0, 3),
                                              )
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: (user?.foto != null && user!.foto!.isNotEmpty)
                                                ? Image.network(
                                                    user.foto!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) => Container(
                                                      color: Colors.grey[200],
                                                      child: Icon(Icons.person, size: 42, color: primaryColor),
                                                    ),
                                                  )
                                                : Container(
                                                    color: Colors.grey[200],
                                                    child: Icon(Icons.person, size: 42, color: primaryColor),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _timeString,
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black12,
                                      offset: Offset(0, 4),
                                      blurRadius: 15,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _dateString,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      _currentLocationName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Dynamic Dashboard Section
              dashboardState.when(
                data: (dashboard) {
                  // Build Active Alerts Slider
                  final alertSlides = _buildAlertSlides(dashboard);
                  final bool hasAlerts = alertSlides.isNotEmpty;
                  final double offset = hasAlerts ? -62.0 : -25.0;

                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Column(
                      children: [
                        // ===== ALERTS SLIDER SECTION =====
                        if (hasAlerts) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 110,
                                  child: PageView(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _activeAlertPage = index;
                                      });
                                    },
                                    children: alertSlides,
                                  ),
                                ),
                                if (alertSlides.length > 1) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      alertSlides.length,
                                      (index) => Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                        width: _activeAlertPage == index ? 18.0 : 6.0,
                                        height: 6.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(3),
                                          color: _activeAlertPage == index
                                              ? primaryColor
                                              : primaryColor.withValues(alpha: 0.2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ===== ATTENDANCE SECTION (Floating/Static Card) =====
                        if (!hasAlerts) const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            child: Row(
                              children: [
                                // In
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey[100]!),
                                          image: (dashboard.attendance?.fotoIn != null)
                                              ? DecorationImage(
                                                  image: NetworkImage(dashboard.attendance!.fotoIn!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: (dashboard.attendance?.fotoIn == null)
                                            ? Icon(Icons.camera_alt_outlined, color: primaryColor, size: 20)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Jam Masuk',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            dashboard.attendance?.jamIn ?? '-- : --',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: dashboard.attendance?.jamIn != null
                                                  ? primaryColor
                                                  : Colors.grey,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider
                                Container(
                                  width: 1.5,
                                  height: 35,
                                  color: Colors.grey[100],
                                ),
                                // Out
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.grey[100]!),
                                            image: (dashboard.attendance?.fotoOut != null)
                                                ? DecorationImage(
                                                    image: NetworkImage(dashboard.attendance!.fotoOut!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: (dashboard.attendance?.fotoOut == null)
                                              ? Icon(Icons.camera_alt_outlined, color: primaryColor, size: 20)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Jam Pulang',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dashboard.attendance?.jamOut ?? '-- : --',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: dashboard.attendance?.jamOut != null
                                                    ? primaryColor
                                                    : Colors.grey,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ===== RECAP SECTION =====
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                )
                              ],
                              border: Border.all(color: Colors.grey[100]!),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            child: Column(
                              children: [
                                Text(
                                  'Rekap Presensi Bulan ${DateFormat('MMMM').format(DateTime.now())}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _buildRecapItem(dashboard.recap.hadir.toString(), 'Hadir', primaryColor),
                                    _buildRecapDivider(),
                                    _buildRecapItem(dashboard.recap.sakit.toString(), 'Sakit', const Color(0xFFFF9800)),
                                    _buildRecapDivider(),
                                    _buildRecapItem(dashboard.recap.izin.toString(), 'Izin', const Color(0xFF2196F3)),
                                    _buildRecapDivider(),
                                    _buildRecapItem(dashboard.recap.cuti.toString(), 'Cuti', const Color(0xFFFF5252)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ===== MENU GRID =====
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: GridView.count(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                            children: [
                              _buildGridMenu(
                                Icons.card_membership_rounded,
                                'ID Card',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const IdCardScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridMenu(
                                Icons.coffee_rounded,
                                'Istirahat',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AbsenIstirahatScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridMenu(
                                Icons.more_time_rounded,
                                'Lembur',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LemburListScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridMenu(
                                Icons.payments_rounded,
                                'Slip Gaji',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SlipGajiListScreen(),
                                    ),
                                  );
                                },
                              ),
                               _buildGridMenu(
                                Icons.trending_up_rounded,
                                'Aktivitas',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AktivitasListScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridMenu(
                                Icons.map_rounded,
                                'Visit',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const KunjunganListScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildGridMenu(
                                Icons.face_retouching_natural_rounded,
                                'Wajah',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FaceRecognitionRegistrationScreen(),
                                    ),
                                  );
                                },
                              ),
                               _buildGridMenu(
                                Icons.grid_view_rounded,
                                'Lainnya',
                                primaryColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LainnyaScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // ===== HISTORY SECTION =====
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _historyActiveTab = 0),
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _historyActiveTab == 0 ? primaryColor : Colors.transparent,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '30 Hari terakhir',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _historyActiveTab == 0 ? Colors.white : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _historyActiveTab = 1),
                                        borderRadius: BorderRadius.circular(30),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _historyActiveTab == 1 ? primaryColor : Colors.transparent,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Lembur',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: _historyActiveTab == 1 ? Colors.white : const Color(0xFF64748B),
                                                ),
                                              ),
                                              if (notifLembur > 0) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: _historyActiveTab == 1 ? Colors.white : Colors.red,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    notifLembur.toString(),
                                                    style: TextStyle(
                                                      color: _historyActiveTab == 1 ? primaryColor : Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              _historyActiveTab == 0 ? _buildPresensiTabContent(dashboard.history, primaryColor) : _buildLemburTabContent(primaryColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(child: CircularProgressIndicator(color: primaryColor)),
                ),
                error: (error, stack) => Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'Gagal memuat data: ${error.toString().replaceAll('Exception: ', '')}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(dashboardProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAlertSlides(DashboardModel dashboard) {
    final List<Widget> slides = [];

    // 1. Contract alert
    if (dashboard.notifKontrak != null) {
      slides.add(_buildAlertCard(
        title: 'Masa Kontrak Segera Berakhir',
        content: 'Sisa masa kontrak Anda adalah ${dashboard.notifKontrak!.sisaHari} hari.\n(Selesai: ${dashboard.notifKontrak!.tanggalAkhir}).',
        subtext: 'Mohon segera koordinasi dengan HRD.',
        icon: Icons.error_outline_rounded,
        bgColor: const Color(0xFFFFF3CD),
        borderColor: const Color(0xFFFFEEBA),
        textColor: const Color(0xFF856404),
        iconColor: const Color(0xFFFFC107),
        iconBgColor: const Color(0x33FFC107),
      ));
    }

    // 2. SP alert
    if (dashboard.notifSp != null) {
      slides.add(_buildAlertCard(
        title: 'Peringatan Disiplin',
        content: 'Status aktif: ${dashboard.notifSp!.jenisSp}.\nBerlaku s/d: ${dashboard.notifSp!.sampai}.',
        subtext: 'Tetap jaga profesionalisme kerja Anda.',
        icon: Icons.warning_amber_rounded,
        bgColor: const Color(0xFFF8D7DA),
        borderColor: const Color(0xFFF5C6CB),
        textColor: const Color(0xFF721C24),
        iconColor: const Color(0xFFDC3545),
        iconBgColor: const Color(0x33DC3545),
      ));
    }

    // 3. Announcement alert
    if (dashboard.announcement != null) {
      slides.add(_buildAlertCard(
        title: dashboard.announcement!.judul,
        content: dashboard.announcement!.isi,
        subtext: dashboard.announcement!.createdAt,
        icon: Icons.campaign_rounded,
        bgColor: const Color(0xFFE3F2FD),
        borderColor: const Color(0xFFB8DAFF),
        textColor: const Color(0xFF0C5460),
        iconColor: const Color(0xFF007BFF),
        iconBgColor: const Color(0x33007BFF),
      ));
    }

    if (_totalAlertPages != slides.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _totalAlertPages = slides.length;
          });
        }
      });
    }

    return slides;
  }

  Widget _buildAlertCard({
    required String title,
    required String content,
    required String subtext,
    required IconData icon,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 9,
                    color: textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapItem(String count, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecapDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildGridMenu(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menu $label belum tersedia.')),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresensiTabContent(List<RiwayatModel> history, Color primaryColor) {
    if (history.isEmpty) {
      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.calendar_today_rounded, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                const Text(
                  'Belum Ada Histori Presensi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Data kehadiran Anda dalam 30 hari terakhir akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final item = history[index];
        
        DateTime parsedDate = DateTime.tryParse(item.tanggal) ?? DateTime.now();
        String dayShort = DateFormat('EEE').format(parsedDate).toUpperCase();
        String dateDay = DateFormat('dd').format(parsedDate);
        String dateFull = DateFormat('dd MMMM yyyy').format(parsedDate);

        Color statusColor = primaryColor;
        Color bgColor = primaryColor.withOpacity(0.08);
        String statusLabel = item.keterangan ?? 'Hadir';

        if (item.status == 'i') {
          statusColor = const Color(0xFF2196F3);
          bgColor = const Color(0xFF2196F3).withOpacity(0.08);
        } else if (item.status == 's') {
          statusColor = const Color(0xFFFF5252);
          bgColor = const Color(0xFFFF5252).withOpacity(0.08);
        } else if (item.status == 'c') {
          statusColor = const Color(0xFFFF9800);
          bgColor = const Color(0xFFFF9800).withOpacity(0.08);
        } else if (item.status == 'a') {
          statusColor = Colors.red;
          bgColor = Colors.red.withOpacity(0.08);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayShort,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      dateDay,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: statusColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateFull,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Text(
                            item.namaJamKerja.isNotEmpty ? item.namaJamKerja : 'NON SHIFT',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (item.status == 'h') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.jamIn ?? "--:--"}  -  ${item.jamOut ?? "--:--"}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555555),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              if (item.jamIn == null) {
                                return const SizedBox.shrink();
                              }
                              try {
                                final inTime = DateFormat('HH:mm').parse(item.jamIn!);
                                final limitTime = DateFormat('HH:mm').parse(item.jamMasuk);
                                if (inTime.isAfter(limitTime)) {
                                  final diff = inTime.difference(limitTime).inMinutes;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'Telat ${diff}m',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  );
                                }
                              } catch (_) {}
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Tepat Waktu',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLemburTabContent(Color primaryColor) {
    final lemburListAsync = ref.watch(lemburListProvider);

    return lemburListAsync.when(
      data: (lemburList) {
        if (lemburList.isEmpty) {
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.more_time_rounded, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Pengajuan Lembur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Histori lembur Anda akan muncul di sini setelah diajukan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        String formatDate(String dateStr) {
          try {
            final date = DateTime.parse(dateStr);
            return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
          } catch (_) {
            return dateStr;
          }
        }

        String formatTime(String? dateTimeStr) {
          if (dateTimeStr == null) return '-';
          try {
            if (dateTimeStr.length == 5 && dateTimeStr.contains(':')) {
              return dateTimeStr;
            }
            final date = DateTime.parse(dateTimeStr);
            return DateFormat('HH:mm').format(date);
          } catch (_) {
            return dateTimeStr;
          }
        }

        Widget getStatusChip(int status) {
          String label = 'Pending';
          Color bgColor = Colors.amber.shade50;
          Color textColor = Colors.amber.shade800;

          if (status == 1) {
            label = 'Disetujui';
            bgColor = Colors.green.shade50;
            textColor = Colors.green.shade700;
          } else if (status == 2) {
            label = 'Ditolak';
            bgColor = Colors.red.shade50;
            textColor = Colors.red.shade700;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        Widget buildTimeInfo(String label, String value, IconData icon) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        Widget buildActionButton(int idLembur, String? lemburIn, String? lemburOut) {
          if (lemburIn == null) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LemburPresensiScreen(
                        idLembur: idLembur,
                        status: 1,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(lemburListProvider);
                    ref.invalidate(dashboardProvider);
                  }
                },
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Mulai Lembur (Absen Masuk)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            );
          } else if (lemburOut == null) {
            return SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LemburPresensiScreen(
                        idLembur: idLembur,
                        status: 2,
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(lemburListProvider);
                    ref.invalidate(dashboardProvider);
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Selesai Lembur (Absen Pulang)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            );
          } else {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Lembur Selesai & Tercatat',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            );
          }
        }

        return Column(
          children: lemburList.map((item) {
            final int status = int.tryParse(item['status']?.toString() ?? '0') ?? 0;
            final int idLembur = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
            final String? lemburIn = item['lembur_in'];
            final String? lemburOut = item['lembur_out'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[100]!),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatDate(item['tanggal']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        getStatusChip(status),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: buildTimeInfo(
                            'Rencana Jam',
                            '${formatTime(item['lembur_mulai'])} - ${formatTime(item['lembur_selesai'])}',
                            Icons.schedule_outlined,
                          ),
                        ),
                        Expanded(
                          child: buildTimeInfo(
                            'Realisasi Jam',
                            '${formatTime(lemburIn)} - ${formatTime(lemburOut)}',
                            Icons.play_circle_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    buildTimeInfo(
                      'Keterangan / Tugas',
                      item['keterangan'] ?? '-',
                      Icons.description_outlined,
                    ),
                    if (status == 1) ...[
                      const SizedBox(height: 16),
                      buildActionButton(idLembur, lemburIn, lemburOut),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: primaryColor)),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Gagal memuat data lembur: $err',
          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, Color primaryColor) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: primaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Halaman $title',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Halaman ini sedang dalam tahap pengembangan.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Wave 1 (Upper Wave)
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.9,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Wave 2 (Lower Wave)
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.9,
        size.width * 0.6,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.5,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color parseHexColor(String? hexString, Color defaultColor) {
  if (hexString == null || hexString.isEmpty) return defaultColor;
  try {
    String formatted = hexString.replaceAll('#', '');
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
  } catch (_) {
    return defaultColor;
  }
}

