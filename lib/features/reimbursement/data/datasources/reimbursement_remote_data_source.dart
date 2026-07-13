import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/reimbursement/data/models/reimbursement_model.dart';

class ReimbursementSubmitItem {
  final String kategori;
  final double jumlah;
  final String keterangan;
  final String? filePath;

  ReimbursementSubmitItem({
    required this.kategori,
    required this.jumlah,
    required this.keterangan,
    this.filePath,
  });
}

abstract class ReimbursementRemoteDataSource {
  Future<List<ReimbursementModel>> getReimbursements();
  Future<List<ReimbursementCategoryModel>> getCategories();
  Future<ReimbursementFullDetailModel> getReimbursementDetail(int id);
  Future<void> submitReimbursement({
    required String tanggal,
    required String keterangan,
    required List<ReimbursementSubmitItem> items,
  });
  Future<void> deleteReimbursement(int id);
}

class ReimbursementRemoteDataSourceImpl implements ReimbursementRemoteDataSource {
  final Dio _dio;

  ReimbursementRemoteDataSourceImpl(this._dio);

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
  Future<List<ReimbursementModel>> getReimbursements() async {
    try {
      final response = await _dio.get('/reimbursement');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List;
          return list.map((e) => ReimbursementModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat riwayat reimbursement');
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
  Future<List<ReimbursementCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get('/reimbursement/categories');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          final list = data['data'] as List;
          return list.map((e) => ReimbursementCategoryModel.fromJson(Map<String, dynamic>.from(e))).toList();
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat kategori reimbursement');
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
  Future<ReimbursementFullDetailModel> getReimbursementDetail(int id) async {
    try {
      final response = await _dio.get('/reimbursement/$id');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return ReimbursementFullDetailModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat detail reimbursement');
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
  Future<void> submitReimbursement({
    required String tanggal,
    required String keterangan,
    required List<ReimbursementSubmitItem> items,
  }) async {
    try {
      final Map<String, dynamic> map = {
        'tanggal': tanggal,
        'keterangan': keterangan,
      };

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        map['items[$i][item_kategori]'] = item.kategori;
        map['items[$i][item_jumlah]'] = item.jumlah;
        map['items[$i][item_keterangan]'] = item.keterangan;
        
        if (item.filePath != null && item.filePath!.isNotEmpty) {
          map['items[$i][item_foto]'] = await MultipartFile.fromFile(
            item.filePath!,
            filename: item.filePath!.split('/').last,
          );
        }
      }

      final formData = FormData.fromMap(map);

      final response = await _dio.post(
        '/reimbursement',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Gagal mengirim pengajuan reimbursement');
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
  Future<void> deleteReimbursement(int id) async {
    try {
      final response = await _dio.delete('/reimbursement/$id');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
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

final reimbursementRemoteDataSourceProvider = Provider<ReimbursementRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ReimbursementRemoteDataSourceImpl(dio);
});
