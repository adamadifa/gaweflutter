import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/kpi/data/datasources/kpi_remote_data_source.dart';
import 'package:gaweflutter/features/kpi/data/models/kpi_model.dart';

abstract class KpiRepository {
  Future<KpiResponseModel> getMyKpiScore();
  Future<void> submitRealisasi({
    required int kpiId,
    required List<Map<String, dynamic>> realisasi,
  });
}

class KpiRepositoryImpl implements KpiRepository {
  final KpiRemoteDataSource _remoteDataSource;

  KpiRepositoryImpl(this._remoteDataSource);

  @override
  Future<KpiResponseModel> getMyKpiScore() async {
    return await _remoteDataSource.getMyKpiScore();
  }

  @override
  Future<void> submitRealisasi({
    required int kpiId,
    required List<Map<String, dynamic>> realisasi,
  }) async {
    await _remoteDataSource.submitRealisasi(kpiId: kpiId, realisasi: realisasi);
  }
}

final kpiRepositoryProvider = Provider<KpiRepository>((ref) {
  final remoteDataSource = ref.watch(kpiRemoteDataSourceProvider);
  return KpiRepositoryImpl(remoteDataSource);
});
