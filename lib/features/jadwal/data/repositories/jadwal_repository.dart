import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/jadwal/data/datasources/jadwal_remote_data_source.dart';
import 'package:gaweflutter/features/jadwal/data/models/jadwal_model.dart';

abstract class JadwalRepository {
  Future<List<JadwalModel>> getJadwalList({String? bulan, String? tahun});
}

class JadwalRepositoryImpl implements JadwalRepository {
  final JadwalRemoteDataSource _remoteDataSource;

  JadwalRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<JadwalModel>> getJadwalList({String? bulan, String? tahun}) async {
    return await _remoteDataSource.getJadwalList(bulan: bulan, tahun: tahun);
  }
}

final jadwalRepositoryProvider = Provider<JadwalRepository>((ref) {
  final remoteDataSource = ref.watch(jadwalRemoteDataSourceProvider);
  return JadwalRepositoryImpl(remoteDataSource);
});
