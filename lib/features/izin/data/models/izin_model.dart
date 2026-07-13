class IzinModel {
  final String kode;
  final String tanggal;
  final String keterangan;
  final String dari;
  final String sampai;
  final String ket; // 'i' (absen), 's' (sakit), 'c' (cuti), 'd' (dinas), 'k' (koreksi)
  final int status; // 0 = pending, 1 = approved, 2 = rejected
  final int approvalStep;
  final String? docSid;
  final String? docSidUrl;

  IzinModel({
    required this.kode,
    required this.tanggal,
    required this.keterangan,
    required this.dari,
    required this.sampai,
    required this.ket,
    required this.status,
    required this.approvalStep,
    this.docSid,
    this.docSidUrl,
  });

  factory IzinModel.fromJson(Map<String, dynamic> json) {
    return IzinModel(
      kode: json['kode']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      dari: json['dari']?.toString() ?? '',
      sampai: json['sampai']?.toString() ?? '',
      ket: json['ket']?.toString() ?? 'i',
      status: _parseInt(json['status']) ?? 0,
      approvalStep: _parseInt(json['approval_step']) ?? 1,
      docSid: json['doc_sid']?.toString(),
      docSidUrl: json['doc_sid_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kode': kode,
      'tanggal': tanggal,
      'keterangan': keterangan,
      'dari': dari,
      'sampai': sampai,
      'ket': ket,
      'status': status,
      'approval_step': approvalStep,
      'doc_sid': docSid,
      'doc_sid_url': docSidUrl,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
