class JadwalModel {
  final String tanggal;
  final String hari;
  final String namaJamKerja;
  final String? jamMasuk;
  final String? jamPulang;
  final String color;
  final bool isToday;
  final bool isHoliday;

  JadwalModel({
    required this.tanggal,
    required this.hari,
    required this.namaJamKerja,
    this.jamMasuk,
    this.jamPulang,
    required this.color,
    required this.isToday,
    required this.isHoliday,
  });

  factory JadwalModel.fromJson(Map<String, dynamic> json) {
    return JadwalModel(
      tanggal: json['tanggal'] ?? '',
      hari: json['hari'] ?? '',
      namaJamKerja: json['nama_jam_kerja'] ?? '',
      jamMasuk: json['jam_masuk'],
      jamPulang: json['jam_pulang'],
      color: json['color'] ?? '#10b981',
      isToday: json['is_today'] ?? false,
      isHoliday: json['is_holiday'] ?? false,
    );
  }
}
