class ShiftModel {
  final String kodeJamKerja;
  final String namaJamKerja;
  final String? jamMasuk;
  final String? jamPulang;
  final String? color;

  ShiftModel({
    required this.kodeJamKerja,
    required this.namaJamKerja,
    this.jamMasuk,
    this.jamPulang,
    this.color,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      kodeJamKerja: json['kode_jam_kerja'] ?? '',
      namaJamKerja: json['nama_jam_kerja'] ?? '',
      jamMasuk: json['jam_masuk'],
      jamPulang: json['jam_pulang'],
      color: json['color'],
    );
  }
}

class TukarShiftRequestModel {
  final int id;
  final String tanggal;
  final String kodeJamKerjaAwal;
  final String namaJamKerjaAwal;
  final String? jamMasukAwal;
  final String? jamPulangAwal;
  final String kodeJamKerjaTujuan;
  final String namaJamKerjaTujuan;
  final String? jamMasukTujuan;
  final String? jamPulangTujuan;
  final String keterangan;
  final String status;
  final String createdAt;

  TukarShiftRequestModel({
    required this.id,
    required this.tanggal,
    required this.kodeJamKerjaAwal,
    required this.namaJamKerjaAwal,
    this.jamMasukAwal,
    this.jamPulangAwal,
    required this.kodeJamKerjaTujuan,
    required this.namaJamKerjaTujuan,
    this.jamMasukTujuan,
    this.jamPulangTujuan,
    required this.keterangan,
    required this.status,
    required this.createdAt,
  });

  factory TukarShiftRequestModel.fromJson(Map<String, dynamic> json) {
    return TukarShiftRequestModel(
      id: json['id'] ?? 0,
      tanggal: json['tanggal'] ?? '',
      kodeJamKerjaAwal: json['kode_jam_kerja_awal'] ?? '',
      namaJamKerjaAwal: json['nama_jam_kerja_awal'] ?? '',
      jamMasukAwal: json['jam_masuk_awal'],
      jamPulangAwal: json['jam_pulang_awal'],
      kodeJamKerjaTujuan: json['kode_jam_kerja_tujuan'] ?? '',
      namaJamKerjaTujuan: json['nama_jam_kerja_tujuan'] ?? '',
      jamMasukTujuan: json['jam_masuk_tujuan'],
      jamPulangTujuan: json['jam_pulang_tujuan'],
      keterangan: json['keterangan'] ?? '',
      status: json['status'] ?? 'p',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class TukarShiftResponseModel {
  final List<TukarShiftRequestModel> requests;
  final List<ShiftModel> shifts;

  TukarShiftResponseModel({
    required this.requests,
    required this.shifts,
  });

  factory TukarShiftResponseModel.fromJson(Map<String, dynamic> json) {
    final reqs = json['requests'] as List? ?? [];
    final sfts = json['shifts'] as List? ?? [];

    return TukarShiftResponseModel(
      requests: reqs.map((e) => TukarShiftRequestModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      shifts: sfts.map((e) => ShiftModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
