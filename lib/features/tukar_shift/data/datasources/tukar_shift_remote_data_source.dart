import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/tukar_shift/data/models/tukar_shift_model.dart';

abstract class TukarShiftRemoteDataSource {
  Future<TukarShiftResponseModel> getTukarShiftData();
  Future<void> submitTukarShift({
    required String tanggal,
    required String kodeJamKerjaTujuan,
    required String keterangan,
  });
  Future<void> cancelTukarShift(int id);
}

class TukarShiftRemoteDataSourceImpl implements TukarShiftRemoteDataSource {
  final Dio _dio;

  TukarShiftRemoteDataSourceImpl(this._dio);

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
  Future<TukarShiftResponseModel> getTukarShiftData() async {
    try {
      final response = await _dio.get('/tukarshift');
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
        if (data['success'] == true) {
          return TukarShiftResponseModel.fromJson(Map<String, dynamic>.from(data['data']));
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data tukar shift');
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
  Future<void> submitTukarShift({
    required String tanggal,
    required String kodeJamKerjaTujuan,
    required String keterangan,
  }) async {
    try {
      final response = await _dio.post(
        '/tukarshift',
        data: {
          'tanggal': tanggal,
          'kode_jam_kerja_tujuan': kodeJamKerjaTujuan,
          'keterangan': keterangan,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = _parseResponseData(response.data);
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
  Future<void> cancelTukarShift(int id) async {
    try {
      final response = await _dio.delete('/tukarshift/$id');
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

final tukarShiftRemoteDataSourceProvider = Provider<TukarShiftRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return TukarShiftRemoteDataSourceImpl(dio);
});
