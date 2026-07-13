class RiwayatModel {
  final int id;
  final String tanggal;
  final String? jamIn;
  final String? jamOut;
  final String status;
  final String namaJamKerja;
  final String jamMasuk;
  final String jamPulang;
  final String? keterangan;
  final String? fotoIn;
  final String? fotoOut;

  RiwayatModel({
    required this.id,
    required this.tanggal,
    this.jamIn,
    this.jamOut,
    required this.status,
    required this.namaJamKerja,
    required this.jamMasuk,
    required this.jamPulang,
    this.keterangan,
    this.fotoIn,
    this.fotoOut,
  });

  factory RiwayatModel.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    final rawId = json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is double) {
      parsedId = rawId.toInt();
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    }

    return RiwayatModel(
      id: parsedId,
      tanggal: json['tanggal'] as String? ?? '',
      jamIn: json['jam_in'] as String?,
      jamOut: json['jam_out'] as String?,
      status: json['status'] as String? ?? 'h',
      namaJamKerja: json['nama_jam_kerja'] as String? ?? '',
      jamMasuk: json['jam_masuk'] as String? ?? '',
      jamPulang: json['jam_pulang'] as String? ?? '',
      keterangan: json['keterangan'] as String?,
      fotoIn: json['foto_in'] as String?,
      fotoOut: json['foto_out'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal': tanggal,
      'jam_in': jamIn,
      'jam_out': jamOut,
      'status': status,
      'nama_jam_kerja': namaJamKerja,
      'jam_masuk': jamMasuk,
      'jam_pulang': jamPulang,
      'keterangan': keterangan,
      'foto_in': fotoIn,
      'foto_out': fotoOut,
    };
  }
}
