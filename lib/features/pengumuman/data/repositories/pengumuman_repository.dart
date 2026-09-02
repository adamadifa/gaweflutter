import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pengumuman/data/datasources/pengumuman_remote_data_source.dart';
import 'package:gaweflutter/features/pengumuman/data/models/pengumuman_model.dart';

abstract class PengumumanRepository {
  Future<List<PengumumanModel>> getPengumumanList({String? search});
  Future<PengumumanModel> getPengumumanDetail(int id);
}

class PengumumanRepositoryImpl implements PengumumanRepository {
  final PengumumanRemoteDataSource _remoteDataSource;

  PengumumanRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PengumumanModel>> getPengumumanList({String? search}) {
    return _remoteDataSource.getPengumumanList(search: search);
  }

  @override
  Future<PengumumanModel> getPengumumanDetail(int id) {
    return _remoteDataSource.getPengumumanDetail(id);
  }
}

final pengumumanRepositoryProvider = Provider<PengumumanRepository>((ref) {
  final remoteDataSource = ref.watch(pengumumanRemoteDataSourceProvider);
  return PengumumanRepositoryImpl(remoteDataSource);
});
