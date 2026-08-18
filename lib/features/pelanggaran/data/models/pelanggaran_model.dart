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
    // keterangan can come as a List<String> or a plain String from the API
    final rawKet = json['keterangan'];
    final keteranganStr = rawKet is List
        ? rawKet.map((e) => e.toString()).join(', ')
        : (rawKet?.toString() ?? '');

    return PelanggaranModel(
      noSp: json['no_sp']?.toString() ?? '',
      noDokumen: json['no_dokumen']?.toString(),
      tanggal: json['tanggal']?.toString(),
      dari: json['dari']?.toString(),
      sampai: json['sampai']?.toString(),
      jenisSp: json['jenis_sp']?.toString() ?? '',
      keterangan: keteranganStr,
      namaJabatan: json['nama_jabatan']?.toString() ?? '',
      namaCabang: json['nama_cabang']?.toString() ?? '',
      namaDept: json['nama_dept']?.toString() ?? '',
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
    // keterangan can come as a List<String> or a plain String from the API
    final rawKet = json['keterangan'];
    final keteranganStr = rawKet is List
        ? rawKet.map((e) => e.toString()).join(', ')
        : (rawKet?.toString() ?? '');

    return PelanggaranDetailModel(
      noSp: json['no_sp']?.toString() ?? '',
      noDokumen: json['no_dokumen']?.toString(),
      tanggal: json['tanggal']?.toString(),
      dari: json['dari']?.toString(),
      sampai: json['sampai']?.toString(),
      jenisSp: json['jenis_sp']?.toString() ?? '',
      keterangan: keteranganStr,
      namaKaryawan: json['nama_karyawan']?.toString() ?? '',
      nikShow: json['nik_show']?.toString() ?? '',
      alamat: json['alamat']?.toString(),
      namaJabatan: json['nama_jabatan']?.toString() ?? '',
      namaCabang: json['nama_cabang']?.toString() ?? '',
      namaDept: json['nama_dept']?.toString() ?? '',
      namaPerusahaan: json['nama_perusahaan']?.toString(),
    );
  }
}
