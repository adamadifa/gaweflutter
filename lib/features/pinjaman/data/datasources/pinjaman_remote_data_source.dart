import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/pinjaman/data/models/pinjaman_model.dart';

abstract class PinjamanRemoteDataSource {
  Future<PinjamanSummaryModel> getPinjamanSummary();
}

class PinjamanRemoteDataSourceImpl implements PinjamanRemoteDataSource {
  final Dio _dio;

  PinjamanRemoteDataSourceImpl(this._dio);

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
  Future<PinjamanSummaryModel> getPinjamanSummary() async {
    try {
      final response = await _dio.get('/pinjaman');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return PinjamanSummaryModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data pinjaman');
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

final pinjamanRemoteDataSourceProvider = Provider<PinjamanRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return PinjamanRemoteDataSourceImpl(dio);
});
