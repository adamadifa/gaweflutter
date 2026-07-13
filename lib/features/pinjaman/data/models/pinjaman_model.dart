class RencanaCicilanModel {
  final int id;
  final int cicilanKe;
  final int bulan;
  final int tahun;
  final double jumlahCicilan;
  final String status;

  RencanaCicilanModel({
    required this.id,
    required this.cicilanKe,
    required this.bulan,
    required this.tahun,
    required this.jumlahCicilan,
    required this.status,
  });

  factory RencanaCicilanModel.fromJson(Map<String, dynamic> json) {
    return RencanaCicilanModel(
      id: json['id'] ?? 0,
      cicilanKe: json['cicilan_ke'] ?? 0,
      bulan: json['bulan'] ?? 1,
      tahun: json['tahun'] ?? 0,
      jumlahCicilan: (json['jumlah_cicilan'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
    );
  }
}

class PembayaranPinjamanModel {
  final int id;
  final String tanggalBayar;
  final String noBukti;
  final double jumlahBayar;

  PembayaranPinjamanModel({
    required this.id,
    required this.tanggalBayar,
    required this.noBukti,
    required this.jumlahBayar,
  });

  factory PembayaranPinjamanModel.fromJson(Map<String, dynamic> json) {
    return PembayaranPinjamanModel(
      id: json['id'] ?? 0,
      tanggalBayar: json['tanggal_bayar'] ?? '',
      noBukti: json['no_bukti'] ?? '',
      jumlahBayar: (json['jumlah_bayar'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PinjamanModel {
  final int id;
  final String noPinjaman;
  final String tanggalPinjaman;
  final double jumlahPinjaman;
  final double sisaPinjaman;
  final double totalDibayar;
  final int jumlahCicilan;
  final String status;
  final List<RencanaCicilanModel> rencanaCicilan;
  final List<PembayaranPinjamanModel> pembayaranPinjaman;

  PinjamanModel({
    required this.id,
    required this.noPinjaman,
    required this.tanggalPinjaman,
    required this.jumlahPinjaman,
    required this.sisaPinjaman,
    required this.totalDibayar,
    required this.jumlahCicilan,
    required this.status,
    required this.rencanaCicilan,
    required this.pembayaranPinjaman,
  });

  factory PinjamanModel.fromJson(Map<String, dynamic> json) {
    final plans = json['rencana_cicilan'] as List? ?? [];
    final payments = json['pembayaran_pinjaman'] as List? ?? [];

    return PinjamanModel(
      id: json['id'] ?? 0,
      noPinjaman: json['no_pinjaman'] ?? '',
      tanggalPinjaman: json['tanggal_pinjaman'] ?? '',
      jumlahPinjaman: (json['jumlah_pinjaman'] as num?)?.toDouble() ?? 0.0,
      sisaPinjaman: (json['sisa_pinjaman'] as num?)?.toDouble() ?? 0.0,
      totalDibayar: (json['total_dibayar'] as num?)?.toDouble() ?? 0.0,
      jumlahCicilan: json['jumlah_cicilan'] ?? 0,
      status: json['status'] ?? '',
      rencanaCicilan: plans.map((e) => RencanaCicilanModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      pembayaranPinjaman: payments.map((e) => PembayaranPinjamanModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class PinjamanSummaryModel {
  final double sisaSaldoPinjaman;
  final double totalPinjaman;
  final double totalDibayar;
  final List<PinjamanModel> pinjaman;

  PinjamanSummaryModel({
    required this.sisaSaldoPinjaman,
    required this.totalPinjaman,
    required this.totalDibayar,
    required this.pinjaman,
  });

  factory PinjamanSummaryModel.fromJson(Map<String, dynamic> json) {
    final list = json['pinjaman'] as List? ?? [];
    return PinjamanSummaryModel(
      sisaSaldoPinjaman: (json['sisa_saldo_pinjaman'] as num?)?.toDouble() ?? 0.0,
      totalPinjaman: (json['total_pinjaman'] as num?)?.toDouble() ?? 0.0,
      totalDibayar: (json['total_dibayar'] as num?)?.toDouble() ?? 0.0,
      pinjaman: list.map((e) => PinjamanModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
