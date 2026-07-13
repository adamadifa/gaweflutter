import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/models/dashboard_model.dart';
import 'package:gaweflutter/data/repositories/dashboard_repository.dart';
import 'package:gaweflutter/data/repositories/lembur_repository.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboard();
});

final lemburListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repository = ref.watch(lemburRepositoryProvider);
  final result = await repository.getLemburList();
  return result['data'] ?? [];
});
