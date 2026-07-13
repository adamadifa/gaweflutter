import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/izin/data/models/izin_model.dart';
import 'package:gaweflutter/features/izin/data/repositories/izin_repository.dart';

final izinListProvider = FutureProvider.autoDispose<List<IzinModel>>((ref) async {
  final repository = ref.watch(izinRepositoryProvider);
  return repository.getIzinList();
});
