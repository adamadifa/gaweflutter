import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/reimbursement/data/datasources/reimbursement_remote_data_source.dart';
import 'package:gaweflutter/features/reimbursement/data/models/reimbursement_model.dart';

abstract class ReimbursementRepository {
  Future<List<ReimbursementModel>> getReimbursements();
  Future<List<ReimbursementCategoryModel>> getCategories();
  Future<ReimbursementFullDetailModel> getReimbursementDetail(int id);
  Future<void> submitReimbursement({
    required String tanggal,
    required String keterangan,
    required List<ReimbursementSubmitItem> items,
  });
  Future<void> deleteReimbursement(int id);
}

class ReimbursementRepositoryImpl implements ReimbursementRepository {
  final ReimbursementRemoteDataSource _remoteDataSource;

  ReimbursementRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ReimbursementModel>> getReimbursements() async {
    return await _remoteDataSource.getReimbursements();
  }

  @override
  Future<List<ReimbursementCategoryModel>> getCategories() async {
    return await _remoteDataSource.getCategories();
  }

  @override
  Future<ReimbursementFullDetailModel> getReimbursementDetail(int id) async {
    return await _remoteDataSource.getReimbursementDetail(id);
  }

  @override
  Future<void> submitReimbursement({
    required String tanggal,
    required String keterangan,
    required List<ReimbursementSubmitItem> items,
  }) async {
    return await _remoteDataSource.submitReimbursement(
      tanggal: tanggal,
      keterangan: keterangan,
      items: items,
    );
  }

  @override
  Future<void> deleteReimbursement(int id) async {
    return await _remoteDataSource.deleteReimbursement(id);
  }
}

final reimbursementRepositoryProvider = Provider<ReimbursementRepository>((ref) {
  final remoteDataSource = ref.watch(reimbursementRemoteDataSourceProvider);
  return ReimbursementRepositoryImpl(remoteDataSource);
});
