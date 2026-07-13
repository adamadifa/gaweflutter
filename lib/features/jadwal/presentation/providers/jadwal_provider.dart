import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/jadwal/data/models/jadwal_model.dart';
import 'package:gaweflutter/features/jadwal/data/repositories/jadwal_repository.dart';

class JadwalQuery {
  final String bulan;
  final String tahun;
  JadwalQuery({required this.bulan, required this.tahun});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JadwalQuery &&
          runtimeType == other.runtimeType &&
          bulan == other.bulan &&
          tahun == other.tahun;

  @override
  int get hashCode => bulan.hashCode ^ tahun.hashCode;
}

final jadwalListProvider = FutureProvider.autoDispose.family<List<JadwalModel>, JadwalQuery>((ref, query) async {
  final repository = ref.watch(jadwalRepositoryProvider);
  return repository.getJadwalList(bulan: query.bulan, tahun: query.tahun);
});
