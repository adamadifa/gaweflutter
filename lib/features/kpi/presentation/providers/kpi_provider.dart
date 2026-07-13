import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/kpi/data/models/kpi_model.dart';
import 'package:gaweflutter/features/kpi/data/repositories/kpi_repository.dart';

final myKpiScoreProvider = FutureProvider.autoDispose<KpiResponseModel>((ref) async {
  final repository = ref.watch(kpiRepositoryProvider);
  return repository.getMyKpiScore();
});
