import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/kontrak/data/models/kontrak_model.dart';
import 'package:gaweflutter/features/kontrak/data/repositories/kontrak_repository.dart';
import 'package:gaweflutter/features/kontrak/presentation/providers/kontrak_provider.dart';
import 'package:printing/printing.dart';

class KontrakDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const KontrakDetailScreen({super.key, required this.id});

  @override
  ConsumerState<KontrakDetailScreen> createState() => _KontrakDetailScreenState();
}

class _KontrakDetailScreenState extends ConsumerState<KontrakDetailScreen> {
  bool _isDownloading = false;

  static const _primary = Color(0xFF32745e);
  static const _bg = Color(0xFFF4F7F6);
  static const _textDark = Color(0xFF1E293B);
  static const _textMuted = Color(0xFF64748B);

  Future<void> _downloadAndPrintPdf(String noKontrak) async {
    setState(() => _isDownloading = true);
    try {
      final repository = ref.read(kontrakRepositoryProvider);
      final bytes = await repository.downloadContractPdf(widget.id);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Kontrak_${noKontrak.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  String _formatCurrency(double amount) {
    final buffer = StringBuffer('Rp ');
    final parts = amount.toStringAsFixed(0).split('');
    int count = 0;
    for (int i = parts.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write('.');
      buffer.write(parts[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(kontrakDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Detail Kontrak',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: _primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: detailState.when(
        data: (detail) => _buildContent(detail),
        loading: () => const Center(child: CircularProgressIndicator(color: _primary)),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildContent(KontrakDetailModel detail) {
    final isActive = detail.statusKontrak == '1';
    final totalTunjangan = detail.tunjangan.fold(0.0, (s, t) => s + t.jumlah);
    final totalGaji = detail.gajiPokok + totalTunjangan;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header Badge ───────────────────────────────────────────
          _buildHeaderCard(detail, isActive),
          const SizedBox(height: 16),

          // ─── Masa Kontrak ────────────────────────────────────────────
          _buildSection(
            icon: Icons.calendar_today_rounded,
            title: 'Masa Kontrak',
            child: Row(
              children: [
                Expanded(
                  child: _buildDateChip(
                    label: 'Mulai',
                    value: detail.dari,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: _textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDateChip(
                    label: 'Berakhir',
                    value: detail.sampai,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Pihak Pertama ────────────────────────────────────────────
          _buildSection(
            icon: Icons.business_rounded,
            title: 'Pihak Pertama (Perusahaan)',
            child: Column(
              children: [
                _buildInfoRow('Nama', detail.namaHrd),
                _buildInfoRow('Jabatan', detail.jabatanHrd),
                _buildInfoRow('Perusahaan', detail.namaPerusahaan),
                _buildInfoRow('Alamat', detail.alamatPerusahaan, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Pihak Kedua ──────────────────────────────────────────────
          _buildSection(
            icon: Icons.person_rounded,
            title: 'Pihak Kedua (Karyawan)',
            child: Column(
              children: [
                _buildInfoRow('Nama', detail.namaKaryawan),
                _buildInfoRow('Tempat, Tgl Lahir', '${detail.tempatLahir}, ${detail.tanggalLahir}'),
                _buildInfoRow('Pendidikan', detail.pendidikanTerakhir),
                _buildInfoRow('Jenis Kelamin', detail.jenisKelamin),
                _buildInfoRow('Alamat', detail.alamatKaryawan),
                _buildInfoRow('No. KTP / SIM', detail.noKtp),
                _buildInfoRow('No. Telepon', detail.noHp, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Info Pekerjaan ───────────────────────────────────────────
          _buildSection(
            icon: Icons.work_rounded,
            title: 'Informasi Pekerjaan',
            child: Column(
              children: [
                _buildInfoRow('Jabatan', detail.namaJabatan),
                _buildInfoRow('Departemen', detail.namaDept),
                _buildInfoRow('Cabang', detail.namaCabang, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Kompensasi ───────────────────────────────────────────────
          _buildSection(
            icon: Icons.payments_rounded,
            title: 'Kompensasi',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSalaryRow('Gaji Pokok', detail.gajiPokok, isBold: false),
                if (detail.tunjangan.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Tunjangan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMuted, letterSpacing: 0.5)),
                  ),
                  ...detail.tunjangan.where((t) => t.jumlah > 0).map((t) => _buildSalaryRow(t.jenis, t.jumlah)),
                ],
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Gaji', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _textDark)),
                    Text(
                      _formatCurrency(totalGaji),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Print Button ─────────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : () => _downloadAndPrintPdf(detail.noKontrak),
            icon: _isDownloading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.print_rounded, color: Colors.white, size: 20),
            label: Text(
              _isDownloading ? 'Mengunduh...' : 'Cetak / Download PDF',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shadowColor: _primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Header Card ─────────────────────────────────────────────────────────────
  Widget _buildHeaderCard(KontrakDetailModel detail, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: _primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.noDokumen ?? detail.noKontrak,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  detail.jenisKontrak == 'T' ? 'PKWTT — Tetap' : 'PKWT — Tertentu',
                  style: const TextStyle(fontSize: 12, color: _textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 12,
                  color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Aktif' : 'Non-Aktif',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Card ─────────────────────────────────────────────────────────────
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1E293B).withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _primary, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ─── Info Row ────────────────────────────────────────────────────────────────
  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: _textMuted),
            ),
          ),
          const Text(':', style: TextStyle(fontSize: 12.5, color: _textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _textDark),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Date Chip ───────────────────────────────────────────────────────────────
  Widget _buildDateChip({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8), fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ─── Salary Row ──────────────────────────────────────────────────────────────
  Widget _buildSalaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? _textDark : _textMuted,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 13,
              color: isBold ? _primary : _textDark,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(kontrakDetailProvider(widget.id)),
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
