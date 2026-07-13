import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pinjaman/data/models/pinjaman_model.dart';
import 'package:gaweflutter/features/pinjaman/data/repositories/pinjaman_repository.dart';

final pinjamanSummaryProvider = FutureProvider.autoDispose<PinjamanSummaryModel>((ref) async {
  final repository = ref.watch(pinjamanRepositoryProvider);
  return repository.getPinjamanSummary();
});
