import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/reimbursement/data/models/reimbursement_model.dart';
import 'package:gaweflutter/features/reimbursement/data/repositories/reimbursement_repository.dart';

final reimbursementListProvider = FutureProvider.autoDispose<List<ReimbursementModel>>((ref) async {
  final repository = ref.watch(reimbursementRepositoryProvider);
  return repository.getReimbursements();
});

final reimbursementCategoriesProvider = FutureProvider.autoDispose<List<ReimbursementCategoryModel>>((ref) async {
  final repository = ref.watch(reimbursementRepositoryProvider);
  return repository.getCategories();
});

final reimbursementDetailProvider = FutureProvider.autoDispose.family<ReimbursementFullDetailModel, int>((ref, id) async {
  final repository = ref.watch(reimbursementRepositoryProvider);
  return repository.getReimbursementDetail(id);
});
