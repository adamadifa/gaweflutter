import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/models/dashboard_model.dart';
import 'package:gaweflutter/data/repositories/dashboard_repository.dart';
import 'package:gaweflutter/data/repositories/lembur_repository.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    return DashboardModel(
      recap: MonthlyRecapModel(hadir: 0, sakit: 0, izin: 0, cuti: 0, alpa: 0),
      isBirthday: false,
      lockLocation: 1,
      history: [],
    );
  }
  
  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.getDashboard();
});

final lemburListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    return [];
  }
  
  final repository = ref.watch(lemburRepositoryProvider);
  final result = await repository.getLemburList();
  return result['data'] ?? [];
});
