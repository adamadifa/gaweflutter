import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/tukar_shift/presentation/providers/tukar_shift_provider.dart';
import 'package:gaweflutter/features/tukar_shift/data/repositories/tukar_shift_repository.dart';
import 'package:gaweflutter/features/tukar_shift/presentation/screens/tukar_shift_create_screen.dart';
import 'package:intl/intl.dart';

class TukarShiftListScreen extends ConsumerWidget {
  const TukarShiftListScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'p':
        return Colors.orange;
      case 'a':
        return Colors.green;
      case 'r':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'p':
        return 'Pending';
      case 'a':
        return 'Disetujui';
      case 'r':
        return 'Ditolak';
      default:
        return 'Batal';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'p':
        return Icons.hourglass_empty;
      case 'a':
        return Icons.check_circle_outline;
      case 'r':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _cancelRequest(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pengajuan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin membatalkan pengajuan tukar shift ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repository = ref.read(tukarShiftRepositoryProvider);
      await repository.cancelTukarShift(id);
      
      ref.invalidate(tukarShiftDataProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan tukar shift berhasil dibatalkan'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftState = ref.watch(tukarShiftDataProvider);
    const primaryColor = Color(0xFF32745e);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Header Banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, Color(0xFF439075)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.chevron_left, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Tukar Shift',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title & Description
                    shiftState.when(
                      data: (res) {
                        final pendingCount = res.requests.where((r) => r.status.toLowerCase() == 'p').length;
                        return Column(
                          children: [
                            const Text(
                              'Pengajuan Perubahan Jadwal',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$pendingCount Pengajuan Pending',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ajukan perubahan shift atau jadwal kerja harian Anda',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                      error: (_, __) => const Center(
                        child: Text(
                          'Tukar Shift Kerja',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable list
          Positioned.fill(
            top: 235,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(tukarShiftDataProvider);
              },
              color: primaryColor,
              child: shiftState.when(
                data: (res) {
                  final list = res.requests;
                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz_outlined, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada pengajuan tukar shift',
                                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Tekan tombol + di kanan bawah untuk membuat pengajuan baru',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final statusColor = _getStatusColor(item.status);
                      final isPending = item.status.toLowerCase() == 'p';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top header row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(item.tanggal),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_getStatusIcon(item.status), color: statusColor, size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getStatusLabel(item.status),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20, color: Color(0xFFF1F5F9)),

                              // Shift Flow Display
                              Row(
                                children: [
                                  // Initial Shift info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Shift Awal',
                                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.namaJamKerjaAwal,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.jamMasukAwal != null)
                                          Text(
                                            '${item.jamMasukAwal} - ${item.jamPulangAwal}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Flow arrow
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward_rounded, color: primaryColor, size: 16),
                                  ),

                                  // Target Shift info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Shift Tujuan',
                                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.namaJamKerjaTujuan,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.jamMasukTujuan != null)
                                          Text(
                                            '${item.jamMasukTujuan} - ${item.jamPulangTujuan}',
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Keterangan / Notes
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alasan / Keterangan:',
                                      style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.keterangan,
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                    ),
                                  ],
                                ),
                              ),

                              // Cancel Button if Pending
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _cancelRequest(context, ref, item.id),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(Icons.delete_outline, size: 14),
                                    label: const Text(
                                      'Batalkan Pengajuan',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(err.toString(), style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final responseData = shiftState.asData?.value;
          if (responseData == null) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TukarShiftCreateScreen(shifts: responseData.shifts),
            ),
          );

          if (result == true) {
            ref.invalidate(tukarShiftDataProvider);
          }
        },
        backgroundColor: primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
