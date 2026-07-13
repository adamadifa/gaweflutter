import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/slip_gaji/presentation/providers/slip_gaji_provider.dart';
import 'package:gaweflutter/features/slip_gaji/presentation/screens/slip_gaji_detail_screen.dart';
import 'package:intl/intl.dart';

class SlipGajiListScreen extends ConsumerStatefulWidget {
  const SlipGajiListScreen({super.key});

  @override
  ConsumerState<SlipGajiListScreen> createState() => _SlipGajiListScreenState();
}

class _SlipGajiListScreenState extends ConsumerState<SlipGajiListScreen> {
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  String _formatPeriodDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slipGajiList = ref.watch(slipGajiListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Slip Gaji',
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(slipGajiListProvider);
        },
        color: const Color(0xFF32745e),
        child: slipGajiList.when(
          data: (periods) {
            final years = periods.map((e) => e.tahun).toSet().toList()..sort((a, b) => b.compareTo(a));
            
            final filteredPeriods = _selectedYear == null
                ? periods
                : periods.where((p) => p.tahun == _selectedYear).toList();

            if (periods.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada slip gaji yang diterbitkan.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year filter selector
                if (years.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Semua'),
                            selected: _selectedYear == null,
                            selectedColor: const Color(0xFF32745e),
                            labelStyle: TextStyle(
                              color: _selectedYear == null ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedYear = null;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ...years.map((year) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('$year'),
                                selected: _selectedYear == year,
                                selectedColor: const Color(0xFF32745e),
                                labelStyle: TextStyle(
                                  color: _selectedYear == year ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedYear = selected ? year : null;
                                  });
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: filteredPeriods.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada slip gaji untuk tahun ini.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredPeriods.length,
                          itemBuilder: (context, index) {
                            final period = filteredPeriods[index];
                            final startFormatted = _formatPeriodDate(period.periodeDari);
                            final endFormatted = _formatPeriodDate(period.periodeSampai);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: const Color(0xFF32745e).withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                              color: Colors.white,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SlipGajiDetailScreen(
                                        bulan: period.bulan,
                                        tahun: period.tahun,
                                        periodName: '${period.namaBulan} ${period.tahun}',
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF32745e).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.assignment_outlined,
                                          color: Color(0xFF32745e),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Slip Gaji ${period.namaBulan} ${period.tahun}',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 14,
                                                  color: Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$startFormatted - $endFormatted',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Color(0xFF32745e),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
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
                    onPressed: () => ref.invalidate(slipGajiListProvider),
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
      ),
    );
  }
}
