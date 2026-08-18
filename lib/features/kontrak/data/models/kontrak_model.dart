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
  // Extended employee fields
  final String tempatLahir;
  final String tanggalLahir;
  final String jenisKelamin;
  final String alamatKaryawan;
  final String noKtp;
  final String noHp;
  final String pendidikanTerakhir;
  // Company fields
  final String namaHrd;
  final String jabatanHrd;
  final String namaPerusahaan;
  final String alamatPerusahaan;

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
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.alamatKaryawan,
    required this.noKtp,
    required this.noHp,
    required this.pendidikanTerakhir,
    required this.namaHrd,
    required this.jabatanHrd,
    required this.namaPerusahaan,
    required this.alamatPerusahaan,
  });

  factory KontrakDetailModel.fromJson(Map<String, dynamic> json) {
    final list = json['tunjangan'] as List? ?? [];

    String s(dynamic v, [String fallback = '']) =>
        v == null ? fallback : v.toString();

    return KontrakDetailModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      noKontrak: s(json['no_kontrak']),
      noDokumen: json['no_dokumen']?.toString(),
      jenisKontrak: s(json['jenis_kontrak']),
      dari: s(json['dari']),
      sampai: s(json['sampai']),
      statusKontrak: s(json['status_kontrak'], '0'),
      tanggal: s(json['tanggal']),
      namaKaryawan: s(json['nama_karyawan']),
      namaJabatan: s(json['nama_jabatan'], '-'),
      namaCabang: s(json['nama_cabang'], '-'),
      namaDept: s(json['nama_dept'], '-'),
      gajiPokok: (json['gaji_pokok'] as num?)?.toDouble() ?? 0.0,
      tunjangan: list.map((e) => TunjanganDetailModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      kontenHtml: s(json['konten_html']),
      tempatLahir: s(json['tempat_lahir'], '-'),
      tanggalLahir: s(json['tanggal_lahir'], '-'),
      jenisKelamin: s(json['jenis_kelamin'], '-'),
      alamatKaryawan: s(json['alamat_karyawan'], '-'),
      noKtp: s(json['no_ktp'], '-'),
      noHp: s(json['no_hp'], '-'),
      pendidikanTerakhir: s(json['pendidikan_terakhir'], '-'),
      namaHrd: s(json['nama_hrd'], 'Pihak Pertama'),
      jabatanHrd: s(json['jabatan_hrd'], '-'),
      namaPerusahaan: s(json['nama_perusahaan'], '-'),
      alamatPerusahaan: s(json['alamat_perusahaan'], '-'),
    );
  }
}
