import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/pelanggaran/presentation/providers/pelanggaran_provider.dart';
import 'package:intl/intl.dart';

class PelanggaranDetailScreen extends ConsumerStatefulWidget {
  final String noSp;
  const PelanggaranDetailScreen({super.key, required this.noSp});

  @override
  ConsumerState<PelanggaranDetailScreen> createState() => _PelanggaranDetailScreenState();
}

class _PelanggaranDetailScreenState extends ConsumerState<PelanggaranDetailScreen> {
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return dateStr;
      }
    }
  }

  Color _getSpColor(String jenisSp) {
    switch (jenisSp.toUpperCase()) {
      case 'SP1':
      case 'SP 1':
        return Colors.orange;
      case 'SP2':
      case 'SP 2':
        return Colors.deepOrange;
      case 'SP3':
      case 'SP 3':
        return Colors.red;
      default:
        return const Color(0xFF32745e);
    }
  }

  String _getSpLabel(String jenisSp) {
    switch (jenisSp.toUpperCase()) {
      case 'SP1':
      case 'SP 1':
        return 'SURAT PERINGATAN KESATU (SP 1)';
      case 'SP2':
      case 'SP 2':
        return 'SURAT PERINGATAN KEDUA (SP 2)';
      case 'SP3':
      case 'SP 3':
        return 'SURAT PERINGATAN KETIGA (SP 3)';
      default:
        return 'SURAT PERINGATAN ($jenisSp)';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(110),
          1: FixedColumnWidth(15),
          2: FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                ':',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(pelanggaranDetailProvider(widget.noSp));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Pelanggaran',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF32745e),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: detailState.when(
        data: (detail) {
          final spColor = _getSpColor(detail.jenisSp);
          final tglFormatted = _formatDate(detail.tanggal);
          final dariFormatted = _formatDate(detail.dari);
          final sampaiFormatted = _formatDate(detail.sampai);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Header Badge
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: spColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: spColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: spColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: Aktif',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: spColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Berlaku s/d $sampaiFormatted',
                              style: TextStyle(
                                fontSize: 11,
                                color: spColor.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Official Document Paper Look
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top indicator line
                      Container(
                        height: 6,
                        color: spColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Company Header
                            Text(
                              (detail.namaPerusahaan ?? 'PERUSAHAAN').toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detail.namaCabang.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(thickness: 1.5, color: Color(0xFF475569)),
                            const SizedBox(height: 16),

                            // Document Title
                            Text(
                              _getSpLabel(detail.jenisSp),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nomor: ${detail.noDokumen ?? detail.noSp}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Recipient Info
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Diberikan Kepada:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('Nama', detail.namaKaryawan),
                                  _buildInfoRow('NIK', detail.nikShow),
                                  _buildInfoRow('Jabatan', detail.namaJabatan),
                                  _buildInfoRow('Departemen', detail.namaDept),
                                  _buildInfoRow('Cabang', detail.namaCabang),
                                  _buildInfoRow('Alamat', detail.alamat ?? 'Di Tempat'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Letter Content Body
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sehubungan dengan hasil evaluasi kinerja dan kedisiplinan yang dilakukan Departemen ${detail.namaDept}, kami memberikan surat peringatan ini sebagai tindak lanjut dari ketidakpatuhan Saudara/i terhadap peraturan dan kebijakan perusahaan. Kami mencatat pelanggaran sebagai berikut:',
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Violation description box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                detail.keterangan,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: 1.5,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Warning text & Validity Period info
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Berdasarkan hal tersebut, dengan ini kami memberikan Surat Peringatan ini kepada Saudara/i. Harap surat ini dijadikan bahan introspeksi dan motivasi untuk memperbaiki sikap serta kinerja yang bersangkutan kedepannya.',
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Masa berlaku Surat Peringatan ini terhitung mulai dari tanggal $dariFormatted sampai dengan tanggal $sampaiFormatted.',
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  height: 1.6,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Footer Place & Date
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${detail.namaCabang}, $tglFormatted',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Signature Layout
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Penerima,',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 60),
                                    Text(
                                      detail.namaKaryawan,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const Text(
                                      'Karyawan',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Pemberi Peringatan,',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 60),
                                    const Text(
                                      'HRD / Manajemen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    Text(
                                      detail.namaPerusahaan ?? 'Perusahaan',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF32745e)),
        ),
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
                  onPressed: () => ref.invalidate(pelanggaranDetailProvider(widget.noSp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32745e),
                  ),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
