import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';

abstract class AktivitasRepository {
  Future<Map<String, dynamic>> getAktivitasList({String? tanggalAwal, String? tanggalAkhir});
  Future<Map<String, dynamic>> submitAktivitas({
    required String aktivitas,
    required String lokasi, // "lat,lng"
    required String imagePath,
  });
  Future<Map<String, dynamic>> deleteAktivitas(int id);
}

class AktivitasRepositoryImpl implements AktivitasRepository {
  final Dio _dio;

  AktivitasRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getAktivitasList({String? tanggalAwal, String? tanggalAkhir}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (tanggalAwal != null) queryParams['tanggal_awal'] = tanggalAwal;
      if (tanggalAkhir != null) queryParams['tanggal_akhir'] = tanggalAkhir;

      final response = await _dio.get('/aktivitas', queryParameters: queryParams);
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
  Future<Map<String, dynamic>> submitAktivitas({
    required String aktivitas,
    required String lokasi,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final file = await MultipartFile.fromFile(imagePath, filename: fileName);

      final formData = FormData.fromMap({
        'aktivitas': aktivitas,
        'lokasi': lokasi,
        'image': file,
      });

      final response = await _dio.post('/aktivitas', data: formData);
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
  Future<Map<String, dynamic>> deleteAktivitas(int id) async {
    try {
      final response = await _dio.delete('/aktivitas/$id');
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

final aktivitasRepositoryProvider = Provider<AktivitasRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AktivitasRepositoryImpl(dio);
});
