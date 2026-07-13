import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/network/dio_client.dart';
import 'package:gaweflutter/data/models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<void> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  });
  Future<String> updateFoto(String filePath);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final Dio _dio;

  ProfileRemoteDataSourceImpl(this._dio);

  @override
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dio.get('/profile');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return ProfileModel.fromJson(data['user']);
        } else {
          throw Exception(data['message'] ?? 'Gagal memuat profil');
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
  Future<void> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post('/profile/password', data: {
        'old_password': oldPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Gagal memperbarui password');
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
  Future<String> updateFoto(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'foto': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('/profile/foto', data: formData);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          return data['foto'] as String;
        } else {
          throw Exception(data['message'] ?? 'Gagal memperbarui foto');
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

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRemoteDataSourceImpl(dio);
});
