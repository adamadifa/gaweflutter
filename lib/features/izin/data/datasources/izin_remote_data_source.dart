import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/izin/data/models/izin_model.dart';

abstract class IzinRemoteDataSource {
  Future<List<IzinModel>> getIzinList();
  Future<void> submitIzin({
    required String jenisIzin,
    required String dari,
    required String sampai,
    required String keterangan,
    String? sidPath,
  });
  Future<void> cancelIzin(String kode);
}

class IzinRemoteDataSourceImpl implements IzinRemoteDataSource {
  final Dio _dio;

  IzinRemoteDataSourceImpl(this._dio);

  @override
  Future<List<IzinModel>> getIzinList() async {
    try {
      final response = await _dio.get('/izin');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          final List<dynamic> listJson = data['data'] ?? [];
          return listJson.map((e) => IzinModel.fromJson(e)).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil data pengajuan');
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
  Future<void> submitIzin({
    required String jenisIzin,
    required String dari,
    required String sampai,
    required String keterangan,
    String? sidPath,
  }) async {
    try {
      Map<String, dynamic> fields = {
        'jenis_izin': jenisIzin,
        'dari': dari,
        'sampai': sampai,
        'keterangan': keterangan,
      };

      if (sidPath != null && sidPath.isNotEmpty) {
        final fileName = sidPath.split('/').last;
        fields['sid'] = await MultipartFile.fromFile(sidPath, filename: fileName);
      }

      final formData = FormData.fromMap(fields);

      final response = await _dio.post('/izin', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Gagal mengirim pengajuan');
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
  Future<void> cancelIzin(String kode) async {
    try {
      final response = await _dio.delete('/izin/$kode');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Gagal membatalkan pengajuan');
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

final izinRemoteDataSourceProvider = Provider<IzinRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return IzinRemoteDataSourceImpl(dio);
});
