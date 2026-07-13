import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/tukar_shift/data/datasources/tukar_shift_remote_data_source.dart';
import 'package:gaweflutter/features/tukar_shift/data/models/tukar_shift_model.dart';

abstract class TukarShiftRepository {
  Future<TukarShiftResponseModel> getTukarShiftData();
  Future<void> submitTukarShift({
    required String tanggal,
    required String kodeJamKerjaTujuan,
    required String keterangan,
  });
  Future<void> cancelTukarShift(int id);
}

class TukarShiftRepositoryImpl implements TukarShiftRepository {
  final TukarShiftRemoteDataSource _remoteDataSource;

  TukarShiftRepositoryImpl(this._remoteDataSource);

  @override
  Future<TukarShiftResponseModel> getTukarShiftData() async {
    return await _remoteDataSource.getTukarShiftData();
  }

  @override
  Future<void> submitTukarShift({
    required String tanggal,
    required String kodeJamKerjaTujuan,
    required String keterangan,
  }) async {
    await _remoteDataSource.submitTukarShift(
      tanggal: tanggal,
      kodeJamKerjaTujuan: kodeJamKerjaTujuan,
      keterangan: keterangan,
    );
  }

  @override
  Future<void> cancelTukarShift(int id) async {
    await _remoteDataSource.cancelTukarShift(id);
  }
}

final tukarShiftRepositoryProvider = Provider<TukarShiftRepository>((ref) {
  final remoteDataSource = ref.watch(tukarShiftRemoteDataSourceProvider);
  return TukarShiftRepositoryImpl(remoteDataSource);
});
