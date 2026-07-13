import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/slip_gaji/data/models/slip_gaji_model.dart';

abstract class SlipGajiRemoteDataSource {
  Future<List<SlipGajiPeriod>> getSlipGajiPeriods();
  Future<SlipGajiDetail> getSlipGajiDetail(int bulan, int tahun);
}

class SlipGajiRemoteDataSourceImpl implements SlipGajiRemoteDataSource {
  final Dio _dio;

  SlipGajiRemoteDataSourceImpl(this._dio);

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
  Future<List<SlipGajiPeriod>> getSlipGajiPeriods() async {
    try {
      final response = await _dio.get('/slipgaji');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List;
          return list.map((e) => SlipGajiPeriod.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat daftar slip gaji');
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
  Future<SlipGajiDetail> getSlipGajiDetail(int bulan, int tahun) async {
    try {
      final response = await _dio.get('/slipgaji/$bulan/$tahun');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return SlipGajiDetail.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail slip gaji');
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

final slipGajiRemoteDataSourceProvider = Provider<SlipGajiRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return SlipGajiRemoteDataSourceImpl(dio);
});
