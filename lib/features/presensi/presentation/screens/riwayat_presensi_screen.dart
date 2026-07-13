import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gaweflutter/data/models/riwayat_model.dart';
import 'package:gaweflutter/features/presensi/presentation/providers/presensi_provider.dart';

class RiwayatPresensiScreen extends ConsumerStatefulWidget {
  const RiwayatPresensiScreen({super.key});

  @override
  ConsumerState<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends ConsumerState<RiwayatPresensiScreen> {
  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2D5A4C);
    const Color bodyBgColor = Color(0xFFE8F0ED);

    final selectedDate = ref.watch(riwayatBulanTahunProvider);
    final riwayatAsync = ref.watch(riwayatProvider);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Histori Kehadiran',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Month selector header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: primaryColor),
                  onPressed: () {
                    final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1);
                    ref.read(riwayatBulanTahunProvider.notifier).setDate(prevMonth);
                  },
                ),
                Text(
                  _getMonthYearLabelIndo(selectedDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: primaryColor),
                  onPressed: () {
                    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
                    ref.read(riwayatBulanTahunProvider.notifier).setDate(nextMonth);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),

          // Main content
          Expanded(
            child: riwayatAsync.when(
              data: (riwayatList) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Visual Calendar Grid
                      _buildCalendarGrid(selectedDate, riwayatList, primaryColor),

                      // History list section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rincian Kehadiran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (riwayatList.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Tidak ada data kehadiran pada bulan ini',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: riwayatList.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = riwayatList[index];
                                  return _buildRiwayatCard(item, primaryColor);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat data: ${error.toString().replaceAll('Exception: ', '')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(riwayatProvider),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthYearLabelIndo(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  Widget _buildCalendarGrid(DateTime selectedDate, List<RiwayatModel> riwayatList, Color primaryColor) {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOffset = DateTime(selectedDate.year, selectedDate.month, 1).weekday - 1; // 0 for Monday

    // Map of day to status
    final Map<int, RiwayatModel> riwayatMap = {};
    for (var r in riwayatList) {
      final dt = DateTime.tryParse(r.tanggal);
      if (dt != null && dt.month == selectedDate.month && dt.year == selectedDate.year) {
        riwayatMap[dt.day] = r;
      }
    }

    // Days label (Mo, Tu, We, Th, Fr, Sa, Su)
    final dayLabels = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          // Day labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels.map((lbl) {
              return SizedBox(
                width: 40,
                child: Text(
                  lbl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Calendar cells Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 weeks max
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayOffset + 1;
              if (dayNumber <= 0 || dayNumber > daysInMonth) {
                return const SizedBox.shrink(); // Empty cell
              }

              final riwayat = riwayatMap[dayNumber];
              Color cellColor = const Color(0xFFF1F5F9);
              Color textColor = const Color(0xFF1E293B);

              if (riwayat != null) {
                final status = riwayat.status.toLowerCase();
                if (status == 'h') {
                  cellColor = primaryColor.withValues(alpha: 0.15);
                  textColor = primaryColor;
                } else if (status == 's') {
                  cellColor = const Color(0xFFFF9800).withValues(alpha: 0.15);
                  textColor = const Color(0xFFE65100);
                } else if (status == 'i') {
                  cellColor = const Color(0xFF2196F3).withValues(alpha: 0.15);
                  textColor = const Color(0xFF0D47A1);
                } else if (status == 'c') {
                  cellColor = const Color(0xFFFF5252).withValues(alpha: 0.15);
                  textColor = const Color(0xFFB71C1C);
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(RiwayatModel item, Color primaryColor) {
    // Parse status details
    String statusText = 'Hadir';
    Color statusColor = primaryColor;
    Color statusBg = primaryColor.withValues(alpha: 0.1);

    final status = item.status.toLowerCase();
    if (status == 's') {
      statusText = 'Sakit';
      statusColor = const Color(0xFFFF9800);
      statusBg = const Color(0xFFFF9800).withValues(alpha: 0.1);
    } else if (status == 'i') {
      statusText = 'Izin';
      statusColor = const Color(0xFF2196F3);
      statusBg = const Color(0xFF2196F3).withValues(alpha: 0.1);
    } else if (status == 'c') {
      statusText = 'Cuti';
      statusColor = const Color(0xFFFF5252);
      statusBg = const Color(0xFFFF5252).withValues(alpha: 0.1);
    }

    // Parse date
    DateTime? dt = DateTime.tryParse(item.tanggal);
    String dateLabel = item.tanggal;
    if (dt != null) {
      dateLabel = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status == 'h')
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                          image: (item.fotoIn != null)
                              ? DecorationImage(
                                  image: NetworkImage(item.fotoIn!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: item.fotoIn == null
                            ? Icon(Icons.camera_alt_outlined, color: primaryColor, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Masuk',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            item.jamIn ?? '--:--',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[200]!),
                          image: (item.fotoOut != null)
                              ? DecorationImage(
                                  image: NetworkImage(item.fotoOut!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: item.fotoOut == null
                            ? Icon(Icons.camera_alt_outlined, color: primaryColor, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pulang',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            item.jamOut ?? '--:--',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          else if (item.keterangan != null && item.keterangan!.isNotEmpty)
            Text(
              'Keterangan: ${item.keterangan}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}
