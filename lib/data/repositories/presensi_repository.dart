import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/datasources/presensi_remote_data_source.dart';
import 'package:gaweflutter/data/models/riwayat_model.dart';

abstract class PresensiRepository {
  Future<Map<String, dynamic>> absenMasuk({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  });

  Future<Map<String, dynamic>> absenPulang({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  });

  Future<Map<String, dynamic>> absenIstirahat({
    required String lokasi,
    required String status,
    required String kodeJamKerja,
    required String imagePath,
  });

  Future<List<RiwayatModel>> getRiwayat({
    required int bulan,
    required int tahun,
  });
}

class PresensiRepositoryImpl implements PresensiRepository {
  final PresensiRemoteDataSource _remoteDataSource;

  PresensiRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> absenMasuk({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  }) async {
    return await _remoteDataSource.absenMasuk(
      lokasi: lokasi,
      kodeJamKerja: kodeJamKerja,
      imagePath: imagePath,
    );
  }

  @override
  Future<Map<String, dynamic>> absenPulang({
    required String lokasi,
    required String kodeJamKerja,
    required String imagePath,
  }) async {
    return await _remoteDataSource.absenPulang(
      lokasi: lokasi,
      kodeJamKerja: kodeJamKerja,
      imagePath: imagePath,
    );
  }

  @override
  Future<Map<String, dynamic>> absenIstirahat({
    required String lokasi,
    required String status,
    required String kodeJamKerja,
    required String imagePath,
  }) async {
    return await _remoteDataSource.absenIstirahat(
      lokasi: lokasi,
      status: status,
      kodeJamKerja: kodeJamKerja,
      imagePath: imagePath,
    );
  }

  @override
  Future<List<RiwayatModel>> getRiwayat({
    required int bulan,
    required int tahun,
  }) async {
    return await _remoteDataSource.getRiwayat(bulan: bulan, tahun: tahun);
  }
}

final presensiRepositoryProvider = Provider<PresensiRepository>((ref) {
  final remoteDataSource = ref.watch(presensiRemoteDataSourceProvider);
  return PresensiRepositoryImpl(remoteDataSource);
});
