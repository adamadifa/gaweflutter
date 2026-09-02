import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gaweflutter/features/approval/data/models/approval_model.dart';
import 'package:gaweflutter/features/approval/presentation/providers/approval_provider.dart';

class ApprovalDetailSheet extends ConsumerStatefulWidget {
  final ApprovalItem item;
  final VoidCallback? onSuccess;

  const ApprovalDetailSheet({
    super.key,
    required this.item,
    this.onSuccess,
  });

  @override
  ConsumerState<ApprovalDetailSheet> createState() => _ApprovalDetailSheetState();
}

class _ApprovalDetailSheetState extends ConsumerState<ApprovalDetailSheet> {
  final TextEditingController _catatanController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'absen':
        return const Color(0xFF2563EB); // Biru
      case 'sakit':
        return const Color(0xFFE11D48); // Merah muda / Rose
      case 'cuti':
        return const Color(0xFFD97706); // Amber / Oranye
      case 'dinas':
        return const Color(0xFF0F766E); // Teal / Hijau toska
      case 'reimbursement':
        return const Color(0xFF7C3AED); // Ungu
      default:
        return const Color(0xFF32745E);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'absen':
        return Icons.event_note_rounded;
      case 'sakit':
        return Icons.medical_services_outlined;
      case 'cuti':
        return Icons.beach_access_rounded;
      case 'dinas':
        return Icons.work_outline_rounded;
      case 'reimbursement':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  String _formatDateRange(String? dari, String? sampai) {
    if (dari == null) return '-';
    try {
      final d1 = DateTime.parse(dari);
      final f1 = DateFormat('d MMM yyyy', 'id_ID').format(d1);
      if (sampai == null || dari == sampai) return f1;
      final d2 = DateTime.parse(sampai);
      final f2 = DateFormat('d MMM yyyy', 'id_ID').format(d2);
      return '$f1 - $f2';
    } catch (_) {
      return '$dari - ${sampai ?? ''}';
    }
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return 'Rp 0';
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  Future<void> _handleAction(String action) async {
    final isApprove = action == 'approve';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isApprove ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApprove ? Icons.check_rounded : Icons.close_rounded,
                color: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isApprove ? 'Setujui Pengajuan?' : 'Tolak Pengajuan?',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: Text(
          isApprove
              ? 'Pengajuan ${widget.item.typeLabel} an. ${widget.item.namaKaryawan} akan disetujui untuk Tahap ${widget.item.approvalStep}.'
              : 'Pengajuan ${widget.item.typeLabel} an. ${widget.item.namaKaryawan} akan ditolak.',
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF32745E) : const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              isApprove ? 'Ya, Setujui' : 'Ya, Tolak',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final success = await ref.read(approvalActionProvider.notifier).process(
          type: widget.item.type,
          kode: widget.item.kode,
          action: action,
          catatan: _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      widget.onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pengajuan berhasil ${isApprove ? "disetujui" : "ditolak"}!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isApprove ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      final errorState = ref.read(approvalActionProvider);
      final errorMsg = errorState.errorMessage ?? 'Gagal memproses pengajuan.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 300,
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.white,
                  child: const Center(
                    child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(widget.item.type);
    final isReimbursement = widget.item.type == 'reimbursement';
    final isSakit = widget.item.type == 'sakit';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            // Sheet Title & Badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getTypeIcon(widget.item.type), color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review ${widget.item.typeLabel}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          widget.item.kode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Tahap ${widget.item.approvalStep}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Content Body Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: typeColor.withValues(alpha: 0.15),
                            child: Text(
                              widget.item.namaKaryawan.isNotEmpty ? widget.item.namaKaryawan[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: typeColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.namaKaryawan,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.item.nik} • ${widget.item.namaJabatan}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.item.namaDept} • ${widget.item.namaCabang}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Detail Specs
                    _buildSectionHeader('Rincian Pengajuan'),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          if (!isReimbursement) ...[
                            _buildDetailRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Periode Izin',
                              value: _formatDateRange(widget.item.dari, widget.item.sampai),
                              highlightValue: true,
                            ),
                            _buildDetailRow(
                              icon: Icons.timelapse_rounded,
                              label: 'Durasi Hari',
                              value: '${widget.item.durasiHari} Hari',
                            ),
                          ] else ...[
                            _buildDetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Total Pengajuan',
                              value: _formatCurrency(widget.item.totalNominal),
                              highlightValue: true,
                              valueColor: const Color(0xFF16A34A),
                            ),
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Tanggal Pengajuan',
                              value: widget.item.tanggalPengajuan ?? '-',
                            ),
                          ],
                          _buildDetailRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: isReimbursement ? 'Catatan Global' : 'Alasan / Keterangan',
                            value: widget.item.keterangan?.isNotEmpty == true ? widget.item.keterangan! : '-',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),

                    // If Sakit & Has SID Attachment
                    if (isSakit && widget.item.docSidUrl != null) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader('Surat Izin Dokter (SID)'),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _showImagePreview(context, widget.item.docSidUrl!),
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            image: DecorationImage(
                              image: NetworkImage(widget.item.docSidUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            alignment: Alignment.bottomRight,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Ketuk untuk perbesar',
                                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    // If Reimbursement & Has Details Items
                    if (isReimbursement && widget.item.details.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _buildSectionHeader('Rincian Item Nota (${widget.item.details.length})'),
                      const SizedBox(height: 10),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.item.details.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final d = widget.item.details[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                if (d.fotoNota != null) ...[
                                  GestureDetector(
                                    onTap: () => _showImagePreview(context, d.fotoNota!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        d.fotoNota!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 48,
                                          height: 48,
                                          color: const Color(0xFFCBD5E1),
                                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.namaJenis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      if (d.keterangan?.isNotEmpty == true)
                                        Text(
                                          d.keterangan!,
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (d.tanggalTransaksi != null)
                                        Text(
                                          d.tanggalTransaksi!,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatCurrency(d.nominal),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Catatan Approval Input
                    _buildSectionHeader('Catatan Approval (Opsional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _catatanController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Tuliskan catatan persetujuan / penolakan jika ada...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: typeColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(color: Color(0xFF32745E)),
                      ),
                    )
                  : Row(
                      children: [
                        // Button Tolak
                        Expanded(
                          flex: 1,
                          child: OutlinedButton.icon(
                            onPressed: () => _handleAction('tolak'),
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFDC2626)),
                            label: const Text(
                              'Tolak',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 14),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                              backgroundColor: const Color(0xFFFEF2F2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Button Approve
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAction('approve'),
                            icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                            label: const Text(
                              'Setujui (Approve)',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF32745E),
                              elevation: 2,
                              shadowColor: const Color(0xFF32745E).withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF475569),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlightValue = false,
    Color? valueColor,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlightValue ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? (highlightValue ? const Color(0xFF0F172A) : const Color(0xFF334155)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
