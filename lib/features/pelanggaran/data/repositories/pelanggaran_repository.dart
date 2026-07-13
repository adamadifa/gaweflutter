import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pelanggaran/data/datasources/pelanggaran_remote_data_source.dart';
import 'package:gaweflutter/features/pelanggaran/data/models/pelanggaran_model.dart';

abstract class PelanggaranRepository {
  Future<List<PelanggaranModel>> getViolations();
  Future<PelanggaranDetailModel> getViolationDetail(String noSp);
}

class PelanggaranRepositoryImpl implements PelanggaranRepository {
  final PelanggaranRemoteDataSource _remoteDataSource;

  PelanggaranRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PelanggaranModel>> getViolations() async {
    return await _remoteDataSource.getViolations();
  }

  @override
  Future<PelanggaranDetailModel> getViolationDetail(String noSp) async {
    return await _remoteDataSource.getViolationDetail(noSp);
  }
}

final pelanggaranRepositoryProvider = Provider<PelanggaranRepository>((ref) {
  final remoteDataSource = ref.watch(pelanggaranRemoteDataSourceProvider);
  return PelanggaranRepositoryImpl(remoteDataSource);
});
