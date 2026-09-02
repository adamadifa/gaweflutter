import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gaweflutter/features/pengumuman/data/models/pengumuman_model.dart';
import 'package:gaweflutter/features/pengumuman/presentation/providers/pengumuman_provider.dart';

class PengumumanDetailScreen extends ConsumerStatefulWidget {
  final int pengumumanId;
  final PengumumanModel? initialData;

  const PengumumanDetailScreen({
    super.key,
    required this.pengumumanId,
    this.initialData,
  });

  @override
  ConsumerState<PengumumanDetailScreen> createState() => _PengumumanDetailScreenState();
}

class _PengumumanDetailScreenState extends ConsumerState<PengumumanDetailScreen> {
  bool _isAcknowledged = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final detailAsync = ref.watch(pengumumanDetailProvider(widget.pengumumanId));

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: detailAsync.when(
        data: (data) => _buildContent(context, data, primaryColor),
        loading: () => widget.initialData != null
            ? _buildContent(context, widget.initialData!, primaryColor)
            : Scaffold(
                appBar: AppBar(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: const Center(child: CircularProgressIndicator()),
              ),
        error: (err, _) => Scaffold(
          appBar: AppBar(
            backgroundColor: primaryColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline_rounded, size: 30, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    err.toString().replaceAll('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(pengumumanDetailProvider(widget.pengumumanId)),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
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

  Widget _buildContent(BuildContext context, PengumumanModel item, Color primaryColor) {
    final isPdf = item.lampiran?.toLowerCase().endsWith('.pdf') ?? false;
    final isImage = (item.lampiran?.toLowerCase().endsWith('.png') ?? false) ||
        (item.lampiran?.toLowerCase().endsWith('.jpg') ?? false) ||
        (item.lampiran?.toLowerCase().endsWith('.jpeg') ?? false);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 1. Colorful App Bar with gradient background
        SliverAppBar(
          expandedHeight: 140,
          pinned: true,
          elevation: 0,
          backgroundColor: primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    const Color(0xFF438A73),
                    const Color(0xFF58907D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Opacity(
                      opacity: 0.12,
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 160,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 5),
                              Text(
                                'Pengumuman Resmi',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Internal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.25),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),

        // 2. Main Article Body
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.judul,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          height: 1.35,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Publisher Info Row
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text(
                                'HR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manajemen Perusahaan',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.formattedDate,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Article Content Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Highlight banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Harap membaca informasi ini dengan teliti. Pengumuman ini berlaku untuk seluruh karyawan.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Text body
                      SelectableText(
                        item.isi,
                        style: const TextStyle(
                          fontSize: 14.5,
                          color: Color(0xFF334155),
                          height: 1.7,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Attachment Card (if present)
                if (item.lampiranUrl != null && item.lampiranUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF64748B).withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.attach_file_rounded, size: 16, color: Color(0xFF475569)),
                            SizedBox(width: 6),
                            Text(
                              'Berkas Lampiran Dokumen',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isPdf
                                ? const Color(0xFFFEF2F2)
                                : isImage
                                    ? const Color(0xFFF0FDF4)
                                    : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPdf
                                  ? const Color(0xFFFECACA)
                                  : isImage
                                      ? const Color(0xFFBBF7D0)
                                      : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isPdf
                                      ? const Color(0xFFDC2626)
                                      : isImage
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    isPdf
                                        ? Icons.picture_as_pdf_rounded
                                        : isImage
                                            ? Icons.image_rounded
                                            : Icons.description_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.lampiran ?? 'Dokumen Lampiran',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      isPdf ? 'Dokumen PDF' : isImage ? 'File Gambar' : 'Dokumen File',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPdf
                                            ? const Color(0xFFB91C1C)
                                            : isImage
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final uri = Uri.parse(item.lampiranUrl!);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Tidak dapat membuka lampiran'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPdf
                                      ? const Color(0xFFDC2626)
                                      : isImage
                                          ? const Color(0xFF16A34A)
                                          : primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.download_rounded, color: Colors.white, size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'Buka',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Friendly Acknowledgment / Interaction Button
                InkWell(
                  onTap: () {
                    setState(() {
                      _isAcknowledged = !_isAcknowledged;
                    });
                    if (_isAcknowledged) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Terima kasih, Anda telah menandai pengumuman ini sudah dipahami!'),
                          backgroundColor: Color(0xFF15803D),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _isAcknowledged ? const Color(0xFFDCFCE7) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isAcknowledged ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isAcknowledged ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                          color: _isAcknowledged ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAcknowledged ? 'Sudah Saya Baca & Pahami' : 'Tandai Sudah Dibaca & Dipahami',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _isAcknowledged ? const Color(0xFF15803D) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
