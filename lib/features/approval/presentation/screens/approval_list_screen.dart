import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gaweflutter/features/approval/data/models/approval_model.dart';
import 'package:gaweflutter/features/approval/presentation/providers/approval_provider.dart';
import 'package:gaweflutter/features/approval/presentation/screens/approval_detail_sheet.dart';

class ApprovalListScreen extends ConsumerWidget {
  const ApprovalListScreen({super.key});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'absen':
        return const Color(0xFF2563EB); // Blue
      case 'sakit':
        return const Color(0xFFE11D48); // Rose
      case 'cuti':
        return const Color(0xFFD97706); // Amber
      case 'dinas':
        return const Color(0xFF0F766E); // Teal
      case 'reimbursement':
        return const Color(0xFF7C3AED); // Purple
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

  void _openDetailSheet(BuildContext context, WidgetRef ref, ApprovalItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApprovalDetailSheet(
        item: item,
        onSuccess: () => ref.invalidate(approvalListProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color primaryColor = Color(0xFF32745E);
    const Color bodyBgColor = Color(0xFFF8FAFC);
    final approvalAsync = ref.watch(approvalListProvider);
    final selectedFilter = ref.watch(selectedApprovalFilterProvider);
    final filteredItems = ref.watch(filteredApprovalItemsProvider);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Hak Approval Delegasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(approvalListProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(approvalListProvider),
        color: primaryColor,
        child: approvalAsync.when(
          data: (data) {
            if (!data.hasAccess) {
              return _buildNoAccessState(context, data.message);
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header Summary Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildDelegationHeaderCard(data),
                  ),
                ),

                // Category Tabs Filter
                if (data.summary != null)
                  SliverToBoxAdapter(
                    child: _buildFilterChips(context, ref, data.summary!, selectedFilter),
                  ),

                // Section List Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getFilterTitle(selectedFilter),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filteredItems.length} Menunggu',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // List Items or Empty State
                if (filteredItems.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filteredItems[index];
                          return _buildApprovalCard(context, ref, item);
                        },
                        childCount: filteredItems.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: primaryColor),
          ),
          error: (err, stack) => _buildErrorState(ref, err.toString()),
        ),
      ),
    );
  }

  Widget _buildDelegationHeaderCard(ApprovalResponseData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1F4D3D),
            Color(0xFF32745E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF32745E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle circle decoration
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Wewenang Delegasi Admin',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.admin?.name ?? '-',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.admin?.role ?? 'Administrator',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${data.summary?.totalPending ?? 0}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
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
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    ApprovalSummary summary,
    String currentFilter,
  ) {
    final filters = [
      {'key': 'all', 'label': 'Semua', 'count': summary.totalPending},
      {'key': 'absen', 'label': 'Izin Absen', 'count': summary.countAbsen},
      {'key': 'sakit', 'label': 'Sakit', 'count': summary.countSakit},
      {'key': 'cuti', 'label': 'Cuti', 'count': summary.countCuti},
      {'key': 'dinas', 'label': 'Dinas', 'count': summary.countDinas},
      {'key': 'reimbursement', 'label': 'Reimburse', 'count': summary.countReimbursement},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = currentFilter == f['key'];
          final count = f['count'] as int;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF32745E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF32745E) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : const Color(0xFF32745E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              onSelected: (_) {
                ref.read(selectedApprovalFilterProvider.notifier).setFilter(f['key'] as String);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApprovalCard(BuildContext context, WidgetRef ref, ApprovalItem item) {
    final typeColor = _getTypeColor(item.type);
    final isReimbursement = item.type == 'reimbursement';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetailSheet(context, ref, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Type Badge + Step Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getTypeIcon(item.type), size: 14, color: typeColor),
                          const SizedBox(width: 5),
                          Text(
                            item.typeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Tahap ${item.approvalStep}',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Employee Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: typeColor.withValues(alpha: 0.12),
                      child: Text(
                        item.namaKaryawan.isNotEmpty ? item.namaKaryawan[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 14,
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
                            item.namaKaryawan,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.namaDept} • ${item.namaJabatan}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Bottom Content: Dates / Amount + Button Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isReimbursement) ...[
                            Row(
                              children: [
                                const Icon(Icons.date_range_rounded, size: 14, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatDateRange(item.dari, item.sampai),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (item.keterangan?.isNotEmpty == true) ...[
                              const SizedBox(height: 3),
                              Text(
                                item.keterangan!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ] else ...[
                            Text(
                              _formatCurrency(item.totalNominal),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.keterangan ?? '-',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF32745E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Proses',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 54,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Semua Pengajuan Selesai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tidak ada pengajuan izin atau reimbursement yang menunggu persetujuan Anda saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 6),
            Text(
              error.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(approvalListProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF32745E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAccessState(BuildContext context, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(
                Icons.shield_outlined,
                size: 52,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Akses Belum Didelegasikan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Akun karyawan Anda saat ini belum memiliki delegasi hak approval dari Administrator.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hubungi Admin / HRD untuk mendelegasikan wewenang approval ke akun Anda.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
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

  String _getFilterTitle(String filter) {
    switch (filter) {
      case 'absen':
        return 'Izin Absen Pending';
      case 'sakit':
        return 'Izin Sakit Pending';
      case 'cuti':
        return 'Izin Cuti Pending';
      case 'dinas':
        return 'Izin Dinas Pending';
      case 'reimbursement':
        return 'Reimbursement Pending';
      default:
        return 'Semua Pengajuan Pending';
    }
  }
}
