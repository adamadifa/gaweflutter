import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/models/riwayat_model.dart';
import 'package:gaweflutter/data/repositories/presensi_repository.dart';

class RiwayatBulanTahunNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void setDate(DateTime date) {
    state = date;
  }
}

final riwayatBulanTahunProvider = NotifierProvider<RiwayatBulanTahunNotifier, DateTime>(() {
  return RiwayatBulanTahunNotifier();
});

final riwayatProvider = FutureProvider.autoDispose<List<RiwayatModel>>((ref) async {
  final date = ref.watch(riwayatBulanTahunProvider);
  final repository = ref.watch(presensiRepositoryProvider);
  return repository.getRiwayat(bulan: date.month, tahun: date.year);
});
