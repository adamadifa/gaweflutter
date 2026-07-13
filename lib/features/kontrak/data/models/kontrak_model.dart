class KontrakModel {
  final int id;
  final String noKontrak;
  final String? noDokumen;
  final String dari;
  final String sampai;
  final String statusKontrak;
  final String tanggal;
  final String namaJabatan;
  final String namaCabang;
  final String namaDept;

  KontrakModel({
    required this.id,
    required this.noKontrak,
    this.noDokumen,
    required this.dari,
    required this.sampai,
    required this.statusKontrak,
    required this.tanggal,
    required this.namaJabatan,
    required this.namaCabang,
    required this.namaDept,
  });

  factory KontrakModel.fromJson(Map<String, dynamic> json) {
    return KontrakModel(
      id: json['id'] ?? 0,
      noKontrak: json['no_kontrak'] ?? '',
      noDokumen: json['no_dokumen'],
      dari: json['dari'] ?? '',
      sampai: json['sampai'] ?? '',
      statusKontrak: json['status_kontrak'] ?? '0',
      tanggal: json['tanggal'] ?? '',
      namaJabatan: json['nama_jabatan'] ?? '',
      namaCabang: json['nama_cabang'] ?? '',
      namaDept: json['nama_dept'] ?? '',
    );
  }
}

class TunjanganDetailModel {
  final String jenis;
  final double jumlah;

  TunjanganDetailModel({
    required this.jenis,
    required this.jumlah,
  });

  factory TunjanganDetailModel.fromJson(Map<String, dynamic> json) {
    return TunjanganDetailModel(
      jenis: json['jenis'] ?? '',
      jumlah: (json['jumlah'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class KontrakDetailModel {
  final int id;
  final String noKontrak;
  final String? noDokumen;
  final String jenisKontrak;
  final String dari;
  final String sampai;
  final String statusKontrak;
  final String tanggal;
  final String namaKaryawan;
  final String namaJabatan;
  final String namaCabang;
  final String namaDept;
  final double gajiPokok;
  final List<TunjanganDetailModel> tunjangan;
  final String kontenHtml;

  KontrakDetailModel({
    required this.id,
    required this.noKontrak,
    this.noDokumen,
    required this.jenisKontrak,
    required this.dari,
    required this.sampai,
    required this.statusKontrak,
    required this.tanggal,
    required this.namaKaryawan,
    required this.namaJabatan,
    required this.namaCabang,
    required this.namaDept,
    required this.gajiPokok,
    required this.tunjangan,
    required this.kontenHtml,
  });

  factory KontrakDetailModel.fromJson(Map<String, dynamic> json) {
    final list = json['tunjangan'] as List? ?? [];
    return KontrakDetailModel(
      id: json['id'] ?? 0,
      noKontrak: json['no_kontrak'] ?? '',
      noDokumen: json['no_dokumen'],
      jenisKontrak: json['jenis_kontrak'] ?? '',
      dari: json['dari'] ?? '',
      sampai: json['sampai'] ?? '',
      statusKontrak: json['status_kontrak'] ?? '0',
      tanggal: json['tanggal'] ?? '',
      namaKaryawan: json['nama_karyawan'] ?? '',
      namaJabatan: json['nama_jabatan'] ?? '',
      namaCabang: json['nama_cabang'] ?? '',
      namaDept: json['nama_dept'] ?? '',
      gajiPokok: (json['gaji_pokok'] as num?)?.toDouble() ?? 0.0,
      tunjangan: list.map((e) => TunjanganDetailModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      kontenHtml: json['konten_html'] ?? '',
    );
  }
}
