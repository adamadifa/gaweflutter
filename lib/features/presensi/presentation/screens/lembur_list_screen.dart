import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/repositories/lembur_repository.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/lembur_form_screen.dart';
import 'package:gaweflutter/features/presensi/presentation/screens/lembur_presensi_screen.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFF32745e);

class LemburListScreen extends ConsumerStatefulWidget {
  const LemburListScreen({super.key});

  @override
  ConsumerState<LemburListScreen> createState() => _LemburListScreenState();
}

class _LemburListScreenState extends ConsumerState<LemburListScreen> {
  bool _isLoading = true;
  List<dynamic> _lemburList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLemburList();
  }

  Future<void> _fetchLemburList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(lemburRepositoryProvider);
      final result = await repository.getLemburList();
      if (mounted) {
        setState(() {
          _lemburList = result['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '-';
    try {
      // If it's already HH:mm format
      if (dateTimeStr.length == 5 && dateTimeStr.contains(':')) {
        return dateTimeStr;
      }
      final date = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(date);
    } catch (_) {
      return dateTimeStr;
    }
  }

  Widget _getStatusChip(int status) {
    String label = 'Pending';
    Color bgColor = Colors.amber.shade50;
    Color textColor = Colors.amber.shade800;

    if (status == 1) {
      label = 'Disetujui';
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else if (status == 2) {
      label = 'Ditolak';
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Daftar Lembur',
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchLemburList,
          )
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LemburFormScreen(),
            ),
          );
          if (result == true) {
            _fetchLemburList();
          }
        },
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajukan Lembur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchLemburList,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_lemburList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_time_rounded, size: 70, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Belum ada data pengajuan lembur.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLemburList,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _lemburList.length,
        itemBuilder: (context, index) {
          final item = _lemburList[index];
          final int status = int.tryParse(item['status']?.toString() ?? '0') ?? 0;
          final int idLembur = int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          final String? lemburIn = item['lembur_in'];
          final String? lemburOut = item['lembur_out'];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(item['tanggal']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      _getStatusChip(status),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeInfo(
                          'Rencana Jam',
                          '${_formatTime(item['lembur_mulai'])} - ${_formatTime(item['lembur_selesai'])}',
                          Icons.schedule_outlined,
                        ),
                      ),
                      Expanded(
                        child: _buildTimeInfo(
                          'Realisasi Jam',
                          '${_formatTime(lemburIn)} - ${_formatTime(lemburOut)}',
                          Icons.play_circle_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTimeInfo(
                    'Keterangan / Tugas',
                    item['keterangan'] ?? '-',
                    Icons.description_outlined,
                  ),
                  if (status == 1) ...[
                    const SizedBox(height: 16),
                    _buildActionButton(idLembur, lemburIn, lemburOut),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(int idLembur, String? lemburIn, String? lemburOut) {
    if (lemburIn == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _navigateToAbsen(idLembur, 1),
          icon: const Icon(Icons.login_rounded, size: 18),
          label: const Text('Mulai Lembur (Absen Masuk)', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      );
    } else if (lemburOut == null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _navigateToAbsen(idLembur, 2),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text('Selesai Lembur (Absen Pulang)', style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
            SizedBox(width: 6),
            Text(
              'Lembur Selesai & Tercatat',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToAbsen(int idLembur, int status) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LemburPresensiScreen(
          idLembur: idLembur,
          status: status,
        ),
      ),
    );
    if (result == true) {
      _fetchLemburList();
    }
  }
}
