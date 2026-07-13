import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/slip_gaji/presentation/providers/slip_gaji_provider.dart';
import 'package:gaweflutter/features/slip_gaji/presentation/helpers/slip_gaji_pdf_helper.dart';
import 'package:intl/intl.dart';

class SlipGajiDetailScreen extends ConsumerWidget {
  final int bulan;
  final int tahun;
  final String periodName;

  const SlipGajiDetailScreen({
    super.key,
    required this.bulan,
    required this.tahun,
    required this.periodName,
  });

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(slipGajiDetailProvider('$bulan-$tahun'));
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Slip Gaji',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          detailState.maybeWhen(
            data: (detail) => IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              onPressed: () =>
                  SlipGajiPdfHelper.printSlipGaji(detail, periodName),
              tooltip: 'Cetak Slip Gaji',
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailState.when(
        data: (detail) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Info Card
                Container(
                  width: double.infinity,
                  color: primaryColor,
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    top: 8,
                  ),
                  child: Column(
                    children: [
                      // Employee meta details
                      Text(
                        detail.karyawan.namaKaryawan,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detail.karyawan.namaJabatan} • ${detail.karyawan.namaDept}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Net Salary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'GAJI BERSIH (TAKE HOME PAY)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatCurrency(detail.gajiBersih),
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Periode: $periodName',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Work Summary Section
                      const Text(
                        'Ringkasan Kerja',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Hari Kerja',
                              '${detail.summary.hariKerja}',
                              Icons.calendar_month_outlined,
                              primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              'Kehadiran',
                              '${detail.summary.hariHadir}',
                              Icons.check_circle_outline,
                              primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              'Terlambat',
                              '${detail.summary.hariTerlambat}',
                              Icons.timer_outlined,
                              primaryColor,
                              isWarning: detail.summary.hariTerlambat > 0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              'Lembur',
                              '${detail.summary.jamLembur}h',
                              Icons.schedule_outlined,
                              primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Earnings (Penerimaan) Card
                      _buildBreakdownCard(
                        title: 'I. Penerimaan',
                        icon: Icons.add_circle_outline,
                        iconColor: primaryColor,
                        total: detail.totalPenerimaan,
                        items: [
                          _buildDetailRow(
                            'Gaji Pokok',
                            detail.penerimaan.gajiPokok,
                          ),
                          ...detail.penerimaan.tunjangan.map(
                            (t) => _buildDetailRow(t.nama, t.jumlah),
                          ),
                          if (detail.penerimaan.tunjanganPajak > 0)
                            _buildDetailRow(
                              'Tunjangan PPh 21',
                              detail.penerimaan.tunjanganPajak,
                            ),
                          if (detail.penerimaan.upahLembur > 0)
                            _buildDetailRow(
                              'Upah Lembur',
                              detail.penerimaan.upahLembur,
                            ),
                          if (detail.penerimaan.penambah > 0)
                            _buildDetailRow(
                              detail.penerimaan.keteranganPenyesuaian.isNotEmpty
                                  ? 'Penyesuaian: ${detail.penerimaan.keteranganPenyesuaian}'
                                  : 'Penyesuaian Penambah',
                              detail.penerimaan.penambah,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Deductions (Potongan) Card
                      _buildBreakdownCard(
                        title: 'II. Potongan',
                        icon: Icons.remove_circle_outline,
                        iconColor: const Color(0xFFD32F2F),
                        total: detail.totalPotongan,
                        items: [
                          if (detail.potongan.potonganJam > 0)
                            _buildDetailRow(
                              'Potongan Jam',
                              detail.potongan.potonganJam,
                            ),
                          if (detail.potongan.denda > 0)
                            _buildDetailRow(
                              'Denda Keterlambatan',
                              detail.potongan.denda,
                            ),
                          if (detail.potongan.bpjsKesehatan > 0)
                            _buildDetailRow(
                              'BPJS Kesehatan',
                              detail.potongan.bpjsKesehatan,
                            ),
                          if (detail.potongan.bpjsTenagakerja > 0)
                            _buildDetailRow(
                              'BPJS Ketenagakerjaan',
                              detail.potongan.bpjsTenagakerja,
                            ),
                          if (detail.potongan.cicilanPinjaman > 0)
                            _buildDetailRow(
                              'Cicilan Pinjaman',
                              detail.potongan.cicilanPinjaman,
                            ),
                          if (detail.potongan.potonganPph21 > 0)
                            _buildDetailRow(
                              'Potongan PPh 21',
                              detail.potongan.potonganPph21,
                            ),
                          if (detail.potongan.pengurang > 0)
                            _buildDetailRow(
                              'Potongan Lainnya',
                              detail.potongan.pengurang,
                            ),
                        ],
                        isDeduction: true,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  err.toString().replaceAll('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(slipGajiDetailProvider('$bulan-$tahun')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color primaryColor, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: isWarning ? Colors.amber : primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.amber[800] : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double total,
    required List<Widget> items,
    bool isDeduction = false,
  }) {
    final validItems = items.where((widget) => widget is! SizedBox).toList();
    if (validItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...items,
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isDeduction ? 'Total Potongan' : 'Total Penerimaan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                  ),
                ),
                Text(
                  _formatCurrency(total),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount) {
    if (amount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
