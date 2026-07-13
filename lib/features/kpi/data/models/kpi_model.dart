class KpiPeriodModel {
  final int id;
  final String name;
  final String startDate;
  final String endDate;

  KpiPeriodModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory KpiPeriodModel.fromJson(Map<String, dynamic> json) {
    return KpiPeriodModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}

class KpiDetailModel {
  final int id;
  final String name;
  final String description;
  final double target;
  final double realisasi;
  final double bobot;
  final double skor;
  final String jenisTarget;
  final String mode;

  KpiDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.target,
    required this.realisasi,
    required this.bobot,
    required this.skor,
    required this.jenisTarget,
    required this.mode,
  });

  factory KpiDetailModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return KpiDetailModel(
      id: json['id'] ?? 0,
      name: json['indicator_name'] ?? '',
      description: json['indicator_description'] ?? '',
      target: parseDouble(json['target']),
      realisasi: parseDouble(json['realisasi']),
      bobot: parseDouble(json['bobot']),
      skor: parseDouble(json['skor']),
      jenisTarget: json['jenis_target'] ?? 'max',
      mode: json['mode'] ?? 'manual',
    );
  }
}

class KpiResponseModel {
  final bool hasKpi;
  final int kpiId;
  final KpiPeriodModel period;
  final String status;
  final double totalScore;
  final double totalBobot;
  final List<KpiDetailModel> details;
  final String? errorMessage;

  KpiResponseModel({
    required this.hasKpi,
    required this.kpiId,
    required this.period,
    required this.status,
    required this.totalScore,
    required this.totalBobot,
    required this.details,
    this.errorMessage,
  });

  factory KpiResponseModel.error(String message) {
    return KpiResponseModel(
      hasKpi: false,
      kpiId: 0,
      period: KpiPeriodModel(id: 0, name: '', startDate: '', endDate: ''),
      status: '',
      totalScore: 0.0,
      totalBobot: 0.0,
      details: [],
      errorMessage: message,
    );
  }

  factory KpiResponseModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    final list = json['details'] as List? ?? [];
    return KpiResponseModel(
      hasKpi: json['has_kpi'] ?? false,
      kpiId: json['kpi_id'] ?? 0,
      period: KpiPeriodModel.fromJson(Map<String, dynamic>.from(json['period'] ?? {})),
      status: json['status'] ?? '',
      totalScore: parseDouble(json['total_score']),
      totalBobot: parseDouble(json['total_bobot']),
      details: list.map((e) => KpiDetailModel.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
