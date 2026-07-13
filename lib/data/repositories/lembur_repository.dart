import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';

abstract class LemburRepository {
  Future<Map<String, dynamic>> getLemburList();
  Future<Map<String, dynamic>> requestLembur({
    required String dari,
    required String sampai,
    required String keterangan,
  });
  Future<Map<String, dynamic>> absenLembur({
    required int idLembur,
    required int status, // 1 = masuk, 2 = pulang
    required String lokasi,
    required String imagePath,
  });
}

class LemburRepositoryImpl implements LemburRepository {
  final Dio _dio;

  LemburRepositoryImpl(this._dio);

  @override
  Future<Map<String, dynamic>> getLemburList() async {
    try {
      final response = await _dio.get('/lembur');
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
  Future<Map<String, dynamic>> requestLembur({
    required String dari,
    required String sampai,
    required String keterangan,
  }) async {
    try {
      final response = await _dio.post('/lembur', data: {
        'dari': dari,
        'sampai': sampai,
        'keterangan': keterangan,
      });
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
  Future<Map<String, dynamic>> absenLembur({
    required int idLembur,
    required int status,
    required String lokasi,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final file = await MultipartFile.fromFile(imagePath, filename: fileName);

      final formData = FormData.fromMap({
        'id_lembur': idLembur,
        'status': status,
        'lokasi': lokasi,
        'image': file,
      });

      final response = await _dio.post('/lembur/absen', data: formData);
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

final lemburRepositoryProvider = Provider<LemburRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LemburRepositoryImpl(dio);
});
