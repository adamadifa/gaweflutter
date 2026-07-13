import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pelanggaran/data/models/pelanggaran_model.dart';
import 'package:gaweflutter/features/pelanggaran/data/repositories/pelanggaran_repository.dart';

final pelanggaranListProvider = FutureProvider.autoDispose<List<PelanggaranModel>>((ref) async {
  final repository = ref.watch(pelanggaranRepositoryProvider);
  return repository.getViolations();
});

final pelanggaranDetailProvider = FutureProvider.autoDispose.family<PelanggaranDetailModel, String>((ref, noSp) async {
  final repository = ref.watch(pelanggaranRepositoryProvider);
  return repository.getViolationDetail(noSp);
});
