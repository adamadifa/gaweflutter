import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/kpi/data/models/kpi_model.dart';

abstract class KpiRemoteDataSource {
  Future<KpiResponseModel> getMyKpiScore();
  Future<void> submitRealisasi({
    required int kpiId,
    required List<Map<String, dynamic>> realisasi,
  });
}

class KpiRemoteDataSourceImpl implements KpiRemoteDataSource {
  final Dio _dio;

  KpiRemoteDataSourceImpl(this._dio);

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
  Future<KpiResponseModel> getMyKpiScore() async {
    try {
      final response = await _dio.get('/kpi/myscore');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return KpiResponseModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data KPI');
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
  Future<void> submitRealisasi({
    required int kpiId,
    required List<Map<String, dynamic>> realisasi,
  }) async {
    try {
      final response = await _dio.post(
        '/kpi/input-realisasi',
        data: {
          'kpi_id': kpiId,
          'realisasi': realisasi,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Gagal menyimpan realisasi');
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

final kpiRemoteDataSourceProvider = Provider<KpiRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return KpiRemoteDataSourceImpl(dio);
});
