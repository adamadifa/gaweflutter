import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pengumuman/data/models/pengumuman_model.dart';
import 'package:gaweflutter/features/pengumuman/data/repositories/pengumuman_repository.dart';

final pengumumanListProvider = FutureProvider.autoDispose.family<List<PengumumanModel>, String?>((ref, search) async {
  final repository = ref.watch(pengumumanRepositoryProvider);
  return repository.getPengumumanList(search: search);
});

final pengumumanDetailProvider = FutureProvider.autoDispose.family<PengumumanModel, int>((ref, id) async {
  final repository = ref.watch(pengumumanRepositoryProvider);
  return repository.getPengumumanDetail(id);
});
