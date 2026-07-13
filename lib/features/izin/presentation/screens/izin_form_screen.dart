import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:gaweflutter/features/izin/data/repositories/izin_repository.dart';
import 'package:gaweflutter/features/izin/presentation/providers/izin_provider.dart';

class IzinFormScreen extends ConsumerStatefulWidget {
  final String? initialJenisIzin;
  const IzinFormScreen({super.key, this.initialJenisIzin});

  @override
  ConsumerState<IzinFormScreen> createState() => _IzinFormScreenState();
}

class _IzinFormScreenState extends ConsumerState<IzinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _dateController = TextEditingController();

  late String _jenisIzin;
  DateTime? _dariDate;
  DateTime? _sampaiDate;
  File? _attachmentFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _jenisIzin = widget.initialJenisIzin ?? 'i';
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDateRange: (_dariDate != null && _sampaiDate != null)
          ? DateTimeRange(start: _dariDate!, end: _sampaiDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D5A4C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dariDate = picked.start;
        _sampaiDate = picked.end;
        final fromStr = DateFormat('d MMM yyyy').format(_dariDate!);
        final toStr = DateFormat('d MMM yyyy').format(_sampaiDate!);
        _dateController.text = '$fromStr - $toStr';
      });
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _attachmentFile = File(pickedFile.path);
      });
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Pilih Bukti Sakit / Lampiran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2D5A4C)),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAttachment(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2D5A4C)),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAttachment(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dariDate == null || _sampaiDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih rentang tanggal pengajuan terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Sakit requires an attachment
    if (_jenisIzin == 's' && _attachmentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Untuk izin sakit, wajib melampirkan Surat Izin Dokter (SID).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(izinRepositoryProvider);
      final fromStr = DateFormat('yyyy-MM-dd').format(_dariDate!);
      final toStr = DateFormat('yyyy-MM-dd').format(_sampaiDate!);

      await repository.submitIzin(
        jenisIzin: _jenisIzin,
        dari: fromStr,
        sampai: toStr,
        keterangan: _keteranganController.text,
        sidPath: _attachmentFile?.path,
      );

      // Invalidate list provider to trigger refresh
      ref.invalidate(izinListProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan izin berhasil dikirim!'),
            backgroundColor: Color(0xFF2D5A4C),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pengajuan: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: Color(0xFF2D5A4C), fontWeight: FontWeight.bold),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF2D5A4C), size: 20),
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D5A4C), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D5A4C), width: 2.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2.2),
      ),
    );
  }

  String _getJenisIzinLabel(String key) {
    switch (key) {
      case 'i':
        return 'Izin Absen';
      case 's':
        return 'Izin Sakit';
      case 'c':
        return 'Cuti';
      case 'd':
        return 'Dinas';
      default:
        return 'Izin';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2D5A4C);
    const Color bodyBgColor = Color(0xFFE8F0ED);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Buat Ajuan Izin',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Jenis Pengajuan (Read Only)
              TextFormField(
                initialValue: _getJenisIzinLabel(_jenisIzin),
                readOnly: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Jenis Pengajuan',
                  prefixIcon: Icons.assignment_outlined,
                ),
              ),
              const SizedBox(height: 12),

              // 2. Rentang Tanggal Field with floating label
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDateRange(context),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Rentang Tanggal',
                  prefixIcon: Icons.date_range_rounded,
                  suffixIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ),
                validator: (value) {
                  if (_dariDate == null || _sampaiDate == null) {
                    return 'Rentang tanggal wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // 3. Keterangan / Alasan Field with floating label
              TextFormField(
                controller: _keteranganController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Keterangan / Alasan',
                  prefixIcon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Keterangan wajib diisi';
                  }
                  return null;
                },
              ),

              // 4. Attachment Section if Sakit
              if (_jenisIzin == 's') ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Lampiran Surat Izin Dokter (SID)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                ),
                InkWell(
                  onTap: _showAttachmentPicker,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2D5A4C), width: 1.5),
                    ),
                    child: _attachmentFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_attachmentFile!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 36, color: primaryColor),
                              SizedBox(height: 6),
                              Text(
                                'Upload Bukti Foto / Surat Dokter',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Maksimal ukuran file: 10MB',
                                style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ===== SUBMIT BUTTON =====
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5A4C), Color(0xFF437A68)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Pengajuan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
