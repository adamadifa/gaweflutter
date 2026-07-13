import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<UserModel> getProfile();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _dio.post('/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'token': data['token'],
            'user': UserModel.fromJson(data['user']),
          };
        } else {
          throw Exception(data['message'] ?? 'Login gagal');
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
  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Terjadi kesalahan koneksi saat logout';
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return UserModel.fromJson(data['user']);
        } else {
          throw Exception(data['message'] ?? 'Gagal mengambil profil');
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

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSourceImpl(dio);
});
