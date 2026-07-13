import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gaweflutter/features/slip_gaji/data/models/slip_gaji_model.dart';

class SlipGajiPdfHelper {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static Future<void> printSlipGaji(SlipGajiDetail detail, String periodName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'GAWE MOBILE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#32745e'),
                        ),
                      ),
                      pw.Text(
                        'Sistem Payroll Resmi Karyawan',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SLIP GAJI',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#32745e'),
                        ),
                      ),
                      pw.Text(
                        periodName,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#32745e')),
              pw.SizedBox(height: 12),

              // Employee Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('NIK', detail.karyawan.nikShow.isNotEmpty ? detail.karyawan.nikShow : detail.karyawan.nik),
                        _buildInfoRow('Nama', detail.karyawan.namaKaryawan),
                        _buildInfoRow('Jabatan', detail.karyawan.namaJabatan),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Departemen', detail.karyawan.namaDept),
                        _buildInfoRow('Jenis Upah', detail.karyawan.jenisUpah),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Work Summary
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Hari Kerja', '${detail.summary.hariKerja}'),
                    _buildSummaryItem('Kehadiran', '${detail.summary.hariHadir}'),
                    _buildSummaryItem('Terlambat', '${detail.summary.hariTerlambat}'),
                    _buildSummaryItem('Lembur', '${detail.summary.jamLembur} Jam'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Earnings & Deductions Tables
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Earnings (Penerimaan)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'I. PENERIMAAN',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColor.fromHex('#32745e'),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        _buildItemRow('Gaji Pokok', detail.penerimaan.gajiPokok),
                        ...detail.penerimaan.tunjangan.map((t) => _buildItemRow(t.nama, t.jumlah)),
                        if (detail.penerimaan.tunjanganPajak > 0)
                          _buildItemRow('Tunjangan PPh 21', detail.penerimaan.tunjanganPajak),
                        if (detail.penerimaan.upahLembur > 0)
                          _buildItemRow('Upah Lembur', detail.penerimaan.upahLembur),
                        if (detail.penerimaan.penambah > 0)
                          _buildItemRow(
                            detail.penerimaan.keteranganPenyesuaian.isNotEmpty
                                ? 'Adj: ${detail.penerimaan.keteranganPenyesuaian}'
                                : 'Penyesuaian',
                            detail.penerimaan.penambah,
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Deductions (Potongan)
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'II. POTONGAN',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColor.fromHex('#d32f2f'),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        if (detail.potongan.potonganJam > 0)
                          _buildItemRow('Potongan Jam', detail.potongan.potonganJam),
                        if (detail.potongan.denda > 0)
                          _buildItemRow('Denda Keterlambatan', detail.potongan.denda),
                        if (detail.potongan.bpjsKesehatan > 0)
                          _buildItemRow('BPJS Kesehatan', detail.potongan.bpjsKesehatan),
                        if (detail.potongan.bpjsTenagakerja > 0)
                          _buildItemRow('BPJS Ketenagakerjaan', detail.potongan.bpjsTenagakerja),
                        if (detail.potongan.cicilanPinjaman > 0)
                          _buildItemRow('Cicilan Pinjaman', detail.potongan.cicilanPinjaman),
                        if (detail.potongan.potonganPph21 > 0)
                          _buildItemRow('Potongan PPh 21', detail.potongan.potonganPph21),
                        if (detail.potongan.pengurang > 0)
                          _buildItemRow('Potongan Lainnya', detail.potongan.pengurang),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 8),

              // Totals Block
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Total Penerimaan (A):',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Total Potongan (B):',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        _currencyFormat.format(detail.totalPenerimaan),
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        _currencyFormat.format(detail.totalPotongan),
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#214d3e'),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'GAJI BERSIH (A - B):',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.Text(
                      _currencyFormat.format(detail.gajiBersih),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),

              // Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        'Penerima,',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 40),
                      pw.Text(
                        detail.karyawan.namaKaryawan,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Slip_Gaji_${periodName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Text(
            ':  $value',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildItemRow(String name, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            name,
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Text(
            _currencyFormat.format(amount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }
}
