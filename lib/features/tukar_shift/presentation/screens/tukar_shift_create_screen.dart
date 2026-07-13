import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/tukar_shift/data/models/tukar_shift_model.dart';
import 'package:gaweflutter/features/tukar_shift/data/repositories/tukar_shift_repository.dart';
import 'package:intl/intl.dart';

class TukarShiftCreateScreen extends ConsumerStatefulWidget {
  final List<ShiftModel> shifts;

  const TukarShiftCreateScreen({super.key, required this.shifts});

  @override
  ConsumerState<TukarShiftCreateScreen> createState() => _TukarShiftCreateScreenState();
}

class _TukarShiftCreateScreenState extends ConsumerState<TukarShiftCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _dateController = TextEditingController();
  
  DateTime? _selectedDate;
  String? _selectedShiftCode;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _keteranganController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate!);
      });
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    const primaryColor = Color(0xFF2D5A4C);
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

  Future<void> _submitForm() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih tanggal terlebih dahulu'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        final repository = ref.read(tukarShiftRepositoryProvider);
        
        await repository.submitTukarShift(
          tanggal: formattedDate,
          kodeJamKerjaTujuan: _selectedShiftCode!,
          keterangan: _keteranganController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengajuan tukar shift berhasil dikirim!'),
              backgroundColor: Color(0xFF2D5A4C),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
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
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2D5A4C);
    const bodyBgColor = Color(0xFFE8F0ED);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Buat Ajuan Tukar Shift',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Banner Alert
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: primaryColor, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sistem akan otomatis mendeteksi jadwal awal Anda pada tanggal yang Anda ajukan.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Date Picker Field (mimicking textformfield range date in IzinFormScreen)
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _isSubmitting ? null : _selectDate,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  decoration: _buildInputDecoration(
                    label: 'Tanggal Perubahan Jadwal',
                    prefixIcon: Icons.date_range_rounded,
                    suffixIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ),
                  validator: (value) {
                    if (_selectedDate == null) {
                      return 'Tanggal wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Target Shift Dropdown select
                DropdownButtonFormField<String>(
                  value: _selectedShiftCode,
                  decoration: _buildInputDecoration(
                    label: 'Shift / Jam Kerja Tujuan',
                    prefixIcon: Icons.assignment_outlined,
                  ),
                  icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          setState(() {
                            _selectedShiftCode = val;
                          });
                        },
                  validator: (val) => val == null ? 'Silakan pilih shift tujuan' : null,
                  items: widget.shifts.map((shift) {
                    final displayLabel = shift.jamMasuk != null && shift.jamPulang != null
                        ? '${shift.namaJamKerja} (${shift.jamMasuk} - ${shift.jamPulang})'
                        : shift.namaJamKerja;
                    return DropdownMenuItem(
                      value: shift.kodeJamKerja,
                      child: Text(displayLabel),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Keterangan Textfield
                TextFormField(
                  controller: _keteranganController,
                  enabled: !_isSubmitting,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  decoration: _buildInputDecoration(
                    label: 'Alasan / Keterangan',
                    prefixIcon: Icons.description_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Alasan / keterangan harus diisi';
                    }
                    return null;
                  },
                ),
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Kirim Pengajuan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
