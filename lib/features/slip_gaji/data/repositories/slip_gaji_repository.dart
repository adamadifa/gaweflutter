import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/slip_gaji/data/datasources/slip_gaji_remote_data_source.dart';
import 'package:gaweflutter/features/slip_gaji/data/models/slip_gaji_model.dart';

abstract class SlipGajiRepository {
  Future<List<SlipGajiPeriod>> getSlipGajiPeriods();
  Future<SlipGajiDetail> getSlipGajiDetail(int bulan, int tahun);
}

class SlipGajiRepositoryImpl implements SlipGajiRepository {
  final SlipGajiRemoteDataSource _remoteDataSource;

  SlipGajiRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<SlipGajiPeriod>> getSlipGajiPeriods() async {
    return await _remoteDataSource.getSlipGajiPeriods();
  }

  @override
  Future<SlipGajiDetail> getSlipGajiDetail(int bulan, int tahun) async {
    return await _remoteDataSource.getSlipGajiDetail(bulan, tahun);
  }
}

final slipGajiRepositoryProvider = Provider<SlipGajiRepository>((ref) {
  final remoteDataSource = ref.watch(slipGajiRemoteDataSourceProvider);
  return SlipGajiRepositoryImpl(remoteDataSource);
});
