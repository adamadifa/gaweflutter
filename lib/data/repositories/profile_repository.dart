import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/datasources/profile_remote_data_source.dart';
import 'package:gaweflutter/data/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile();
  Future<void> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  });
  Future<String> updateFoto(String filePath);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileModel> getProfile() async {
    return await _remoteDataSource.getProfile();
  }

  @override
  Future<void> updatePassword({
    required String oldPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _remoteDataSource.updatePassword(
      oldPassword: oldPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  @override
  Future<String> updateFoto(String filePath) async {
    return await _remoteDataSource.updateFoto(filePath);
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remoteDataSource);
});
