class ApprovalAdminInfo {
  final int id;
  final String name;
  final String? role;

  ApprovalAdminInfo({
    required this.id,
    required this.name,
    this.role,
  });

  factory ApprovalAdminInfo.fromJson(Map<String, dynamic> json) {
    return ApprovalAdminInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      role: json['role'],
    );
  }
}

class ApprovalSummary {
  final int totalPending;
  final int countAbsen;
  final int countSakit;
  final int countCuti;
  final int countDinas;
  final int countReimbursement;

  ApprovalSummary({
    required this.totalPending,
    required this.countAbsen,
    required this.countSakit,
    required this.countCuti,
    required this.countDinas,
    required this.countReimbursement,
  });

  factory ApprovalSummary.fromJson(Map<String, dynamic> json) {
    return ApprovalSummary(
      totalPending: json['total_pending'] ?? 0,
      countAbsen: json['count_absen'] ?? 0,
      countSakit: json['count_sakit'] ?? 0,
      countCuti: json['count_cuti'] ?? 0,
      countDinas: json['count_dinas'] ?? 0,
      countReimbursement: json['count_reimbursement'] ?? 0,
    );
  }
}

class ReimbursementDetailItem {
  final int? id;
  final String namaJenis;
  final String? tanggalTransaksi;
  final double nominal;
  final String? keterangan;
  final String? fotoNota;

  ReimbursementDetailItem({
    this.id,
    required this.namaJenis,
    this.tanggalTransaksi,
    required this.nominal,
    this.keterangan,
    this.fotoNota,
  });

  factory ReimbursementDetailItem.fromJson(Map<String, dynamic> json) {
    return ReimbursementDetailItem(
      id: json['id'],
      namaJenis: json['nama_jenis'] ?? '',
      tanggalTransaksi: json['tanggal_transaksi'],
      nominal: (json['nominal'] as num?)?.toDouble() ?? 0.0,
      keterangan: json['keterangan'],
      fotoNota: json['foto_nota'],
    );
  }
}

class ApprovalItem {
  final String kode;
  final String type; // 'absen', 'sakit', 'cuti', 'dinas', 'reimbursement'
  final String typeLabel;
  final String nik;
  final String namaKaryawan;
  final String namaDept;
  final String namaCabang;
  final String namaJabatan;
  final String? tanggalPengajuan;
  final String? dari;
  final String? sampai;
  final int durasiHari;
  final String? keterangan;
  final int approvalStep;
  final int? status;
  final String? docSid;
  final String? docSidUrl;
  final double? totalNominal;
  final List<ReimbursementDetailItem> details;

  ApprovalItem({
    required this.kode,
    required this.type,
    required this.typeLabel,
    required this.nik,
    required this.namaKaryawan,
    required this.namaDept,
    required this.namaCabang,
    required this.namaJabatan,
    this.tanggalPengajuan,
    this.dari,
    this.sampai,
    this.durasiHari = 1,
    this.keterangan,
    this.approvalStep = 1,
    this.status,
    this.docSid,
    this.docSidUrl,
    this.totalNominal,
    this.details = const [],
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    var rawDetails = json['details'] as List?;
    List<ReimbursementDetailItem> parsedDetails = [];
    if (rawDetails != null) {
      parsedDetails = rawDetails.map((i) => ReimbursementDetailItem.fromJson(i)).toList();
    }

    return ApprovalItem(
      kode: json['kode'] ?? '',
      type: json['type'] ?? '',
      typeLabel: json['type_label'] ?? '',
      nik: json['nik'] ?? '',
      namaKaryawan: json['nama_karyawan'] ?? '',
      namaDept: json['nama_dept'] ?? '-',
      namaCabang: json['nama_cabang'] ?? '-',
      namaJabatan: json['nama_jabatan'] ?? '-',
      tanggalPengajuan: json['tanggal_pengajuan'],
      dari: json['dari'],
      sampai: json['sampai'],
      durasiHari: json['durasi_hari'] ?? 1,
      keterangan: json['keterangan'],
      approvalStep: json['approval_step'] ?? 1,
      status: json['status'],
      docSid: json['doc_sid'],
      docSidUrl: json['doc_sid_url'],
      totalNominal: (json['total_nominal'] as num?)?.toDouble(),
      details: parsedDetails,
    );
  }
}

class ApprovalResponseData {
  final bool hasAccess;
  final String? message;
  final ApprovalAdminInfo? admin;
  final ApprovalSummary? summary;
  final List<ApprovalItem> items;

  ApprovalResponseData({
    required this.hasAccess,
    this.message,
    this.admin,
    this.summary,
    this.items = const [],
  });

  factory ApprovalResponseData.fromJson(Map<String, dynamic> json) {
    final bool hasAccess = json['has_access'] ?? (json['data'] != null);
    final data = json['data'] as Map<String, dynamic>?;

    if (!hasAccess || data == null) {
      return ApprovalResponseData(
        hasAccess: false,
        message: json['message'] ?? 'Anda tidak memiliki akses delegasi approval.',
        items: const [],
      );
    }

    var rawItems = data['items'] as List? ?? [];
    return ApprovalResponseData(
      hasAccess: true,
      message: json['message'],
      admin: ApprovalAdminInfo.fromJson(data['admin'] ?? {}),
      summary: ApprovalSummary.fromJson(data['summary'] ?? {}),
      items: rawItems.map((i) => ApprovalItem.fromJson(i)).toList(),
    );
  }
}
