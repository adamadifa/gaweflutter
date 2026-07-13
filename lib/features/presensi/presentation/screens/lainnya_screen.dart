import 'package:flutter/material.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/kunjungan_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/lembur_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/aktivitas_list_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/face_recognition_registration_screen.dart';
import 'package:gaweflutter/features/slip_gaji/presentation/screens/slip_gaji_list_screen.dart';
import 'package:gaweflutter/features/profil/presentation/screens/idcard_screen.dart';
import 'package:gaweflutter/features/kontrak/presentation/screens/kontrak_list_screen.dart';
import 'package:gaweflutter/features/pelanggaran/presentation/screens/pelanggaran_screen.dart';
import 'package:gaweflutter/features/pinjaman/presentation/screens/pinjaman_screen.dart';
import 'package:gaweflutter/features/reimbursement/presentation/screens/reimbursement_list_screen.dart';
import 'package:gaweflutter/features/jadwal/presentation/screens/jadwal_screen.dart';
import 'package:gaweflutter/features/tukar_shift/presentation/screens/tukar_shift_list_screen.dart';
import 'package:gaweflutter/features/kpi/presentation/screens/kpi_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/absen_istirahat_screen.dart';
import 'package:gaweflutter/features/project/presentation/screens/projects_list_screen.dart';

const Color bodyBgColor = Color(0xFFF8FAFC);

class LainnyaScreen extends StatelessWidget {
  const LainnyaScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur $title segera hadir!'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Semua Menu',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // PERSONAL SECTION
          _buildSectionHeader('Personal'),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.badge_outlined,
            title: 'ID Card',
            subtitle: 'Lihat Kartu Identitas Digital',
            backgroundColor: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            onTap: () => _navigateTo(context, const IdCardScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.payments_outlined,
            title: 'Slip Gaji',
            subtitle: 'Download Bukti Gaji Bulanan',
            backgroundColor: const Color(0xFFE6F2ED),
            iconColor: primaryColor,
            onTap: () => _navigateTo(context, const SlipGajiListScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.assignment_outlined,
            title: 'Dokumen Kontrak',
            subtitle: 'Lihat Masa Berlaku Kontrak',
            backgroundColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            onTap: () => _navigateTo(context, const KontrakListScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'Pelanggaran (SP)',
            subtitle: 'Riwayat Surat Peringatan',
            backgroundColor: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFDC2626),
            onTap: () => _navigateTo(context, const PelanggaranScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            title: 'Pinjaman (PJP)',
            subtitle: 'Riwayat & Saldo Pinjaman',
            backgroundColor: const Color(0xFFF0FDFA),
            iconColor: const Color(0xFF0D9488),
            onTap: () => _navigateTo(context, const PinjamanScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.receipt_long_outlined,
            title: 'Reimbursement',
            subtitle: 'Ajukan Klaim Biaya Mandiri',
            backgroundColor: const Color(0xFFFDF2F8),
            iconColor: const Color(0xFFDB2777),
            onTap: () => _navigateTo(context, const ReimbursementListScreen()),
          ),
          
          const SizedBox(height: 24),

          // ABSENSI & HARIAN SECTION
          _buildSectionHeader('Absensi & Harian'),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.calendar_month_outlined,
            title: 'Jadwal Saya',
            subtitle: 'Lihat Jadwal Kerja Bulanan',
            backgroundColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            onTap: () => _navigateTo(context, const JadwalScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.coffee_outlined,
            title: 'Absen Istirahat',
            subtitle: 'Catat Keluar Masuk Istirahat',
            backgroundColor: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFEA580C),
            onTap: () => _navigateTo(context, const AbsenIstirahatScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.more_time_rounded,
            title: 'Lembur Harian',
            subtitle: 'Riwayat Pekerjaan Lembur',
            backgroundColor: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            onTap: () => _navigateTo(context, const LemburListScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.published_with_changes_rounded,
            title: 'Tukar Shift',
            subtitle: 'Ajukan Perubahan Jadwal Kerja',
            backgroundColor: const Color(0xFFE0E7FF),
            iconColor: const Color(0xFF4F46E5),
            onTap: () => _navigateTo(context, const TukarShiftListScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.analytics_outlined,
            title: 'Penilaian KPI',
            subtitle: 'Key Performance Indicator',
            backgroundColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            onTap: () => _navigateTo(context, const KpiScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.face_retouching_natural_rounded,
            title: 'Daftar Face ID',
            subtitle: 'Rekam Data Wajah Presensi',
            backgroundColor: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF475569),
            onTap: () => _navigateTo(context, const FaceRecognitionRegistrationScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.assignment_turned_in_outlined,
            title: 'Project Board',
            subtitle: 'Pantau tugas & progress project',
            backgroundColor: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            onTap: () => _navigateTo(context, const ProjectsListScreen()),
          ),

          const SizedBox(height: 24),

          // KHUSUS SECTION
          _buildSectionHeader('Khusus'),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.trending_up_rounded,
            title: 'Aktivitas Karyawan',
            subtitle: 'Laporan Kegiatan Karyawan',
            backgroundColor: const Color(0xFFFFE4E6),
            iconColor: const Color(0xFFE11D48),
            onTap: () => _navigateTo(context, const AktivitasListScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.map_rounded,
            title: 'Kunjungan / Visit',
            subtitle: 'Titik Kunjungan Pelanggan',
            backgroundColor: const Color(0xFFFAE8FF),
            iconColor: const Color(0xFFC026D3),
            onTap: () => _navigateTo(context, const KunjunganListScreen()),
          ),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.done_all_rounded,
            title: 'Hak Approval',
            subtitle: 'Persetujuan Pengajuan',
            backgroundColor: const Color(0xFFCCFBF1),
            iconColor: const Color(0xFF0F766E),
            onTap: () => _showComingSoon(context, 'Hak Approval'),
          ),

          const SizedBox(height: 24),

          // UMUM SECTION
          _buildSectionHeader('Umum'),
          const SizedBox(height: 8),
          _buildMenuTile(
            context,
            icon: Icons.campaign_outlined,
            title: 'Pengumuman',
            subtitle: 'Pusat Informasi Perusahaan',
            backgroundColor: const Color(0xFFFDF4FF),
            iconColor: const Color(0xFFA21CAF),
            onTap: () => _showComingSoon(context, 'Pengumuman'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
