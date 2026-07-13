import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gaweflutter/data/repositories/aktivitas_repository.dart';

const Color primaryColor = Color(0xFF32745e);
const Color bodyBgColor = Color(0xFFE8F0ED);

class AktivitasFormScreen extends ConsumerStatefulWidget {
  const AktivitasFormScreen({super.key});

  @override
  ConsumerState<AktivitasFormScreen> createState() => _AktivitasFormScreenState();
}

class _AktivitasFormScreenState extends ConsumerState<AktivitasFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aktivitasController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _dateController = TextEditingController();

  DateTime _activityDate = DateTime.now();
  File? _photoFile;
  Position? _currentPosition;
  bool _isLocating = true;
  String? _locationError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('d MMMM yyyy', 'id_ID').format(_activityDate);
    _initLocationTracking();
  }

  @override
  void dispose() {
    _aktivitasController.dispose();
    _lokasiController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    setState(() {
      _isLocating = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "GPS dinonaktifkan. Silakan aktifkan layanan lokasi.";
          _isLocating = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = "Izin lokasi ditolak.";
            _isLocating = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Izin lokasi ditolak permanen.";
          _isLocating = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _lokasiController.text = "${position.latitude},${position.longitude}";
          _isLocating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = "Gagal memuat lokasi: $e";
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  void _showPhotoPicker() {
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
                    'Ambil Foto Bukti Aktivitas',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: primaryColor),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: primaryColor),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
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

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap tunggu hingga lokasi GPS terdeteksi')),
      );
      return;
    }

    if (_photoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto bukti aktivitas wajib dilampirkan')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(aktivitasRepositoryProvider);

      final result = await repository.submitAktivitas(
        aktivitas: _aktivitasController.text.trim(),
        lokasi: _lokasiController.text.trim(),
        imagePath: _photoFile!.path,
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aktivitas harian berhasil dikirim!'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(result['message'] ?? 'Gagal menyimpan data aktivitas');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim aktivitas: ${e.toString().replaceAll('Exception: ', '')}'),
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
      floatingLabelStyle: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
      prefixIcon: Icon(prefixIcon, color: primaryColor, size: 20),
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2.2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Input Aktivitas',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // GPS tracking indicator card
              if (_isLocating) ...[
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.5)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Sedang membaca lokasi GPS Anda saat ini...',
                          style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_locationError != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_rounded, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _locationError!,
                          style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _initLocationTracking,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. Tanggal Aktivitas (Read only / Today)
              TextFormField(
                controller: _dateController,
                readOnly: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Tanggal Catat',
                  prefixIcon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Lokasi Koordinat (Read only)
              TextFormField(
                controller: _lokasiController,
                readOnly: true,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Koordinat Lokasi',
                  prefixIcon: Icons.map_rounded,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location, color: primaryColor),
                    onPressed: _initLocationTracking,
                  ),
                ),
                validator: (value) {
                  if (_currentPosition == null) {
                    return 'Koordinat GPS wajib didapatkan';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Deskripsi Aktivitas
              TextFormField(
                controller: _aktivitasController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Deskripsi Aktivitas Harian',
                  prefixIcon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Deskripsi aktivitas wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 4. Capture Photo Lampiran
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Foto Bukti Aktivitas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ),
              InkWell(
                onTap: _showPhotoPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor, width: 1.5),
                  ),
                  child: _photoFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_photoFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: primaryColor),
                            SizedBox(height: 8),
                            Text(
                              'Ambil Foto Bukti Aktivitas Harian',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // ===== SUBMIT BUTTON =====
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, Color(0xFF4E8A75)],
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
                          'Simpan Aktivitas',
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
