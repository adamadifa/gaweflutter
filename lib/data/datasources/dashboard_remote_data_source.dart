import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/data/models/dashboard_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> getDashboard();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final Dio _dio;

  DashboardRemoteDataSourceImpl(this._dio);

  @override
  Future<DashboardModel> getDashboard() async {
    try {
      final response = await _dio.get('/dashboard');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return DashboardModel.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat data dashboard');
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

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DashboardRemoteDataSourceImpl(dio);
});
