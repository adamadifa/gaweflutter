import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/pelanggaran/data/models/pelanggaran_model.dart';

abstract class PelanggaranRemoteDataSource {
  Future<List<PelanggaranModel>> getViolations();
  Future<PelanggaranDetailModel> getViolationDetail(String noSp);
}

class PelanggaranRemoteDataSourceImpl implements PelanggaranRemoteDataSource {
  final Dio _dio;

  PelanggaranRemoteDataSourceImpl(this._dio);

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
  Future<List<PelanggaranModel>> getViolations() async {
    try {
      final response = await _dio.get('/pelanggaran');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List;
          return list.map((e) => PelanggaranModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat daftar pelanggaran');
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
  Future<PelanggaranDetailModel> getViolationDetail(String noSp) async {
    try {
      final response = await _dio.get('/pelanggaran/$noSp');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return PelanggaranDetailModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail pelanggaran');
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

final pelanggaranRemoteDataSourceProvider = Provider<PelanggaranRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PelanggaranRemoteDataSourceImpl(dio);
});
