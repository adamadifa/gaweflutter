import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/tukar_shift/data/models/tukar_shift_model.dart';
import 'package:gaweflutter/features/tukar_shift/data/repositories/tukar_shift_repository.dart';

final tukarShiftDataProvider = FutureProvider.autoDispose<TukarShiftResponseModel>((ref) async {
  final repository = ref.watch(tukarShiftRepositoryProvider);
  return repository.getTukarShiftData();
});
