import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pinjaman/data/datasources/pinjaman_remote_data_source.dart';
import 'package:gaweflutter/features/pinjaman/data/models/pinjaman_model.dart';

abstract class PinjamanRepository {
  Future<PinjamanSummaryModel> getPinjamanSummary();
}

class PinjamanRepositoryImpl implements PinjamanRepository {
  final PinjamanRemoteDataSource _remoteDataSource;

  PinjamanRepositoryImpl(this._remoteDataSource);

  @override
  Future<PinjamanSummaryModel> getPinjamanSummary() async {
    return await _remoteDataSource.getPinjamanSummary();
  }
}

final pinjamanRepositoryProvider = Provider<PinjamanRepository>((ref) {
  final remoteDataSource = ref.watch(pinjamanRemoteDataSourceProvider);
  return PinjamanRepositoryImpl(remoteDataSource);
});
