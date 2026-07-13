class PelanggaranModel {
  final String noSp;
  final String? noDokumen;
  final String? tanggal;
  final String? dari;
  final String? sampai;
  final String jenisSp;
  final String keterangan;
  final String namaJabatan;
  final String namaCabang;
  final String namaDept;

  PelanggaranModel({
    required this.noSp,
    this.noDokumen,
    this.tanggal,
    this.dari,
    this.sampai,
    required this.jenisSp,
    required this.keterangan,
    required this.namaJabatan,
    required this.namaCabang,
    required this.namaDept,
  });

  factory PelanggaranModel.fromJson(Map<String, dynamic> json) {
    return PelanggaranModel(
      noSp: json['no_sp'] ?? '',
      noDokumen: json['no_dokumen'],
      tanggal: json['tanggal'],
      dari: json['dari'],
      sampai: json['sampai'],
      jenisSp: json['jenis_sp'] ?? '',
      keterangan: json['keterangan'] ?? '',
      namaJabatan: json['nama_jabatan'] ?? '',
      namaCabang: json['nama_cabang'] ?? '',
      namaDept: json['nama_dept'] ?? '',
    );
  }
}

class PelanggaranDetailModel {
  final String noSp;
  final String? noDokumen;
  final String? tanggal;
  final String? dari;
  final String? sampai;
  final String jenisSp;
  final String keterangan;
  final String namaKaryawan;
  final String nikShow;
  final String? alamat;
  final String namaJabatan;
  final String namaCabang;
  final String namaDept;
  final String? namaPerusahaan;

  PelanggaranDetailModel({
    required this.noSp,
    this.noDokumen,
    this.tanggal,
    this.dari,
    this.sampai,
    required this.jenisSp,
    required this.keterangan,
    required this.namaKaryawan,
    required this.nikShow,
    this.alamat,
    required this.namaJabatan,
    required this.namaCabang,
    required this.namaDept,
    this.namaPerusahaan,
  });

  factory PelanggaranDetailModel.fromJson(Map<String, dynamic> json) {
    return PelanggaranDetailModel(
      noSp: json['no_sp'] ?? '',
      noDokumen: json['no_dokumen'],
      tanggal: json['tanggal'],
      dari: json['dari'],
      sampai: json['sampai'],
      jenisSp: json['jenis_sp'] ?? '',
      keterangan: json['keterangan'] ?? '',
      namaKaryawan: json['nama_karyawan'] ?? '',
      nikShow: json['nik_show'] ?? '',
      alamat: json['alamat'],
      namaJabatan: json['nama_jabatan'] ?? '',
      namaCabang: json['nama_cabang'] ?? '',
      namaDept: json['nama_dept'] ?? '',
      namaPerusahaan: json['nama_perusahaan'],
    );
  }
}
