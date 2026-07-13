import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/kontrak/data/models/kontrak_model.dart';
import 'package:gaweflutter/features/kontrak/data/repositories/kontrak_repository.dart';

final kontrakListProvider = FutureProvider.autoDispose<List<KontrakModel>>((ref) async {
  final repository = ref.watch(kontrakRepositoryProvider);
  return repository.getContracts();
});

final kontrakDetailProvider = FutureProvider.autoDispose.family<KontrakDetailModel, int>((ref, id) async {
  final repository = ref.watch(kontrakRepositoryProvider);
  return repository.getContractDetail(id);
});
