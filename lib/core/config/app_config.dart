import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gaweflutter/core/constants/app_constants.dart';
import 'package:gaweflutter/core/storage/secure_storage.dart';

class AppConfig {
  AppConfig._();

  static bool _isInitialized = false;

  /// Inisialisasi konfigurasi .env saat aplikasi pertama kali dijalankan
  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await dotenv.load(fileName: ".env");
      _isInitialized = true;
      if (kDebugMode) {
        print('[AppConfig] .env loaded successfully');
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print('[AppConfig] Note: .env not loaded ($e), using dynamic server mode.');
      }
    }
  }

  /// Mengecek apakah aplikasi menggunakan Server Statis dari .env
  /// (Misal: pembeli membeli Source Code Flutter dan mengeset BASE_URL di .env)
  static bool get isStaticServer {
    if (!_isInitialized) return false;
    final requireConfig = dotenv.maybeGet('REQUIRE_SERVER_CONFIG')?.trim().toLowerCase();
    final baseUrl = dotenv.maybeGet('BASE_URL')?.trim() ?? '';
    
    // Jika REQUIRE_SERVER_CONFIG = false dan BASE_URL diisi
    return requireConfig == 'false' && baseUrl.isNotEmpty;
  }

  /// Mendapatkan Base URL yang dikonfigurasi secara statis dari .env
  static String? get staticBaseUrl {
    if (!isStaticServer) return null;
    final rawUrl = dotenv.get('BASE_URL').trim();
    return formatBaseUrl(rawUrl);
  }

  /// Mendapatkan URL server aktif saat ini
  /// Prioritas:
  /// 1. Jika mode statis dari .env aktif -> gunakan URL dari .env
  /// 2. Jika mode dinamis -> gunakan URL tersimpan di SecureStorage
  /// 3. Jika belum disetel -> null
  static Future<String?> getBaseUrl() async {
    if (isStaticServer) {
      return staticBaseUrl;
    }

    final savedUrl = await SecureStorage.read(AppConstants.keyServerUrl);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      return formatBaseUrl(savedUrl.trim());
    }

    return null;
  }

  /// Mengecek apakah endpoint server sudah siap digunakan
  static Future<bool> isServerConfigured() async {
    final url = await getBaseUrl();
    return url != null && url.isNotEmpty;
  }

  /// Menyimpan URL server custom ke penyimpanan aman perangkat
  static Future<void> saveServerUrl(String rawUrl) async {
    final formatted = formatBaseUrl(rawUrl);
    await SecureStorage.write(AppConstants.keyServerUrl, formatted);
  }

  /// Menghapus URL server custom
  static Future<void> clearServerUrl() async {
    await SecureStorage.delete(AppConstants.keyServerUrl);
  }

  /// Memformat input URL agar selalu memiliki protocol dan path endpoint `/api/mobile`
  static String formatBaseUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return '';

    // 1. Tambahkan prefix protocol jika belum ada
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Jika IP local / localhost -> default ke http, jika domain -> default ke https
      if (url.contains('localhost') ||
          url.contains('10.0.2.2') ||
          url.startsWith('192.168.') ||
          url.startsWith('10.') ||
          url.startsWith('172.')) {
        url = 'http://$url';
      } else {
        url = 'https://$url';
      }
    }

    // 2. Hapus trailing slash di akhir
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    // 3. Pastikan mengarah ke /api/mobile
    if (url.endsWith('/api/mobile')) {
      return url;
    } else if (url.endsWith('/api')) {
      return '$url/mobile';
    } else {
      return '$url/api/mobile';
    }
  }

  /// Mendapatkan Root URL / Host URL tanpa path `/api/mobile` (berguna untuk asset public)
  static String getRootUrlFromBaseUrl(String baseUrl) {
    var url = baseUrl.replaceAll('/api/mobile', '').replaceAll('/api', '');
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Mendapatkan format tampilan URL yang bersih untuk input form pengguna
  static String getDisplayUrl(String fullUrl) {
    return getRootUrlFromBaseUrl(fullUrl);
  }

  /// Menguji konektivitas ke URL server Laravel presensigpsv2
  static Future<({bool success, String message, int? latencyMs})> testConnection(
      String rawUrl) async {
    final formattedUrl = formatBaseUrl(rawUrl);
    if (formattedUrl.isEmpty) {
      return (
        success: false,
        message: 'Alamat URL server tidak boleh kosong.',
        latencyMs: null,
      );
    }

    final stopwatch = Stopwatch()..start();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 7),
        receiveTimeout: const Duration(seconds: 7),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    try {
      // Tes ping ke endpoint auth/login mobile Laravel presensigpsv2
      final response = await dio.post(
        '$formattedUrl/login',
        data: {'username': '', 'password': ''},
        options: Options(
          validateStatus: (status) => true, // Terima semua status code HTTP
        ),
      );
      stopwatch.stop();

      // Kode status HTTP 422 (Unprocessable / Validation error) atau 200 atau 400
      // menandakan server Laravel dan routing /api/mobile/login aktif dan merespons!
      if (response.statusCode == 422 ||
          response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401) {
        return (
          success: true,
          message: 'Server terhubung dan siap digunakan!',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } else if (response.statusCode == 404) {
        return (
          success: false,
          message:
              'Server merespons (404 Not Found). Pastikan backend Laravel presensigpsv2 sudah terpasang dengan benar.',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        return (
          success: true,
          message: 'Server terhubung (Status: ${response.statusCode})',
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
    } on DioException catch (e) {
      stopwatch.stop();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return (
          success: false,
          message:
              'Koneksi waktu habis (Timeout). Pastikan server aktif dan dapat diakses dari jaringan ini.',
          latencyMs: null,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        return (
          success: false,
          message:
              'Gagal terhubung ke server. Periksa kembali alamat IP / Domain dan port server.',
          latencyMs: null,
        );
      } else {
        return (
          success: false,
          message: 'Gagal terhubung: ${e.message ?? 'Kesalahan jaringan'}',
          latencyMs: null,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return (
        success: false,
        message: 'Gagal menghubungi server: $e',
        latencyMs: null,
      );
    }
  }
}
