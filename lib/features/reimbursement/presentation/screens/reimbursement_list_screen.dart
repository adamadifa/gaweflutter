import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/reimbursement/presentation/providers/reimbursement_provider.dart';
import 'package:gaweflutter/features/reimbursement/presentation/screens/reimbursement_create_screen.dart';
import 'package:gaweflutter/features/reimbursement/presentation/screens/reimbursement_detail_screen.dart';
import 'package:intl/intl.dart';

class ReimbursementListScreen extends ConsumerStatefulWidget {
  const ReimbursementListScreen({super.key});

  @override
  ConsumerState<ReimbursementListScreen> createState() => _ReimbursementListScreenState();
}

class _ReimbursementListScreenState extends ConsumerState<ReimbursementListScreen> {
  DateTime _currentFilterDate = DateTime.now();

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      try {
        final date = DateTime.parse(dateStr);
        return DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {
        return dateStr;
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'P':
        return const Color(0xFFF59E0B); // Pending (orange)
      case 'A':
        return const Color(0xFF10B981); // Approved (green)
      case 'R':
        return const Color(0xFFEF4444); // Rejected (red)
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'P':
        return 'Pending';
      case 'A':
        return 'Disetujui';
      case 'R':
        return 'Ditolak';
      default:
        return 'Batal';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'P':
        return Icons.access_time_rounded;
      case 'A':
        return Icons.check_circle_outline_rounded;
      case 'R':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // Get localized filter month text: "01 sd 30 Jun 2026"
  String _getFilterText(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    
    final dayFrom = DateFormat('dd').format(firstDay);
    final dayTo = DateFormat('dd').format(lastDay);
    
    // Translate month manually to match indonesian
    final monthYear = DateFormat('MMM yyyy', 'id_ID').format(firstDay);
    return "$dayFrom sd $dayTo $monthYear";
  }

  @override
  Widget build(BuildContext context) {
    final claimsState = ref.watch(reimbursementListProvider);
    const Color primaryColor = Color(0xFF32745e);
    const Color bodyBgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bodyBgColor,
      body: claimsState.when(
        data: (claims) {
          // Filter claims matching current month & year
          final filteredClaims = claims.where((c) {
            try {
              final date = DateTime.parse(c.tanggalPengajuan);
              return date.year == _currentFilterDate.year && date.month == _currentFilterDate.month;
            } catch (_) {
              return true; // Keep if date parsing fails to avoid losing data
            }
          }).toList();

          // Calculate total reimbursement for this period (excluding Rejected 'R')
          final totalAmountPeriod = filteredClaims
              .where((c) => c.status.toUpperCase() != 'R')
              .fold(0.0, (sum, item) => sum + item.totalNominal);

          return Stack(
            children: [
              // Custom Header Banner (match #header-custom style)
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
                        // Custom Header Nav Row
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
                                'Reimbursement',
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
                        // Total Section
                        Column(
                          children: [
                            const Text(
                              'Total reimbursement bulan ini',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatCurrency(totalAmountPeriod),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Klik pengajuan untuk melihat detail\nHanya menampilkan data yang tidak ditolak',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Scrollable Content
              Positioned.fill(
                top: 255, // Starts slightly overlapping the header
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(reimbursementListProvider);
                  },
                  color: primaryColor,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                    children: [
                      // Filter Card (Monthly navigation)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _currentFilterDate = DateTime(
                                    _currentFilterDate.year,
                                    _currentFilterDate.month - 1,
                                    1,
                                  );
                                });
                              },
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B), size: 18),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              _getFilterText(_currentFilterDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _currentFilterDate = DateTime(
                                    _currentFilterDate.year,
                                    _currentFilterDate.month + 1,
                                    1,
                                  );
                                });
                              },
                              icon: const Icon(Icons.arrow_forward, color: Color(0xFF64748B), size: 18),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (filteredClaims.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Color(0xFFCBD5E1),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada pengajuan reimbursement.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredClaims.map((item) {
                          final statusColor = _getStatusColor(item.status);
                          final dateFormatted = _formatDate(item.tanggalPengajuan);

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
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                 borderRadius: BorderRadius.circular(12),
                                 onTap: () async {
                                   final res = await Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => ReimbursementDetailScreen(id: item.id),
                                     ),
                                   );
                                   if (res == true && mounted) {
                                     ref.invalidate(reimbursementListProvider);
                                   }
                                 },
                                 child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Card Row Top
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            item.noReimbursement,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF334155),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _getStatusIcon(item.status),
                                                size: 14,
                                                color: statusColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getStatusLabel(item.status),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Card Row Bottom
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.catatan ?? '-',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  dateFormatted,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF94A3B8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            _formatCurrency(item.totalNominal),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: primaryColor,
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
                        }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
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
                  onPressed: () => ref.invalidate(reimbursementListProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReimbursementCreateScreen(),
            ),
          );
          if (res == true) {
            ref.invalidate(reimbursementListProvider);
          }
        },
        backgroundColor: primaryColor,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

