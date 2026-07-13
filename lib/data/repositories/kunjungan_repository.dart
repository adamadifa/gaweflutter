import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';

abstract class KunjunganRepository {
  Future<Map<String, dynamic>> getKunjunganList({String? tanggalAwal, String? tanggalAkhir});
  Future<Map<String, dynamic>> submitKunjungan({
    required String deskripsi,
    required String lokasi, // "lat,lng"
    required String imagePath,
    required String tanggalKunjungan, // "yyyy-MM-dd"
  });
}

class KunjunganRepositoryImpl implements KunjunganRepository {
  final Dio _dio;

  KunjunganRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getKunjunganList({String? tanggalAwal, String? tanggalAkhir}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (tanggalAwal != null) queryParams['tanggal_awal'] = tanggalAwal;
      if (tanggalAkhir != null) queryParams['tanggal_akhir'] = tanggalAkhir;

      final response = await _dio.get('/kunjungan', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    }
  }

  @override
  Future<Map<String, dynamic>> submitKunjungan({
    required String deskripsi,
    required String lokasi,
    required String imagePath,
    required String tanggalKunjungan,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final file = await MultipartFile.fromFile(imagePath, filename: fileName);

      final formData = FormData.fromMap({
        'deskripsi': deskripsi,
        'lokasi': lokasi,
        'tanggal_kunjungan': tanggalKunjungan,
        'image': file,
      });

      final response = await _dio.post('/kunjungan', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        return response.data;
      }
      throw Exception('Server error: ${response.statusCode}');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    }
  }
}

final kunjunganRepositoryProvider = Provider<KunjunganRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return KunjunganRepositoryImpl(dio);
});
