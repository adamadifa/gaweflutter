class SlipGajiPeriod {
  final String kodeSlipGaji;
  final int bulan;
  final int tahun;
  final String namaBulan;
  final String periodeDari;
  final String periodeSampai;

  SlipGajiPeriod({
    required this.kodeSlipGaji,
    required this.bulan,
    required this.tahun,
    required this.namaBulan,
    required this.periodeDari,
    required this.periodeSampai,
  });

  factory SlipGajiPeriod.fromJson(Map<String, dynamic> json) {
    return SlipGajiPeriod(
      kodeSlipGaji: json['kode_slip_gaji'] ?? '',
      bulan: json['bulan'] ?? 0,
      tahun: json['tahun'] ?? 0,
      namaBulan: json['nama_bulan'] ?? '',
      periodeDari: json['periode_dari'] ?? '',
      periodeSampai: json['periode_sampai'] ?? '',
    );
  }
}

class SlipGajiDetail {
  final KaryawanSlipInfo karyawan;
  final SlipGajiSummary summary;
  final SlipGajiPenerimaan penerimaan;
  final SlipGajiPotongan potongan;
  final double totalPenerimaan;
  final double totalPotongan;
  final double gajiBersih;

  SlipGajiDetail({
    required this.karyawan,
    required this.summary,
    required this.penerimaan,
    required this.potongan,
    required this.totalPenerimaan,
    required this.totalPotongan,
    required this.gajiBersih,
  });

  factory SlipGajiDetail.fromJson(Map<String, dynamic> json) {
    return SlipGajiDetail(
      karyawan: KaryawanSlipInfo.fromJson(json['karyawan'] ?? {}),
      summary: SlipGajiSummary.fromJson(json['summary'] ?? {}),
      penerimaan: SlipGajiPenerimaan.fromJson(json['penerimaan'] ?? {}),
      potongan: SlipGajiPotongan.fromJson(json['potongan'] ?? {}),
      totalPenerimaan: (json['total_penerimaan'] as num?)?.toDouble() ?? 0.0,
      totalPotongan: (json['total_potongan'] as num?)?.toDouble() ?? 0.0,
      gajiBersih: (json['gaji_bersih'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class KaryawanSlipInfo {
  final String nik;
  final String nikShow;
  final String namaKaryawan;
  final String namaJabatan;
  final String namaDept;
  final String jenisUpah;

  KaryawanSlipInfo({
    required this.nik,
    required this.nikShow,
    required this.namaKaryawan,
    required this.namaJabatan,
    required this.namaDept,
    required this.jenisUpah,
  });

  factory KaryawanSlipInfo.fromJson(Map<String, dynamic> json) {
    return KaryawanSlipInfo(
      nik: json['nik'] ?? '',
      nikShow: json['nik_show'] ?? '',
      namaKaryawan: json['nama_karyawan'] ?? '',
      namaJabatan: json['nama_jabatan'] ?? '',
      namaDept: json['nama_dept'] ?? '',
      jenisUpah: json['jenis_upah'] ?? 'Bulanan',
    );
  }
}

class SlipGajiSummary {
  final int hariKerja;
  final int hariHadir;
  final int hariTerlambat;
  final double jamLembur;

  SlipGajiSummary({
    required this.hariKerja,
    required this.hariHadir,
    required this.hariTerlambat,
    required this.jamLembur,
  });

  factory SlipGajiSummary.fromJson(Map<String, dynamic> json) {
    return SlipGajiSummary(
      hariKerja: json['hari_kerja'] ?? 0,
      hariHadir: json['hari_hadir'] ?? 0,
      hariTerlambat: json['hari_terlambat'] ?? 0,
      jamLembur: (json['jam_lembur'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TunjanganItem {
  final String nama;
  final double jumlah;

  TunjanganItem({
    required this.nama,
    required this.jumlah,
  });

  factory TunjanganItem.fromJson(Map<String, dynamic> json) {
    return TunjanganItem(
      nama: json['nama'] ?? '',
      jumlah: (json['jumlah'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SlipGajiPenerimaan {
  final double gajiPokok;
  final List<TunjanganItem> tunjangan;
  final double tunjanganPajak;
  final double upahLembur;
  final double penambah;
  final String keteranganPenyesuaian;

  SlipGajiPenerimaan({
    required this.gajiPokok,
    required this.tunjangan,
    required this.tunjanganPajak,
    required this.upahLembur,
    required this.penambah,
    required this.keteranganPenyesuaian,
  });

  factory SlipGajiPenerimaan.fromJson(Map<String, dynamic> json) {
    var tunjanganList = json['tunjangan'] as List?;
    List<TunjanganItem> parsedTunjangan = tunjanganList != null
        ? tunjanganList.map((i) => TunjanganItem.fromJson(i)).toList()
        : [];

    return SlipGajiPenerimaan(
      gajiPokok: (json['gaji_pokok'] as num?)?.toDouble() ?? 0.0,
      tunjangan: parsedTunjangan,
      tunjanganPajak: (json['tunjangan_pajak'] as num?)?.toDouble() ?? 0.0,
      upahLembur: (json['upah_lembur'] as num?)?.toDouble() ?? 0.0,
      penambah: (json['penambah'] as num?)?.toDouble() ?? 0.0,
      keteranganPenyesuaian: json['keterangan_penyesuaian'] ?? '',
    );
  }
}

class SlipGajiPotongan {
  final double potonganJam;
  final double denda;
  final double bpjsKesehatan;
  final double bpjsTenagakerja;
  final double cicilanPinjaman;
  final double potonganPph21;
  final double pengurang;

  SlipGajiPotongan({
    required this.potonganJam,
    required this.denda,
    required this.bpjsKesehatan,
    required this.bpjsTenagakerja,
    required this.cicilanPinjaman,
    required this.potonganPph21,
    required this.pengurang,
  });

  factory SlipGajiPotongan.fromJson(Map<String, dynamic> json) {
    return SlipGajiPotongan(
      potonganJam: (json['potongan_jam'] as num?)?.toDouble() ?? 0.0,
      denda: (json['denda'] as num?)?.toDouble() ?? 0.0,
      bpjsKesehatan: (json['bpjs_kesehatan'] as num?)?.toDouble() ?? 0.0,
      bpjsTenagakerja: (json['bpjs_tenagakerja'] as num?)?.toDouble() ?? 0.0,
      cicilanPinjaman: (json['cicilan_pinjaman'] as num?)?.toDouble() ?? 0.0,
      potonganPph21: (json['potongan_pph21'] as num?)?.toDouble() ?? 0.0,
      pengurang: (json['pengurang'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
