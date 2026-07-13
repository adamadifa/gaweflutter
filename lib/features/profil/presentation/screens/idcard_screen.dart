import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:gaweflutter/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _exportIdCard() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2D5A4C)),
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

      Navigator.pop(context);

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
    const Color primaryColor = Color(0xFF2D5A4C);
    final user = ref.watch(authProvider).user;
    final dashboardAsync = ref.watch(dashboardProvider);
    final generalSetting = dashboardAsync.value?.generalSetting;
    final companyName = generalSetting?.namaPerusahaan ?? user?.cabang ?? 'E-Presensi';
    final companyLogoUrl = generalSetting?.logo;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // modern slate background
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
          IconButton(
            icon: const Icon(Icons.flip_rounded, size: 20, color: Colors.white),
            tooltip: 'Balik Kartu',
            onPressed: _toggleCard,
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
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
                              ..setEntry(3, 2, 0.001) // perspective
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
                                    photoUrl: user?.foto,
                                    companyName: companyName,
                                    companyLogoUrl: companyLogoUrl,
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
                                      photoUrl: user?.foto,
                                      companyName: companyName,
                                      companyLogoUrl: companyLogoUrl,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Tip Text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Text(
                          'Ketuk kartu untuk membalik',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Offscreen capture widget (positioned far offstage to be painted but invisible)
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
                  photoUrl: user?.foto,
                  companyName: companyName,
                  companyLogoUrl: companyLogoUrl,
                ),
                const SizedBox(width: 20),
                _buildCardSide(
                  key: _globalKeyExportBack,
                  isFront: false,
                  name: user?.name ?? 'Nama Karyawan',
                  nik: user?.nik ?? '000000',
                  department: user?.departemen ?? '-',
                  jobTitle: user?.jabatan ?? '-',
                  photoUrl: user?.foto,
                  companyName: companyName,
                  companyLogoUrl: companyLogoUrl,
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
  }) {
    const Color brandDarkGreen = Color(0xFF2D5A4C);
    const Color goldAccent = Color(0xFFC5A880);
    const Color textDark = Color(0xFF0F172A);
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
              color: const Color(0xFF0F172A).withOpacity(0.12),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Stack(
          children: [
            // Background Watermark / Geometric Line (subtle)
            Positioned(
              right: -80,
              bottom: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandDarkGreen.withOpacity(0.02),
                  border: Border.all(color: brandDarkGreen.withOpacity(0.03), width: 2),
                ),
              ),
            ),
            isFront
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Elegant Corporate Header
                      Container(
                        height: 125,
                        decoration: const BoxDecoration(
                          color: brandDarkGreen,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) ...[
                                        Image.network(
                                          companyLogoUrl,
                                          height: 20,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.business_rounded,
                                            color: goldAccent,
                                            size: 20,
                                          ),
                                        ),
                                      ] else ...[
                                        const Icon(
                                          Icons.business_rounded,
                                          color: goldAccent,
                                          size: 20,
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Text(
                                        companyName.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'OFFICIAL ID CARD',
                                    style: TextStyle(
                                      color: goldAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Gold Divider Line
                      Container(
                        height: 3,
                        color: goldAccent,
                      ),
                      // Avatar Photo with formal rectangular border
                      Transform.translate(
                        offset: const Offset(0, -35),
                        child: Center(
                          child: Container(
                            width: 100,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: goldAccent, width: 2.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: (photoUrl != null && photoUrl.isNotEmpty)
                                  ? Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.person_outline_rounded,
                                        size: 50,
                                        color: brandDarkGreen,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline_rounded,
                                      size: 50,
                                      color: brandDarkGreen,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      // Name & Job Title details
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                name.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: textDark,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                jobTitle.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: goldAccent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Structured Info Grid
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'EMPLOYEE ID',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: textMuted,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            nik,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 28,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'DEPARTMENT',
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.w800,
                                              color: textMuted,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            department,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: textDark,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Barcode Frame
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    CustomPaint(
                                      size: const Size(180, 24),
                                      painter: BarcodePainter(nik),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      nik,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Bottom Stripes
                      Container(
                        height: 3,
                        color: goldAccent,
                      ),
                      Container(
                        height: 10,
                        color: brandDarkGreen,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back Header Block
                      Container(
                        height: 80,
                        color: brandDarkGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) ...[
                                  Image.network(
                                    companyLogoUrl,
                                    height: 16,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  companyName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: goldAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: goldAccent.withOpacity(0.4), width: 0.8),
                              ),
                              child: const Text(
                                'SECURITY PASS',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w900,
                                  color: goldAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 3,
                        color: goldAccent,
                      ),
                      // Terms and Conditions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KETENTUAN PENGGUNAAN KARTU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: textMuted,
                                letterSpacing: 1.0,
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
                      // Barcode Back
                      Center(
                        child: CustomPaint(
                          size: const Size(160, 24),
                          painter: BarcodePainter(nik),
                        ),
                      ),
                      const Spacer(),
                      // Signature block and Footer info
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
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Sistem Kehadiran & Identitas GPS',
                                    style: TextStyle(
                                      fontSize: 7.5,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'HR Manager',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w800,
                                    color: brandDarkGreen,
                                  ),
                                ),
                                Container(
                                  width: 70,
                                  height: 1,
                                  color: const Color(0xFFCBD5E1),
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                const Text(
                                  'AUTHORIZED PASS',
                                  style: TextStyle(
                                    fontSize: 6.5,
                                    fontWeight: FontWeight.w900,
                                    color: textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Bottom Stripes
                      Container(
                        height: 3,
                        color: goldAccent,
                      ),
                      Container(
                        height: 10,
                        color: brandDarkGreen,
                      ),
                    ],
                  ),
            // Reflection gloss overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.0),
                        Colors.black.withOpacity(0.02),
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
    const Color primaryColor = Color(0xFF2D5A4C);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withOpacity(0.08),
            border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
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
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom Clipper for Modern Curved Banner
class BannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 35);
    // Draw smooth bezier curve
    final firstControlPoint = Offset(size.width / 2, size.height + 5);
    final firstEndPoint = Offset(size.width, size.height - 35);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BarcodePainter extends CustomPainter {
  final String nik;
  BarcodePainter(this.nik);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
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
