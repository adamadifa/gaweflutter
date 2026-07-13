class ReimbursementCategoryModel {
  final String kodeJenisReimburse;
  final String namaJenis;
  final int wajibBukti;
  final double limitNominal;

  ReimbursementCategoryModel({
    required this.kodeJenisReimburse,
    required this.namaJenis,
    required this.wajibBukti,
    required this.limitNominal,
  });

  factory ReimbursementCategoryModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementCategoryModel(
      kodeJenisReimburse: json['kode_jenis_reimburse'] ?? '',
      namaJenis: json['nama_jenis'] ?? '',
      wajibBukti: json['wajib_bukti'] ?? 0,
      limitNominal: (json['limit_nominal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReimbursementModel {
  final int id;
  final String noReimbursement;
  final String tanggalPengajuan;
  final double totalNominal;
  final String? catatan;
  final String status;
  final int approvalStep;

  ReimbursementModel({
    required this.id,
    required this.noReimbursement,
    required this.tanggalPengajuan,
    required this.totalNominal,
    this.catatan,
    required this.status,
    required this.approvalStep,
  });

  factory ReimbursementModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementModel(
      id: json['id'] ?? 0,
      noReimbursement: json['no_reimbursement'] ?? '',
      tanggalPengajuan: json['tanggal_pengajuan'] ?? '',
      totalNominal: (json['total_nominal'] as num?)?.toDouble() ?? 0.0,
      catatan: json['catatan'],
      status: json['status'] ?? '',
      approvalStep: json['approval_step'] ?? 1,
    );
  }
}

class ReimbursementDetailModel {
  final int id;
  final String tanggalTransaksi;
  final String kodeJenisReimburse;
  final String? namaJenis;
  final double nominal;
  final String keterangan;
  final String? buktiFile;

  ReimbursementDetailModel({
    required this.id,
    required this.tanggalTransaksi,
    required this.kodeJenisReimburse,
    this.namaJenis,
    required this.nominal,
    required this.keterangan,
    this.buktiFile,
  });

  factory ReimbursementDetailModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementDetailModel(
      id: json['id'] ?? 0,
      tanggalTransaksi: json['tanggal_transaksi'] ?? '',
      kodeJenisReimburse: json['kode_jenis_reimburse'] ?? '',
      namaJenis: json['nama_jenis'],
      nominal: (json['nominal'] as num?)?.toDouble() ?? 0.0,
      keterangan: json['keterangan'] ?? '',
      buktiFile: json['bukti_file'],
    );
  }
}

class ReimbursementApprovalModel {
  final int id;
  final String userName;
  final String status;
  final String? notes;
  final int level;
  final String? createdAt;

  ReimbursementApprovalModel({
    required this.id,
    required this.userName,
    required this.status,
    this.notes,
    required this.level,
    this.createdAt,
  });

  factory ReimbursementApprovalModel.fromJson(Map<String, dynamic> json) {
    return ReimbursementApprovalModel(
      id: json['id'] ?? 0,
      userName: json['user_name'] ?? '',
      status: json['status'] ?? '',
      notes: json['notes'],
      level: json['level'] ?? 1,
      createdAt: json['created_at'],
    );
  }
}

class ReimbursementFullDetailModel {
  final int id;
  final String noReimbursement;
  final String tanggalPengajuan;
  final double totalNominal;
  final String? catatan;
  final String status;
  final int approvalStep;
  final List<ReimbursementDetailModel> details;
  final List<ReimbursementApprovalModel> approvals;

  ReimbursementFullDetailModel({
    required this.id,
    required this.noReimbursement,
    required this.tanggalPengajuan,
    required this.totalNominal,
    this.catatan,
    required this.status,
    required this.approvalStep,
    required this.details,
    required this.approvals,
  });

  factory ReimbursementFullDetailModel.fromJson(Map<String, dynamic> json) {
    final detailList = json['details'] as List? ?? [];
    final approvalList = json['approvals'] as List? ?? [];

    return ReimbursementFullDetailModel(
      id: json['id'] ?? 0,
      noReimbursement: json['no_reimbursement'] ?? '',
      tanggalPengajuan: json['tanggal_pengajuan'] ?? '',
      totalNominal: (json['total_nominal'] as num?)?.toDouble() ?? 0.0,
      catatan: json['catatan'],
      status: json['status'] ?? '',
      approvalStep: json['approval_step'] ?? 1,
      details: detailList.map((e) => ReimbursementDetailModel.fromJson(Map<String, dynamic>.from(e))).toList(),
      approvals: approvalList.map((e) => ReimbursementApprovalModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
