class PengumumanModel {
  final int id;
  final String judul;
  final String isi;
  final String? lampiran;
  final String? lampiranUrl;
  final String createdAt;
  final String formattedDate;
  final String shortDate;

  PengumumanModel({
    required this.id,
    required this.judul,
    required this.isi,
    this.lampiran,
    this.lampiranUrl,
    required this.createdAt,
    required this.formattedDate,
    required this.shortDate,
  });

  factory PengumumanModel.fromJson(Map<String, dynamic> json) {
    return PengumumanModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      lampiran: json['lampiran']?.toString(),
      lampiranUrl: json['lampiran_url']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString() ?? '-',
      shortDate: json['short_date']?.toString() ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'isi': isi,
      'lampiran': lampiran,
      'lampiran_url': lampiranUrl,
      'created_at': createdAt,
      'formatted_date': formattedDate,
      'short_date': shortDate,
    };
  }
}
