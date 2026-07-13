import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/data/repositories/lembur_repository.dart';
import 'package:intl/intl.dart';

const Color primaryColor = Color(0xFF32745e);
const Color bodyBgColor = Color(0xFFE8F0ED);

class LemburFormScreen extends ConsumerStatefulWidget {
  const LemburFormScreen({super.key});

  @override
  ConsumerState<LemburFormScreen> createState() => _LemburFormScreenState();
}

class _LemburFormScreenState extends ConsumerState<LemburFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _startDateTimeController = TextEditingController();
  final _endDateTimeController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    _startDateTimeController.dispose();
    _endDateTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDateTime() async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );

    if (datePicked != null) {
      if (!mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: _startTime ?? TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        ),
      );

      if (timePicked != null) {
        setState(() {
          _startDate = datePicked;
          _startTime = timePicked;
          
          final finalDateTime = DateTime(
            datePicked.year,
            datePicked.month,
            datePicked.day,
            timePicked.hour,
            timePicked.minute,
          );

          _startDateTimeController.text = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(finalDateTime);

          // If end date/time is empty or before start, set same values by default
          if (_endDate == null || _startDate!.isAfter(_endDate!)) {
            _endDate = datePicked;
            _endTime = timePicked;
            _endDateTimeController.text = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(finalDateTime);
          }
        });
      }
    }
  }

  Future<void> _selectEndDateTime() async {
    final DateTime? datePicked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );

    if (datePicked != null) {
      if (!mounted) return;
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: _endTime ?? _startTime ?? TimeOfDay.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        ),
      );

      if (timePicked != null) {
        setState(() {
          _endDate = datePicked;
          _endTime = timePicked;

          final finalDateTime = DateTime(
            datePicked.year,
            datePicked.month,
            datePicked.day,
            timePicked.hour,
            timePicked.minute,
          );

          _endDateTimeController.text = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(finalDateTime);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih waktu mulai dan selesai lembur')),
      );
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu selesai tidak boleh sebelum waktu mulai lembur')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formattedStart = DateFormat('yyyy-MM-dd HH:mm').format(startDateTime);
      final formattedEnd = DateFormat('yyyy-MM-dd HH:mm').format(endDateTime);

      final repository = ref.read(lemburRepositoryProvider);
      final result = await repository.requestLembur(
        dari: formattedStart,
        sampai: formattedEnd,
        keterangan: _keteranganController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan lembur berhasil dikirim!'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(result['message'] ?? 'Gagal menyimpan data');
        }
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
          'Buat Ajuan Lembur',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
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
              // 1. Waktu Mulai Picker
              TextFormField(
                controller: _startDateTimeController,
                readOnly: true,
                onTap: _selectStartDateTime,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Waktu Mulai Lembur',
                  prefixIcon: Icons.play_circle_outline_rounded,
                  suffixIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ),
                validator: (value) {
                  if (_startDate == null || _startTime == null) {
                    return 'Waktu mulai wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 2. Waktu Selesai Picker
              TextFormField(
                controller: _endDateTimeController,
                readOnly: true,
                onTap: _selectEndDateTime,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Waktu Selesai Lembur',
                  prefixIcon: Icons.stop_circle_outlined,
                  suffixIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ),
                validator: (value) {
                  if (_endDate == null || _endTime == null) {
                    return 'Waktu selesai wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Keterangan / Tugas
              TextFormField(
                controller: _keteranganController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                decoration: _buildInputDecoration(
                  label: 'Keterangan / Tugas Lembur',
                  prefixIcon: Icons.description_outlined,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Keterangan wajib diisi';
                  }
                  return null;
                },
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
