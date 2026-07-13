import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/izin/data/datasources/izin_remote_data_source.dart';
import 'package:gaweflutter/features/izin/data/models/izin_model.dart';

abstract class IzinRepository {
  Future<List<IzinModel>> getIzinList();
  Future<void> submitIzin({
    required String jenisIzin,
    required String dari,
    required String sampai,
    required String keterangan,
    String? sidPath,
  });
  Future<void> cancelIzin(String kode);
}

class IzinRepositoryImpl implements IzinRepository {
  final IzinRemoteDataSource _remoteDataSource;

  IzinRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<IzinModel>> getIzinList() async {
    return await _remoteDataSource.getIzinList();
  }

  @override
  Future<void> submitIzin({
    required String jenisIzin,
    required String dari,
    required String sampai,
    required String keterangan,
    String? sidPath,
  }) async {
    await _remoteDataSource.submitIzin(
      jenisIzin: jenisIzin,
      dari: dari,
      sampai: sampai,
      keterangan: keterangan,
      sidPath: sidPath,
    );
  }

  @override
  Future<void> cancelIzin(String kode) async {
    await _remoteDataSource.cancelIzin(kode);
  }
}

final izinRepositoryProvider = Provider<IzinRepository>((ref) {
  final remoteDataSource = ref.watch(izinRemoteDataSourceProvider);
  return IzinRepositoryImpl(remoteDataSource);
});
