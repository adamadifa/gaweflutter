import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/slip_gaji/data/models/slip_gaji_model.dart';
import 'package:gaweflutter/features/slip_gaji/data/repositories/slip_gaji_repository.dart';

final slipGajiListProvider = FutureProvider.autoDispose<List<SlipGajiPeriod>>((ref) async {
  final repository = ref.watch(slipGajiRepositoryProvider);
  return repository.getSlipGajiPeriods();
});

final slipGajiDetailProvider = FutureProvider.autoDispose.family<SlipGajiDetail, String>((ref, arg) async {
  final repository = ref.watch(slipGajiRepositoryProvider);
  final parts = arg.split('-');
  final bulan = int.parse(parts[0]);
  final tahun = int.parse(parts[1]);
  return repository.getSlipGajiDetail(bulan, tahun);
});
