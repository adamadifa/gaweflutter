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
    const Color primaryColor = Color(0xFF2D5A4C);
    const Color bodyBgColor = Color(0xFFE8F0ED);
    final izinListAsync = ref.watch(izinListProvider);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Daftar Ajuan Izin',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D5A4C), Color(0xFF4E8A75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _showJenisIzinSelector(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          label: const Text(
            'Buat Ajuan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Pilih Jenis Pengajuan Izin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              _buildJenisIzinTile(
                context,
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF2563EB),
                title: 'Izin Absen',
                subtitle: 'Izin tidak masuk kerja karena keperluan tertentu',
                value: 'i',
              ),
              _buildJenisIzinTile(
                context,
                icon: Icons.medical_services_rounded,
                color: const Color(0xFFEF4444),
                title: 'Izin Sakit',
                subtitle: 'Izin sakit (wajib melampirkan Surat Dokter)',
                value: 's',
              ),
              _buildJenisIzinTile(
                context,
                icon: Icons.beach_access_rounded,
                color: const Color(0xFF10B981),
                title: 'Cuti',
                subtitle: 'Pengajuan cuti tahunan atau cuti khusus',
                value: 'c',
              ),
              _buildJenisIzinTile(
                context,
                icon: Icons.business_center_rounded,
                color: const Color(0xFF8B5CF6),
                title: 'Dinas',
                subtitle: 'Tugas luar kota atau keperluan dinas kantor',
                value: 'd',
              ),
              const SizedBox(height: 12),
            ],
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IzinFormScreen(initialJenisIzin: value),
          ),
        );
      },
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
          // ===== SUMMARY CARDS =====
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Ajuan',
                    count: total.toString(),
                    icon: Icons.assignment_outlined,
                    iconColor: primaryColor,
                    bgColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Disetujui',
                    count: approved.toString(),
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Pending',
                    count: pending.toString(),
                    icon: Icons.pending_actions_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    bgColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
            child: Text(
              'Riwayat Pengajuan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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

  Widget _buildSummaryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
        typeColor = const Color(0xFF2563EB); // Blue
        typeIcon = Icons.calendar_today_rounded;
        break;
      case 's':
        typeLabel = 'Izin Sakit';
        typeColor = const Color(0xFFEF4444); // Red
        typeIcon = Icons.medical_services_rounded;
        break;
      case 'c':
        typeLabel = 'Cuti';
        typeColor = const Color(0xFF10B981); // Green
        typeIcon = Icons.beach_access_rounded;
        break;
      case 'd':
        typeLabel = 'Dinas';
        typeColor = const Color(0xFF8B5CF6); // Purple
        typeIcon = Icons.business_center_rounded;
        break;
      case 'k':
        typeLabel = 'Koreksi Absen';
        typeColor = const Color(0xFFF59E0B); // Amber
        typeIcon = Icons.edit_calendar_rounded;
        break;
    }

    // Setup status labels
    String statusText = 'Pending';
    Color statusBg = const Color(0xFFFFF3CD);
    Color statusFg = const Color(0xFF856404);
    IconData statusIcon = Icons.hourglass_empty_rounded;

    if (item.status == 1) {
      statusText = 'Disetujui';
      statusBg = const Color(0xFFD1E7DD);
      statusFg = const Color(0xFF0F5132);
      statusIcon = Icons.check_circle_rounded;
    } else if (item.status == 2) {
      statusText = 'Ditolak';
      statusBg = const Color(0xFFF8D7DA);
      statusFg = const Color(0xFF842029);
      statusIcon = Icons.cancel_rounded;
    }

    // Parse date ranges
    final fromDate = DateTime.tryParse(item.dari);
    final toDate = DateTime.tryParse(item.sampai);
    String dateRangeStr = '${item.dari} s/d ${item.sampai}';
    int totalDays = 1;

    if (fromDate != null && toDate != null) {
      dateRangeStr = '${DateFormat('d MMM y').format(fromDate)} - ${DateFormat('d MMM y').format(toDate)}';
      totalDays = toDate.difference(fromDate).inDays + 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: typeColor,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(typeIcon, color: typeColor, size: 15),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    typeLabel,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '$totalDays Hari',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, color: statusFg, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateRangeStr,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alasan / Keterangan:',
                              style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.keterangan,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF334155), height: 1.4),
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
                                    color: primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: primaryColor.withOpacity(0.15)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.attach_file_rounded, size: 14, color: primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Lihat Lampiran (SID)',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
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
                                    color: Colors.red.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.withOpacity(0.15)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                                      SizedBox(width: 4),
                                      Text(
                                        'Batalkan',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
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
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today_rounded, size: 50, color: primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum Ada Ajuan Izin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Riwayat pengajuan izin, sakit, cuti atau dinas Anda akan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(izinListProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}
