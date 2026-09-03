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
    const Color primaryColor = Color(0xFF1E6152);
    const Color bodyBgColor = Color(0xFFF9FBFA);

    final selectedDate = ref.watch(riwayatBulanTahunProvider);
    final riwayatAsync = ref.watch(riwayatProvider);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Histori Kehadiran',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.1,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Month selector bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1);
                    ref.read(riwayatBulanTahunProvider.notifier).setDate(prevMonth);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: Color(0xFF334155), size: 20),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      _getMonthYearLabelIndo(selectedDate),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
                    ref.read(riwayatBulanTahunProvider.notifier).setDate(nextMonth);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Color(0xFF334155), size: 20),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),

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
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rincian Kehadiran Harian',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (riwayatList.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.15),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.event_busy_rounded, size: 28, color: primaryColor),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Tidak ada riwayat kehadiran pada bulan ini',
                                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
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
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 44),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat data: ${error.toString().replaceAll('Exception: ', '')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(riwayatProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Coba Lagi'),
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

    final Map<int, RiwayatModel> riwayatMap = {};
    for (var r in riwayatList) {
      final dt = DateTime.tryParse(r.tanggal);
      if (dt != null && dt.month == selectedDate.month && dt.year == selectedDate.year) {
        riwayatMap[dt.day] = r;
      }
    }

    final dayLabels = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels.map((lbl) {
              return SizedBox(
                width: 36,
                child: Text(
                  lbl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - firstDayOffset + 1;
              if (dayNumber <= 0 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final riwayat = riwayatMap[dayNumber];
              Color cellColor = const Color(0xFFF8FAFC);
              Color textColor = const Color(0xFF334155);
              Border? border = Border.all(color: const Color(0xFFF1F5F9), width: 1);

              if (riwayat != null) {
                final status = riwayat.status.toLowerCase();
                if (status == 'h') {
                  cellColor = const Color(0xFFF0FDF4);
                  textColor = const Color(0xFF16A34A);
                  border = Border.all(color: const Color(0xFFBBF7D0), width: 1);
                } else if (status == 's') {
                  cellColor = const Color(0xFFFEF2F2);
                  textColor = const Color(0xFFE11D48);
                  border = Border.all(color: const Color(0xFFFECDD3), width: 1);
                } else if (status == 'i') {
                  cellColor = const Color(0xFFF0F9FF);
                  textColor = const Color(0xFF0284C7);
                  border = Border.all(color: const Color(0xFFBAE6FD), width: 1);
                } else if (status == 'c') {
                  cellColor = const Color(0xFFECFDF5);
                  textColor = const Color(0xFF059669);
                  border = Border.all(color: const Color(0xFFA7F3D0), width: 1);
                }
              }

              return Container(
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(8),
                  border: border,
                ),
                alignment: Alignment.center,
                child: Text(
                  dayNumber.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
    String statusText = 'Hadir';
    Color statusColor = const Color(0xFF16A34A);
    Color statusBg = const Color(0xFFF0FDF4);
    IconData statusIcon = Icons.check_circle_outline_rounded;

    final status = item.status.toLowerCase();
    if (status == 's') {
      statusText = 'Sakit';
      statusColor = const Color(0xFFE11D48);
      statusBg = const Color(0xFFFEF2F2);
      statusIcon = Icons.medical_services_outlined;
    } else if (status == 'i') {
      statusText = 'Izin';
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFF0F9FF);
      statusIcon = Icons.calendar_today_rounded;
    } else if (status == 'c') {
      statusText = 'Cuti';
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFECFDF5);
      statusIcon = Icons.beach_access_outlined;
    }

    DateTime? dt = DateTime.tryParse(item.tanggal);
    String dateLabel = item.tanggal;
    if (dt != null) {
      dateLabel = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 11.5, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status == 'h')
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            image: (item.fotoIn != null)
                                ? DecorationImage(
                                    image: NetworkImage(item.fotoIn!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: item.fotoIn == null
                              ? const Icon(Icons.login_rounded, color: Color(0xFF10B981), size: 15)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Masuk',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            Text(
                              item.jamIn ?? '--:--',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            image: (item.fotoOut != null)
                                ? DecorationImage(
                                    image: NetworkImage(item.fotoOut!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: item.fotoOut == null
                              ? const Icon(Icons.logout_rounded, color: Color(0xFFF59E0B), size: 15)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pulang',
                              style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            Text(
                              item.jamOut ?? '--:--',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else if (item.keterangan != null && item.keterangan!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Text(
                'Keterangan: ${item.keterangan}',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF475569),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
