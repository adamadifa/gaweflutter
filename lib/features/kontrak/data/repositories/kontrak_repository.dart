import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/kontrak/data/datasources/kontrak_remote_data_source.dart';
import 'package:gaweflutter/features/kontrak/data/models/kontrak_model.dart';

abstract class KontrakRepository {
  Future<List<KontrakModel>> getContracts();
  Future<KontrakDetailModel> getContractDetail(int id);
  Future<Uint8List> downloadContractPdf(int id);
}

class KontrakRepositoryImpl implements KontrakRepository {
  final KontrakRemoteDataSource _remoteDataSource;

  KontrakRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<KontrakModel>> getContracts() async {
    return await _remoteDataSource.getContracts();
  }

  @override
  Future<KontrakDetailModel> getContractDetail(int id) async {
    return await _remoteDataSource.getContractDetail(id);
  }

  @override
  Future<Uint8List> downloadContractPdf(int id) async {
    return await _remoteDataSource.downloadContractPdf(id);
  }
}

final kontrakRepositoryProvider = Provider<KontrakRepository>((ref) {
  final remoteDataSource = ref.watch(kontrakRemoteDataSourceProvider);
  return KontrakRepositoryImpl(remoteDataSource);
});
