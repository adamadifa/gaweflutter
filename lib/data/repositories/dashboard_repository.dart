import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/datasources/dashboard_remote_data_source.dart';
import 'package:gaweflutter/data/models/dashboard_model.dart';

abstract class DashboardRepository {
  Future<DashboardModel> getDashboard();
}

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remoteDataSource;

  DashboardRepositoryImpl(this._remoteDataSource);

  @override
  Future<DashboardModel> getDashboard() async {
    return await _remoteDataSource.getDashboard();
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final remoteDataSource = ref.watch(dashboardRemoteDataSourceProvider);
  return DashboardRepositoryImpl(remoteDataSource);
});
