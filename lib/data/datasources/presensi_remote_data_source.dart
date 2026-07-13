import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/data/models/riwayat_model.dart';

abstract class PresensiRemoteDataSource {
  Future<Map<String, dynamic>> absenMasuk({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  });

  Future<Map<String, dynamic>> absenPulang({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  });

  Future<Map<String, dynamic>> absenIstirahat({
    required String lokasi,
    required String status,
    required String kodeJamKerja,
    required String imagePath,
  });

  Future<List<RiwayatModel>> getRiwayat({
    required int bulan,
    required int tahun,
  });
}

class PresensiRemoteDataSourceImpl implements PresensiRemoteDataSource {
  final Dio _dio;

  PresensiRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> absenMasuk({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'lokasi': lokasi,
        'kode_jam_kerja': kodeJamKerja,
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });

      final response = await _dio.post('/presensi/masuk', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Gagal absen masuk');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> absenPulang({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'lokasi': lokasi,
        'kode_jam_kerja': kodeJamKerja,
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });

      final response = await _dio.post('/presensi/pulang', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Gagal absen pulang');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> absenIstirahat({
    required String lokasi,
    required String status,
    required String kodeJamKerja,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'lokasi': lokasi,
        'status': status,
        'kode_jam_kerja': kodeJamKerja,
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });

      final response = await _dio.post('/presensi/istirahat', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'Gagal absen istirahat');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<List<RiwayatModel>> getRiwayat({
    required int bulan,
    required int tahun,
  }) async {
    try {
      final response = await _dio.get('/presensi/riwayat', queryParameters: {
        'bulan': bulan,
        'tahun': tahun,
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((item) => RiwayatModel.fromJson(item)).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat riwayat');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final presensiRemoteDataSourceProvider = Provider<PresensiRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PresensiRemoteDataSourceImpl(dio);
});
