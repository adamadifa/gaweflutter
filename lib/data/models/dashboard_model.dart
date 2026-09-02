import 'package:gaweflutter/data/models/riwayat_model.dart';

class DashboardModel {
  final TodayAttendanceModel? attendance;
  final MonthlyRecapModel recap;
  final bool isBirthday;
  final int? umur;
  final ContractNotifModel? notifKontrak;
  final SpNotifModel? notifSp;
  final AnnouncementModel? announcement;
  final CabangInfoModel? cabang;
  final int lockLocation;
  final JamKerjaInfoModel? jamKerja;
  final GeneralSettingModel? generalSetting;
  final List<RiwayatModel> history;
  final bool hasApprovalAccess;
  final int pendingApprovalCount;

  DashboardModel({
    this.attendance,
    required this.recap,
    required this.isBirthday,
    this.umur,
    this.notifKontrak,
    this.notifSp,
    this.announcement,
    this.cabang,
    required this.lockLocation,
    this.jamKerja,
    this.generalSetting,
    required this.history,
    this.hasApprovalAccess = false,
    this.pendingApprovalCount = 0,
  });

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    var historyList = json['history'] as List? ?? [];
    List<RiwayatModel> historyObjs = historyList.map((i) => RiwayatModel.fromJson(i)).toList();

    return DashboardModel(
      attendance: json['presensi'] != null ? TodayAttendanceModel.fromJson(json['presensi']) : null,
      recap: MonthlyRecapModel.fromJson(json['rekap'] ?? {}),
      isBirthday: json['is_birthday'] as bool? ?? false,
      umur: _parseInt(json['umur']),
      notifKontrak: json['notif_kontrak'] != null ? ContractNotifModel.fromJson(json['notif_kontrak']) : null,
      notifSp: json['notif_sp'] != null ? SpNotifModel.fromJson(json['notif_sp']) : null,
      announcement: json['pengumuman'] != null ? AnnouncementModel.fromJson(json['pengumuman']) : null,
      cabang: json['cabang'] != null ? CabangInfoModel.fromJson(json['cabang']) : null,
      lockLocation: _parseInt(json['lock_location']) ?? 1,
      jamKerja: json['jam_kerja'] != null ? JamKerjaInfoModel.fromJson(json['jam_kerja']) : null,
      generalSetting: json['general_setting'] != null ? GeneralSettingModel.fromJson(json['general_setting']) : null,
      history: historyObjs,
      hasApprovalAccess: json['has_approval_access'] as bool? ?? false,
      pendingApprovalCount: _parseInt(json['pending_approval_count']) ?? 0,
    );
  }
}

class GeneralSettingModel {
  final String namaPerusahaan;
  final String? logo;
  final String? alamat;
  final int absenIstirahat;
  final String mobileThemeScheme;

  GeneralSettingModel({
    required this.namaPerusahaan,
    this.logo,
    this.alamat,
    required this.absenIstirahat,
    required this.mobileThemeScheme,
  });

  factory GeneralSettingModel.fromJson(Map<String, dynamic> json) {
    return GeneralSettingModel(
      namaPerusahaan: json['nama_perusahaan'] as String? ?? 'E-Presensi',
      logo: json['logo'] as String?,
      alamat: json['alamat'] as String?,
      absenIstirahat: DashboardModel._parseInt(json['absen_istirahat']) ?? 0,
      mobileThemeScheme: json['mobile_theme_scheme'] as String? ?? 'green',
    );
  }
}

class CabangInfoModel {
  final String namaCabang;
  final String lokasiCabang;
  final int radiusCabang;

  CabangInfoModel({
    required this.namaCabang,
    required this.lokasiCabang,
    required this.radiusCabang,
  });

  factory CabangInfoModel.fromJson(Map<String, dynamic> json) {
    return CabangInfoModel(
      namaCabang: json['nama_cabang'] as String? ?? '',
      lokasiCabang: json['lokasi_cabang'] as String? ?? '',
      radiusCabang: json['radius_cabang'] as int? ?? 0,
    );
  }
}

class JamKerjaInfoModel {
  final String kodeJamKerja;
  final String namaJamKerja;
  final String? jamMasuk;
  final String? jamPulang;
  final int lintashari;
  final int istirahat;
  final String? jamAwalIstirahat;
  final String? jamAkhirIstirahat;

  JamKerjaInfoModel({
    required this.kodeJamKerja,
    required this.namaJamKerja,
    this.jamMasuk,
    this.jamPulang,
    required this.lintashari,
    required this.istirahat,
    this.jamAwalIstirahat,
    this.jamAkhirIstirahat,
  });

  factory JamKerjaInfoModel.fromJson(Map<String, dynamic> json) {
    return JamKerjaInfoModel(
      kodeJamKerja: json['kode_jam_kerja'] as String? ?? '',
      namaJamKerja: json['nama_jam_kerja'] as String? ?? '',
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      lintashari: json['lintashari'] as int? ?? 0,
      istirahat: DashboardModel._parseInt(json['istirahat']) ?? 0,
      jamAwalIstirahat: json['jam_awal_istirahat'] as String?,
      jamAkhirIstirahat: json['jam_akhir_istirahat'] as String?,
    );
  }
}

class TodayAttendanceModel {
  final String? jamIn;
  final String? jamOut;
  final String? fotoIn;
  final String? fotoOut;
  final String? istirahatOut;
  final String? istirahatIn;
  final String? fotoIstirahatOut;
  final String? fotoIstirahatIn;

  TodayAttendanceModel({
    this.jamIn,
    this.jamOut,
    this.fotoIn,
    this.fotoOut,
    this.istirahatOut,
    this.istirahatIn,
    this.fotoIstirahatOut,
    this.fotoIstirahatIn,
  });

  factory TodayAttendanceModel.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceModel(
      jamIn: json['jam_in'] as String?,
      jamOut: json['jam_out'] as String?,
      fotoIn: json['foto_in'] as String?,
      fotoOut: json['foto_out'] as String?,
      istirahatOut: json['istirahat_out'] as String?,
      istirahatIn: json['istirahat_in'] as String?,
      fotoIstirahatOut: json['foto_istirahat_out'] as String?,
      fotoIstirahatIn: json['foto_istirahat_in'] as String?,
    );
  }
}

class MonthlyRecapModel {
  final int hadir;
  final int sakit;
  final int izin;
  final int cuti;
  final int alpa;

  MonthlyRecapModel({
    required this.hadir,
    required this.sakit,
    required this.izin,
    required this.cuti,
    required this.alpa,
  });

  factory MonthlyRecapModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRecapModel(
      hadir: DashboardModel._parseInt(json['hadir']) ?? 0,
      sakit: DashboardModel._parseInt(json['sakit']) ?? 0,
      izin: DashboardModel._parseInt(json['izin']) ?? 0,
      cuti: DashboardModel._parseInt(json['cuti']) ?? 0,
      alpa: DashboardModel._parseInt(json['alpa']) ?? 0,
    );
  }
}

class ContractNotifModel {
  final int sisaHari;
  final String tanggalAkhir;

  ContractNotifModel({
    required this.sisaHari,
    required this.tanggalAkhir,
  });

  factory ContractNotifModel.fromJson(Map<String, dynamic> json) {
    return ContractNotifModel(
      sisaHari: DashboardModel._parseInt(json['sisa_hari']) ?? 0,
      tanggalAkhir: json['tanggal_akhir'] as String? ?? '',
    );
  }
}

class SpNotifModel {
  final String? id;
  final String jenisSp;
  final String sampai;

  SpNotifModel({
    this.id,
    required this.jenisSp,
    required this.sampai,
  });

  factory SpNotifModel.fromJson(Map<String, dynamic> json) {
    return SpNotifModel(
      id: json['id']?.toString(),
      jenisSp: json['jenis_sp'] as String? ?? '',
      sampai: json['sampai'] as String? ?? '',
    );
  }
}

class AnnouncementModel {
  final int? id;
  final String judul;
  final String isi;
  final String createdAt;

  AnnouncementModel({
    this.id,
    required this.judul,
    required this.isi,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: DashboardModel._parseInt(json['id']),
      judul: json['judul'] as String? ?? '',
      isi: json['isi'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
