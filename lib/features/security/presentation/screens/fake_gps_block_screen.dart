import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/services/mock_location_service.dart';

class FakeGpsBlockScreen extends ConsumerStatefulWidget {
  const FakeGpsBlockScreen({super.key});

  @override
  ConsumerState<FakeGpsBlockScreen> createState() => _FakeGpsBlockScreenState();
}

class _FakeGpsBlockScreenState extends ConsumerState<FakeGpsBlockScreen> {
  bool _isChecking = false;

  Future<void> _recheckGps() async {
    setState(() {
      _isChecking = true;
    });

    final mockService = ref.read(mockLocationServiceProvider);
    final isMock = await mockService.checkIsMockLocation();

    if (mounted) {
      setState(() {
        _isChecking = false;
      });

      if (!isMock) {
        ref.read(isMockLocationDetectedProvider.notifier).setDetected(false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fake GPS masih aktif. Harap nonaktifkan aplikasi / mock location Anda.'),
            backgroundColor: Color(0xFFDC2626),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Warning Icon Container with soft pulse border
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    size: 72,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Terdeteksi Fake GPS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                // Description
                const Text(
                  'Aplikasi mendeteksi penggunaan Fake GPS atau Lokasi Tiruan (Mock Location). Demi keamanan dan akurasi presensi, aplikasi tidak dapat dibuka.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Instruction Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF334155), width: 1.15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                          SizedBox(width: 8),
                          Text(
                            'Langkah Penyelesaian:',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildStepItem('1', 'Tutup aplikasi Fake GPS / Mock Location.'),
                      const SizedBox(height: 6),
                      _buildStepItem('2', 'Buka Pengaturan HP > Opsi Pengembang (Developer Options).'),
                      const SizedBox(height: 6),
                      _buildStepItem('3', 'Nonaktifkan "Pilih Aplikasi Lokasi Palsu" (Select Mock Location App).'),
                    ],
                  ),
                ),

                const Spacer(),

                // Recheck Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _recheckGps,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      _isChecking ? 'Memeriksa Lokasi...' : 'Periksa Ulang Lokasi',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Exit App Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      } else {
                        exit(0);
                      }
                    },
                    icon: const Icon(Icons.power_settings_new_rounded, size: 16, color: Color(0xFF94A3B8)),
                    label: const Text(
                      'Keluar Aplikasi',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF334155), width: 1.15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            number,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1), height: 1.35),
          ),
        ),
      ],
    );
  }
}
