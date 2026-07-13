import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/jadwal/data/models/jadwal_model.dart';

abstract class JadwalRemoteDataSource {
  Future<List<JadwalModel>> getJadwalList({String? bulan, String? tahun});
}

class JadwalRemoteDataSourceImpl implements JadwalRemoteDataSource {
  final Dio _dio;

  JadwalRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _parseResponseData(dynamic rawData) {
    if (rawData == null) {
      throw Exception('Data response kosong');
    }
    if (rawData is String) {
      return jsonDecode(rawData) as Map<String, dynamic>;
    } else if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    } else {
      throw Exception('Format response data tidak valid');
    }
  }

  @override
  Future<List<JadwalModel>> getJadwalList({String? bulan, String? tahun}) async {
    try {
      final response = await _dio.get(
        '/jadwal',
        queryParameters: {
          if (bulan != null) 'bulan': bulan,
          if (tahun != null) 'tahun': tahun,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List? ?? [];
          return list.map((e) => JadwalModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data jadwal');
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

final jadwalRemoteDataSourceProvider = Provider<JadwalRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return JadwalRemoteDataSourceImpl(dio);
});
