import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/storage/secure_storage.dart';
import 'package:gaweflutter/data/datasources/auth_remote_data_source.dart';
import 'package:gaweflutter/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> login(String username, String password);
  Future<void> logout();
  Future<UserModel?> getCachedUser();
  Future<String?> getCachedToken();
  Future<void> saveCachedUser(UserModel user);
  Future<UserModel> getProfile();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<UserModel> login(String username, String password) async {
    final result = await _remoteDataSource.login(username, password);
    final String token = result['token'];
    final UserModel user = result['user'];

    // Save token and user info locally
    await SecureStorage.saveToken(token);
    await SecureStorage.saveUser(jsonEncode(user.toJson()));

    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Even if API logout fails, clear local storage
    } finally {
      await SecureStorage.deleteToken();
      await SecureStorage.deleteUser();
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final userJson = await SecureStorage.getUser();
    if (userJson != null) {
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<String?> getCachedToken() async {
    return await SecureStorage.getToken();
  }

  @override
  Future<void> saveCachedUser(UserModel user) async {
    await SecureStorage.saveUser(jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel> getProfile() async {
    return await _remoteDataSource.getProfile();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});
