import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/kontrak/data/repositories/kontrak_repository.dart';
import 'package:gaweflutter/features/kontrak/presentation/providers/kontrak_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class KontrakDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const KontrakDetailScreen({super.key, required this.id});

  @override
  ConsumerState<KontrakDetailScreen> createState() => _KontrakDetailScreenState();
}

class _KontrakDetailScreenState extends ConsumerState<KontrakDetailScreen> {
  bool _isDownloading = false;

  /// Strip inline width/margin-left styles from td and table elements
  /// so the customStylesBuilder can properly control column widths.
  String _cleanContractHtml(String html) {
    var cleaned = html;
    // Remove all inline width styles like: width: 200px; width: 10px; width: 120px; width: 55%;
    for (var i = 1; i <= 500; i++) {
      cleaned = cleaned.replaceAll('width: ${i}px;', '');
      cleaned = cleaned.replaceAll('width: ${i}px', '');
      cleaned = cleaned.replaceAll('width:${i}px;', '');
      cleaned = cleaned.replaceAll('width:${i}px', '');
    }
    for (var i = 1; i <= 100; i++) {
      cleaned = cleaned.replaceAll('width: $i%;', '');
      cleaned = cleaned.replaceAll('width: $i%', '');
      cleaned = cleaned.replaceAll('width:$i%;', '');
      cleaned = cleaned.replaceAll('width:$i%', '');
    }
    // Remove margin-left styles
    for (var i = 1; i <= 100; i++) {
      cleaned = cleaned.replaceAll('margin-left: ${i}px;', '');
      cleaned = cleaned.replaceAll('margin-left: ${i}px', '');
      cleaned = cleaned.replaceAll('margin-left:${i}px;', '');
      cleaned = cleaned.replaceAll('margin-left:${i}px', '');
    }
    // Remove HTML width attributes
    cleaned = cleaned.replaceAll('width="100%"', '');
    cleaned = cleaned.replaceAll('width="50%"', '');
    cleaned = cleaned.replaceAll('width="200"', '');
    // Remove empty style attributes
    cleaned = cleaned.replaceAll('style=" "', '');
    cleaned = cleaned.replaceAll('style=""', '');
    cleaned = cleaned.replaceAll('style="  "', '');
    return cleaned;
  }


  Future<void> _downloadAndPrintPdf(String noKontrak) async {
    setState(() {
      _isDownloading = true;
    });

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
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(kontrakDetailProvider(widget.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Kontrak',
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
          final isActive = detail.statusKontrak == '1';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: const Color(0xFF32745e).withOpacity(0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'STATUS DOKUMEN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF32745e),
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isActive ? 'Aktif' : 'Non-Aktif',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          detail.noDokumen ?? detail.noKontrak,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Premium Contract Document Container (Paper view)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top decorative line
                      Container(
                        height: 6,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF32745e), Color(0xFF4b9b82)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: HtmlWidget(
                          _cleanContractHtml(detail.kontenHtml),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: Color(0xFF334155),
                          ),
                          customStylesBuilder: (element) {
                            if (element.localName == 'table') {
                              return {
                                'width': '100%',
                                'border-collapse': 'collapse',
                                'margin-top': '8px',
                                'margin-bottom': '8px',
                                'margin-left': '0',
                              };
                            }
                            if (element.localName == 'td') {
                              final text = element.text.trim();
                              final isColon = element.classes.contains('colon') || text == ':';
                              final isValue = element.classes.contains('value');
                              final isLabel = element.classes.contains('label');

                              if (isLabel) {
                                return {
                                  'padding': '4px 2px',
                                  'vertical-align': 'top',
                                };
                              } else if (isColon) {
                                return {
                                  'padding': '4px 4px',
                                  'vertical-align': 'top',
                                };
                              } else if (isValue) {
                                return {
                                  'padding': '4px 2px',
                                  'vertical-align': 'top',
                                  'text-align': 'right',
                                  'font-weight': 'bold',
                                };
                              } else {
                                return {
                                  'padding': '4px 2px',
                                  'vertical-align': 'top',
                                };
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button Download/Print
                ElevatedButton.icon(
                  onPressed: _isDownloading ? null : () => _downloadAndPrintPdf(detail.noKontrak),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.print_outlined, color: Colors.white),
                  label: Text(
                    _isDownloading ? 'Mengunduh...' : 'Cetak / Download PDF',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF32745e),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
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
                  onPressed: () => ref.invalidate(kontrakDetailProvider(widget.id)),
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
