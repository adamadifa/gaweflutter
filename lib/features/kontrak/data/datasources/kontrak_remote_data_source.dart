import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/kontrak/data/models/kontrak_model.dart';

abstract class KontrakRemoteDataSource {
  Future<List<KontrakModel>> getContracts();
  Future<KontrakDetailModel> getContractDetail(int id);
  Future<Uint8List> downloadContractPdf(int id);
}

class KontrakRemoteDataSourceImpl implements KontrakRemoteDataSource {
  final Dio _dio;

  KontrakRemoteDataSourceImpl(this._dio);

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
  Future<List<KontrakModel>> getContracts() async {
    try {
      final response = await _dio.get('/kontrak');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List;
          return list.map((e) => KontrakModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat daftar kontrak');
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
  Future<KontrakDetailModel> getContractDetail(int id) async {
    try {
      final response = await _dio.get('/kontrak/$id');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return KontrakDetailModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail kontrak');
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
  Future<Uint8List> downloadContractPdf(int id) async {
    try {
      final response = await _dio.get(
        '/kontrak/$id/download',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data as List<int>);
      } else {
        throw Exception('Gagal mendownload PDF kontrak');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Terjadi kesalahan koneksi saat download PDF');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final kontrakRemoteDataSourceProvider = Provider<KontrakRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return KontrakRemoteDataSourceImpl(dio);
});
