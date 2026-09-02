import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/features/approval/data/models/approval_model.dart';

class ApprovalRepository {
  final Dio _dio;

  ApprovalRepository(this._dio);

  Future<ApprovalResponseData> getApprovalList() async {
    try {
      final response = await _dio.get('/approval');
      if (response.data['success'] == true) {
        return ApprovalResponseData.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat data approval');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan jaringan';
      throw Exception(msg);
    }
  }

  Future<ApprovalItem> getApprovalDetail(String type, String kode) async {
    try {
      final response = await _dio.get('/approval/detail/$type/$kode');
      if (response.data['success'] == true && response.data['data'] != null) {
        return ApprovalItem.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memuat rincian approval');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan jaringan';
      throw Exception(msg);
    }
  }

  Future<String> processApproval({
    required String type,
    required String kode,
    required String action, // 'approve' or 'tolak'
    String? catatan,
  }) async {
    try {
      final response = await _dio.post(
        '/approval/$type/$kode',
        data: {
          'action': action,
          'catatan': catatan,
        },
      );

      if (response.data['success'] == true) {
        return response.data['message'] ?? 'Berhasil memproses pengajuan';
      } else {
        throw Exception(response.data['message'] ?? 'Gagal memproses pengajuan');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan saat memproses';
      throw Exception(msg);
    }
  }
}

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return ApprovalRepository(dio);
});
