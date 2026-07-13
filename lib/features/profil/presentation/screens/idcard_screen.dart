import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/constants/app_constants.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:gaweflutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:gaweflutter/core/theme/app_theme_scheme.dart';

class IdCardScreen extends ConsumerStatefulWidget {
  const IdCardScreen({super.key});

  @override
  ConsumerState<IdCardScreen> createState() => _IdCardScreenState();
}

class _IdCardScreenState extends ConsumerState<IdCardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFront = true;
  final GlobalKey _globalKeyFront = GlobalKey();
  final GlobalKey _globalKeyBack = GlobalKey();
  final GlobalKey _globalKeyExportFront = GlobalKey();
  final GlobalKey _globalKeyExportBack = GlobalKey();

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  // Helper to fix localhost urls when testing on physical devices or emulators
  String? _getValidUrl(String? url) {
    if (url == null) return null;
    if (url.contains('localhost')) {
      try {
        final Uri baseUri = Uri.parse(AppConstants.baseUrl);
        final String correctHost = '${baseUri.scheme}://${baseUri.host}:${baseUri.port}';
        return url
            .replaceAll('http://localhost', correctHost)
            .replaceAll('https://localhost', correctHost)
            .replaceAll('localhost', '${baseUri.host}:${baseUri.port}');
      } catch (_) {
        return url;
      }
    }
    return url;
  }

  Future<void> _exportIdCard() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF32745e)),
        ),
      );

      final RenderRepaintBoundary? boundaryFront =
          _globalKeyExportFront.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final RenderRepaintBoundary? boundaryBack =
          _globalKeyExportBack.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundaryFront == null || boundaryBack == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menangkap gambar ID Card.')),
        );
        return;
      }

      final ui.Image imgFront = await boundaryFront.toImage(pixelRatio: 3.0);
      final ByteData? byteDataFront = await imgFront.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytesFront = byteDataFront!.buffer.asUint8List();

      final ui.Image imgBack = await boundaryBack.toImage(pixelRatio: 3.0);
      final ByteData? byteDataBack = await imgBack.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytesBack = byteDataBack!.buffer.asUint8List();

      if (mounted) {
        Navigator.pop(context);
      }

      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'EMPLOYEE ID CARD',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 30),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 220,
                        height: 371,
                        child: pw.Image(pw.MemoryImage(pngBytesFront)),
                      ),
                      pw.SizedBox(width: 40),
                      pw.Container(
                        width: 220,
                        height: 371,
                        child: pw.Image(pw.MemoryImage(pngBytesBack)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'ID_Card_Employee.pdf',
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat mengekspor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dashboardAsync = ref.watch(dashboardProvider);
    final generalSetting = dashboardAsync.value?.generalSetting;
    final companyName = generalSetting?.namaPerusahaan ?? user?.cabang ?? 'E-Presensi';
    final companyAddress = generalSetting?.alamat;
    final companyLogoUrl = _getValidUrl(generalSetting?.logo);
    final userPhotoUrl = _getValidUrl(user?.foto);
    final primaryColor = AppThemeScheme.getPrimary(generalSetting?.mobileThemeScheme);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'E-ID Card',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white),
            tooltip: 'Simpan / Cetak',
            onPressed: _exportIdCard,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Premium Segmented Controller / Switch
                  Center(
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (!_isFront) _toggleCard();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isFront ? primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'DEPAN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isFront ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (_isFront) _toggleCard();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !_isFront ? primaryColor : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'BELAKANG',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !_isFront ? Colors.white : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3D Flip Card Container
                  Center(
                    child: GestureDetector(
                      onTap: _toggleCard,
                      child: AnimatedBuilder(
                        animation: _flipController,
                        builder: (context, child) {
                          final angle = _flipController.value * pi;
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: angle < pi / 2
                                ? _buildCardSide(
                                    key: _globalKeyFront,
                                    isFront: true,
                                    name: user?.name ?? 'Nama Karyawan',
                                    nik: user?.nik ?? '000000',
                                    department: user?.departemen ?? '-',
                                    jobTitle: user?.jabatan ?? '-',
                                    photoUrl: userPhotoUrl,
                                    companyName: companyName,
                                    companyLogoUrl: companyLogoUrl,
                                    companyAddress: companyAddress,
                                    themeScheme: generalSetting?.mobileThemeScheme,
                                  )
                                : Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildCardSide(
                                      key: _globalKeyBack,
                                      isFront: false,
                                      name: user?.name ?? 'Nama Karyawan',
                                      nik: user?.nik ?? '000000',
                                      department: user?.departemen ?? '-',
                                      jobTitle: user?.jabatan ?? '-',
                                      photoUrl: userPhotoUrl,
                                      companyName: companyName,
                                      companyLogoUrl: companyLogoUrl,
                                      companyAddress: companyAddress,
                                      themeScheme: generalSetting?.mobileThemeScheme,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Interactive Tip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 16, color: primaryColor.withValues(alpha: 0.7)),
                        const SizedBox(width: 8),
                        const Text(
                          'Ketuk kartu untuk membalik',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Offscreen capture widget for high-res exporting
          Positioned(
            left: -2000,
            top: -2000,
            child: Row(
              children: [
                _buildCardSide(
                  key: _globalKeyExportFront,
                  isFront: true,
                  name: user?.name ?? 'Nama Karyawan',
                  nik: user?.nik ?? '000000',
                  department: user?.departemen ?? '-',
                  jobTitle: user?.jabatan ?? '-',
                  photoUrl: userPhotoUrl,
                  companyName: companyName,
                  companyLogoUrl: companyLogoUrl,
                  companyAddress: companyAddress,
                  themeScheme: generalSetting?.mobileThemeScheme,
                ),
                const SizedBox(width: 20),
                _buildCardSide(
                  key: _globalKeyExportBack,
                  isFront: false,
                  name: user?.name ?? 'Nama Karyawan',
                  nik: user?.nik ?? '000000',
                  department: user?.departemen ?? '-',
                  jobTitle: user?.jabatan ?? '-',
                  photoUrl: userPhotoUrl,
                  companyName: companyName,
                  companyLogoUrl: companyLogoUrl,
                  companyAddress: companyAddress,
                  themeScheme: generalSetting?.mobileThemeScheme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSide({
    required Key key,
    required bool isFront,
    required String name,
    required String nik,
    required String department,
    required String jobTitle,
    required String? photoUrl,
    required String companyName,
    required String? companyLogoUrl,
    required String? companyAddress,
    required String? themeScheme,
  }) {
    final Color brandGreenStart = AppThemeScheme.getPrimary(themeScheme);
    final Color brandGreenEnd = AppThemeScheme.getLight(themeScheme);
    const Color goldAccent = Color(0xFFC5A880);
    const Color textDark = Color(0xFF1E293B);
    const Color textMuted = Color(0xFF64748B);

    return RepaintBoundary(
      key: key,
      child: Container(
        width: 310,
        height: 520,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Light background stripes (simulating the background pattern)
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPatternPainter(),
              ),
            ),

            isFront
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Upper half: Dark green gradient background with curved bottom
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandGreenStart, brandGreenEnd],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Wave Ornament same as Homepage
                            Positioned.fill(
                              child: CustomPaint(
                                painter: IdCardWavePainter(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 15, bottom: 40, left: 16, right: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) ...[
                                    Image.network(
                                      companyLogoUrl,
                                      height: 55, // Larger logo height (from 35 to 55)
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.shield_outlined,
                                        color: Colors.white,
                                        size: 55,
                                      ),
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.shield_outlined,
                                      color: Colors.white,
                                      size: 55,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    companyName.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (companyAddress != null && companyAddress.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      companyAddress.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 70), // Spacer for overlapping photo

                      // Text and Details section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: brandGreenStart,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${jobTitle.toUpperCase()} - ${department.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: textMuted,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'STAFF KARYAWAN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: goldAccent,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'GPS VERIFIED - $nik',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: brandGreenStart,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Barcode section at the very bottom
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'ID',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CustomPaint(
                                    size: const Size(double.infinity, 28),
                                    painter: BarcodePainter(nik),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    nik,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 2,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back Header Block (Same curvature/style but slightly shorter)
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandGreenStart, brandGreenEnd],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            // Wave Ornament same as Homepage
                            Positioned.fill(
                              child: CustomPaint(
                                painter: IdCardWavePainter(),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    companyName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'SECURITY ACCESS PASSED',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: goldAccent,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Terms and Conditions list
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KETENTUAN PENGGUNAAN KARTU',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: textDark,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildModernTermItem(1, 'Kartu identitas ini wajib selalu dikenakan dan dipasang di posisi yang mudah terlihat selama jam kerja.'),
                            const SizedBox(height: 12),
                            _buildModernTermItem(2, 'Segala bentuk penyalahgunaan atau penggunaan oleh pihak lain yang tidak berhak dapat dikenai sanksi.'),
                            const SizedBox(height: 12),
                            _buildModernTermItem(3, 'Apabila kartu ini hilang atau ditemukan oleh pihak lain, harap segera mengembalikannya ke Bagian HRD.'),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Signature block & Stamps
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Diterbitkan oleh:',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      color: textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    companyName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Sistem Kehadiran Karyawan',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Signature display
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomPaint(
                                  size: const Size(60, 20),
                                  painter: SignaturePainter(),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'HR Manager',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: brandGreenStart,
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 1,
                                  color: const Color(0xFFCBD5E1),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                const Text(
                                  'AUTHORIZED PASS',
                                  style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.bold,
                                    color: textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

            // Overlapping Square Rounded Profile Photo (Front side only)
            if (isFront)
              Positioned(
                top: 145,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(1),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: (photoUrl != null && photoUrl.isNotEmpty)
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.person_rounded,
                                      size: 80,
                                      color: brandGreenStart,
                                    ),
                                  )
                                : Icon(
                                    Icons.person_rounded,
                                    size: 80,
                                    color: brandGreenStart,
                                  ),
                          ),
                        ),
                        // Small diamond badge in the top right corner of the picture frame
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Transform.rotate(
                            angle: pi / 4,
                            child: Container(
                              width: 10,
                              height: 10,
                              color: brandGreenStart,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Laminated plastic gloss overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTermItem(int number, String text) {
    const Color primaryColor = Color(0xFF32745e);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withValues(alpha: 0.08),
            border: Border.all(color: primaryColor.withValues(alpha: 0.15), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF334155),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

// Background pattern painter to draw subtle diagonal stripes
class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F5F9).withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double step = 20;
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom Painter for Stylized Digital Signature
class SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const ui.Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.35,
      size.height * 0.9,
      size.width * 0.5,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.2,
      size.width * 0.75,
      size.height * 0.8,
      size.width * 0.9,
      size.height * 0.5,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BarcodePainter extends CustomPainter {
  final String nik;
  BarcodePainter(this.nik);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final int seed = nik.hashCode;
    final Random random = Random(seed);

    double currentX = 0;
    while (currentX < size.width) {
      final double width = random.nextDouble() < 0.25 ? 1.5 : (random.nextDouble() < 0.55 ? 3.0 : 4.0);
      final double space = random.nextDouble() < 0.5 ? 2.0 : 3.5;

      if (currentX + width <= size.width) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, width, size.height),
          paint,
        );
      }
      currentX += width + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IdCardWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Wave 1 (Upper Wave)
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.065)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.9,
        size.width,
        size.height * 0.7,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Wave 2 (Lower Wave)
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.9,
        size.width * 0.6,
        size.height * 0.68,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.5,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color parseHexColor(String? hexString, Color defaultColor) {
  if (hexString == null || hexString.isEmpty) return defaultColor;
  try {
    String formatted = hexString.replaceAll('#', '');
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
  } catch (_) {
    return defaultColor;
  }
}
