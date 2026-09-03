import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gaweflutter/features/izin/presentation/providers/izin_provider.dart';
import 'package:gaweflutter/features/izin/data/models/izin_model.dart';
import 'package:gaweflutter/features/izin/presentation/screens/izin_form_screen.dart';
import 'package:gaweflutter/features/izin/data/repositories/izin_repository.dart';

class IzinListScreen extends ConsumerWidget {
  const IzinListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color primaryColor = Color(0xFF1E6152); // Brand deep green
    const Color bodyBgColor = Color(0xFFF9FBFA);
    final izinListAsync = ref.watch(izinListProvider);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Ajuan Izin',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 17,
            letterSpacing: 0.1,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.white),
            tooltip: 'Segarkan',
            onPressed: () => ref.invalidate(izinListProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(izinListProvider),
        color: primaryColor,
        child: izinListAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return _buildEmptyState(context, primaryColor);
            }
            return _buildContent(context, ref, list, primaryColor);
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (err, stack) => _buildErrorState(ref, err.toString(), primaryColor),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _showJenisIzinSelector(context),
        backgroundColor: primaryColor,
        elevation: 3,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Buat Ajuan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  void _showJenisIzinSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Jenis Pengajuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tentukan kategori izin yang ingin Anda ajukan',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _buildJenisIzinTile(
                  context,
                  icon: Icons.calendar_today_rounded,
                  color: const Color(0xFF0284C7),
                  title: 'Izin Absen',
                  subtitle: 'Izin tidak masuk kerja karena keperluan tertentu',
                  value: 'i',
                ),
                const SizedBox(height: 8),
                _buildJenisIzinTile(
                  context,
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFFE11D48),
                  title: 'Izin Sakit',
                  subtitle: 'Izin sakit (wajib melampirkan Surat Dokter)',
                  value: 's',
                ),
                const SizedBox(height: 8),
                _buildJenisIzinTile(
                  context,
                  icon: Icons.beach_access_outlined,
                  color: const Color(0xFF10B981),
                  title: 'Cuti',
                  subtitle: 'Pengajuan cuti tahunan atau cuti khusus',
                  value: 'c',
                ),
                const SizedBox(height: 8),
                _buildJenisIzinTile(
                  context,
                  icon: Icons.business_center_outlined,
                  color: const Color(0xFF8B5CF6),
                  title: 'Dinas',
                  subtitle: 'Tugas dinas atau keperluan dinas di luar kantor',
                  value: 'd',
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildJenisIzinTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IzinFormScreen(initialJenisIzin: value),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<IzinModel> list, Color primaryColor) {
    // Calculate summaries
    final total = list.length;
    final approved = list.where((e) => e.status == 1).length;
    final pending = list.where((e) => e.status == 0).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== ELEGANT SUMMARY METRICS =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.15),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactStatItem(
                      title: 'Total Ajuan',
                      count: total.toString(),
                      icon: Icons.assignment_outlined,
                      iconColor: primaryColor,
                    ),
                  ),
                  _buildVerticalDivider(),
                  Expanded(
                    child: _buildCompactStatItem(
                      title: 'Disetujui',
                      count: approved.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF10B981),
                    ),
                  ),
                  _buildVerticalDivider(),
                  Expanded(
                    child: _buildCompactStatItem(
                      title: 'Pending',
                      count: pending.toString(),
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(22, 14, 22, 8),
            child: Text(
              'Riwayat Pengajuan',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),

          // ===== LIST ITEMS =====
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildIzinItem(context, ref, item, primaryColor);
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 28,
      width: 1.1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildCompactStatItem({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIzinItem(BuildContext context, WidgetRef ref, IzinModel item, Color primaryColor) {
    // Setup labels based on permission type ('ket')
    String typeLabel = '';
    Color typeColor = Colors.grey;
    IconData typeIcon = Icons.info_outline;

    switch (item.ket) {
      case 'i':
        typeLabel = 'Izin Absen';
        typeColor = const Color(0xFF0284C7); // Blue
        typeIcon = Icons.calendar_today_rounded;
        break;
      case 's':
        typeLabel = 'Izin Sakit';
        typeColor = const Color(0xFFE11D48); // Red
        typeIcon = Icons.medical_services_outlined;
        break;
      case 'c':
        typeLabel = 'Cuti';
        typeColor = const Color(0xFF10B981); // Green
        typeIcon = Icons.beach_access_outlined;
        break;
      case 'd':
        typeLabel = 'Dinas';
        typeColor = const Color(0xFF8B5CF6); // Purple
        typeIcon = Icons.business_center_outlined;
        break;
      case 'k':
        typeLabel = 'Koreksi Absen';
        typeColor = const Color(0xFFD97706); // Amber
        typeIcon = Icons.edit_calendar_rounded;
        break;
    }

    // Setup status labels
    String statusText = 'Pending';
    Color statusBg = const Color(0xFFFFFBEB);
    Color statusFg = const Color(0xFFD97706);
    IconData statusIcon = Icons.schedule_rounded;

    if (item.status == 1) {
      statusText = 'Disetujui';
      statusBg = const Color(0xFFF0FDF4);
      statusFg = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (item.status == 2) {
      statusText = 'Ditolak';
      statusBg = const Color(0xFFFEF2F2);
      statusFg = const Color(0xFFDC2626);
      statusIcon = Icons.highlight_off_rounded;
    }

    // Parse date ranges
    final fromDate = DateTime.tryParse(item.dari);
    final toDate = DateTime.tryParse(item.sampai);
    String dateRangeStr = '${item.dari} s/d ${item.sampai}';
    int totalDays = 1;

    if (fromDate != null && toDate != null) {
      dateRangeStr = '${DateFormat('d MMM y', 'id_ID').format(fromDate)} - ${DateFormat('d MMM y', 'id_ID').format(toDate)}';
      totalDays = toDate.difference(fromDate).inDays + 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type Badge and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(typeIcon, color: typeColor, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusFg, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusFg,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Date & Days count Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_outlined, size: 15, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      dateRangeStr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    '$totalDays Hari',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Reason / Alasan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KETERANGAN / ALASAN',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.keterangan.isNotEmpty ? item.keterangan : '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            // Action buttons row (Attachment / Cancel)
            if (item.docSidUrl != null || (item.status == 0 && item.ket != 'k')) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.docSidUrl != null) ...[
                    InkWell(
                      onTap: () {
                        _showImageDialog(context, item.docSidUrl!);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file_rounded, size: 13, color: primaryColor),
                            const SizedBox(width: 4),
                            Text(
                              'Lihat Lampiran (SID)',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (item.status == 0 && item.ket != 'k') ...[
                    InkWell(
                      onTap: () {
                        _showCancelConfirmationDialog(context, ref, item.kode);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 13, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Batalkan',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, WidgetRef ref, String kode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Batalkan Pengajuan?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pengajuan izin ini? Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kembali',
              style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final messenger = ScaffoldMessenger.of(context);
              
              // Show progress indicator
              messenger.showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Membatalkan pengajuan...'),
                    ],
                  ),
                  duration: Duration(days: 1), // keeps visible until dismissed
                ),
              );

              try {
                final repo = ref.read(izinRepositoryProvider);
                await repo.cancelIzin(kode);
                
                // Clear progress Snack bar
                messenger.clearSnackBars();
                
                // Show success
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Pengajuan berhasil dibatalkan'),
                    backgroundColor: Color(0xFF2D5A4C),
                  ),
                );

                // Refresh provider
                ref.invalidate(izinListProvider);
              } catch (e) {
                // Clear progress Snack bar
                messenger.clearSnackBars();
                
                // Show error
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal membatalkan: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lampiran Surat Dokter (SID)', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Gagal memuat gambar lampiran.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.event_note_rounded, size: 44, color: primaryColor),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Ada Ajuan Izin',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Riwayat pengajuan izin, sakit, cuti atau dinas Anda akan otomatis tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data: ${error.replaceAll('Exception: ', '')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(izinListProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
