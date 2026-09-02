import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/pengumuman/data/models/pengumuman_model.dart';

abstract class PengumumanRemoteDataSource {
  Future<List<PengumumanModel>> getPengumumanList({String? search});
  Future<PengumumanModel> getPengumumanDetail(int id);
}

class PengumumanRemoteDataSourceImpl implements PengumumanRemoteDataSource {
  final Dio _dio;

  PengumumanRemoteDataSourceImpl(this._dio);

  Map<String, dynamic> _parseResponseData(dynamic rawData) {
    if (rawData == null) {
      throw Exception('Data response kosong');
    }
    if (rawData is String) {
      return jsonDecode(rawData) as Map<String, dynamic>;
    } else if (rawData is Map) {
      return Map<String, dynamic>.from(rawData);
    } else {
      throw Exception('Format response tidak dikenali: ${rawData.runtimeType}');
    }
  }

  @override
  Future<List<PengumumanModel>> getPengumumanList({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _dio.get(
        '/pengumuman',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final respData = _parseResponseData(response.data);
      if (respData['success'] == true && respData['data'] is List) {
        return (respData['data'] as List)
            .map((item) => PengumumanModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Gagal memuat pengumuman';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<PengumumanModel> getPengumumanDetail(int id) async {
    try {
      final response = await _dio.get('/pengumuman/$id');
      final respData = _parseResponseData(response.data);

      if (respData['success'] == true && respData['data'] != null) {
        return PengumumanModel.fromJson(respData['data'] as Map<String, dynamic>);
      }
      throw Exception('Pengumuman tidak ditemukan');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Gagal memuat detail pengumuman';
      throw Exception(msg);
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}

final pengumumanRemoteDataSourceProvider = Provider<PengumumanRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PengumumanRemoteDataSourceImpl(dio);
});
