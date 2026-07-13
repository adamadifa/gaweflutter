import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/features/reimbursement/data/datasources/reimbursement_remote_data_source.dart';
import 'package:gaweflutter/features/reimbursement/data/repositories/reimbursement_repository.dart';
import 'package:gaweflutter/features/reimbursement/presentation/providers/reimbursement_provider.dart';
import 'package:gaweflutter/features/reimbursement/data/models/reimbursement_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ReimbursementCreateScreen extends ConsumerStatefulWidget {
  const ReimbursementCreateScreen({super.key});

  @override
  ConsumerState<ReimbursementCreateScreen> createState() => _ReimbursementCreateScreenState();
}

class _ReimbursementCreateScreenState extends ConsumerState<ReimbursementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _keteranganController = TextEditingController();
  final _tanggalController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  final List<ItemFormInput> _items = [];
  bool _isSubmitting = false;

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  void initState() {
    super.initState();
    _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
    // Start with 1 empty item
    _items.add(ItemFormInput());
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _tanggalController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF32745e),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
    }
  }

  double _calculateGrandTotal() {
    double total = 0.0;
    for (var item in _items) {
      final text = item.jumlahController.text.replaceAll('.', '');
      final val = double.tryParse(text) ?? 0.0;
      total += val;
    }
    return total;
  }

  Future<void> _pickImage(ItemFormInput item, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        item.file = File(pickedFile.path);
      });
    }
  }

  void _showImagePicker(ItemFormInput item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lampirkan Foto Bukti',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Silakan pilih kamera atau galeri untuk mengunggah nota/kwitansi pembelian Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(item, ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 32, color: Color(0xFF32745e)),
                            SizedBox(height: 8),
                            Text(
                              'Kamera',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(item, ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFFF8FAFC),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 32, color: Color(0xFF32745e)),
                            SizedBox(height: 8),
                            Text(
                              'Galeri Foto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item #${i + 1}: Silakan pilih kategori reimbursement.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final textVal = item.jumlahController.text.replaceAll('.', '');
      final amount = double.tryParse(textVal) ?? 0.0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item #${i + 1}: Nominal harus lebih besar dari 0.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (amount > item.selectedCategory!.limitNominal) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item #${i + 1}: Nominal melebihi batas kategori (${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(item.selectedCategory!.limitNominal)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (item.selectedCategory!.wajibBukti == 1 && item.file == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item #${i + 1}: Kategori ini wajib melampirkan foto kwitansi/nota.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(reimbursementRepositoryProvider);
      
      final submitItems = _items.map((e) {
        final textVal = e.jumlahController.text.replaceAll('.', '');
        return ReimbursementSubmitItem(
          kategori: e.selectedCategory!.kodeJenisReimburse,
          jumlah: double.parse(textVal),
          keterangan: e.keteranganController.text,
          filePath: e.file?.path,
        );
      }).toList();

      await repository.submitReimbursement(
        tanggal: _tanggalController.text,
        keterangan: _keteranganController.text,
        items: submitItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan reimbursement berhasil dikirim!'),
            backgroundColor: Color(0xFF32745e),
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

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w600),
      floatingLabelStyle: const TextStyle(color: Color(0xFF32745e), fontWeight: FontWeight.bold),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF32745e), size: 20),
      prefix: prefix,
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF32745e), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF32745e), width: 2.2),
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
    final categoriesState = ref.watch(reimbursementCategoriesProvider);
    const Color primaryColor = Color(0xFF32745e);
    const Color bodyBgColor = Color(0xFFE8F0ED);

    return Scaffold(
      backgroundColor: bodyBgColor,
      appBar: AppBar(
        title: const Text(
          'Buat Pengajuan',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: categoriesState.when(
        data: (categories) {
          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Tanggal Pengajuan Field
                        TextFormField(
                          controller: _tanggalController,
                          readOnly: true,
                          onTap: _selectDate,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: _buildInputDecoration(
                            label: 'Tanggal Pengajuan',
                            prefixIcon: Icons.calendar_today_outlined,
                            suffixIcon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Catatan Pengajuan Field
                        TextFormField(
                          controller: _keteranganController,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Catatan pengajuan wajib diisi';
                            }
                            return null;
                          },
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          decoration: _buildInputDecoration(
                            label: 'Catatan Pengajuan (Keterangan/Tujuan)',
                            prefixIcon: Icons.description_outlined,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Multi Items Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'RINCIAN ITEM TRANSAKSI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.8,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _items.add(ItemFormInput());
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, size: 14, color: primaryColor),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tambah Item',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        ...List.generate(_items.length, (index) {
                          final item = _items[index];
                          return _buildItemSection(item, index, categories);
                        }),
                      ],
                    ),
                  ),
                ),

                // Grand Total & Submit Footer (Matches sticky footer style but matches bg)
                Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFD1DCD6), width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL PENGAJUAN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCurrency(_calculateGrandTotal()),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Kirim Pengajuan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
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
                  onPressed: () => ref.invalidate(reimbursementCategoriesProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Muat Ulang Kategori', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemSection(ItemFormInput item, int index, List<ReimbursementCategoryModel> categories) {
    const Color primaryColor = Color(0xFF32745e);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (index > 0) ...[
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFCBD5E1), thickness: 1),
          const SizedBox(height: 8),
        ],
        // Item Subheader
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Item #${index + 1}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            if (_items.length > 1)
              IconButton(
                onPressed: () {
                  setState(() {
                    _items.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Dropdown Kategori
        DropdownButtonFormField<ReimbursementCategoryModel>(
          value: item.selectedCategory,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          items: categories.map((cat) {
            return DropdownMenuItem<ReimbursementCategoryModel>(
              value: cat,
              child: Text(
                cat.namaJenis,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              item.selectedCategory = val;
            });
          },
          decoration: _buildInputDecoration(
            label: 'Kategori Reimbursement *',
            prefixIcon: Icons.category_outlined,
          ),
        ),
        const SizedBox(height: 12),

        // Limits & Wajib Bukti Badges
        if (item.selectedCategory != null) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1DCD6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wallet, size: 12, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Limit: ${_formatCurrency(item.selectedCategory!.limitNominal)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.selectedCategory!.wajibBukti == 1
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.selectedCategory!.wajibBukti == 1
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      size: 12,
                      color: item.selectedCategory!.wajibBukti == 1
                          ? Colors.red
                          : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.selectedCategory!.wajibBukti == 1 ? 'Wajib Bukti' : 'Bukti Opsional',
                      style: TextStyle(
                        fontSize: 10,
                        color: item.selectedCategory!.wajibBukti == 1
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Nominal Jumlah
        TextFormField(
          controller: item.jumlahController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nominal wajib diisi';
            }
            return null;
          },
          onChanged: (val) {
            if (val.isNotEmpty) {
              final clean = val.replaceAll('.', '');
              final formatted = NumberFormat('#,###', 'id_ID').format(int.parse(clean));
              item.jumlahController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            }
            setState(() {});
          },
          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
          decoration: _buildInputDecoration(
            label: 'Nominal Jumlah (Rupiah) *',
            prefixIcon: Icons.payments_outlined,
            prefix: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Text(
                'Rp ',
                style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Keterangan Item
        TextFormField(
          controller: item.keteranganController,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Keterangan item wajib diisi';
            }
            return null;
          },
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
          decoration: _buildInputDecoration(
            label: 'Keterangan Item *',
            prefixIcon: Icons.edit_note_outlined,
          ),
        ),
        const SizedBox(height: 16),

        // Foto Bukti
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Foto Bukti Kwitansi / Nota',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
        ),
        InkWell(
          onTap: () => _showImagePicker(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor, width: 1.5),
            ),
            child: item.file != null
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(item.file!, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              item.file = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 36, color: primaryColor),
                      SizedBox(height: 6),
                      Text(
                        'Upload Bukti Foto',
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
        const SizedBox(height: 16),
      ],
    );
  }
}

class ItemFormInput {
  final jumlahController = TextEditingController();
  final keteranganController = TextEditingController();
  
  ReimbursementCategoryModel? selectedCategory;
  File? file;

  void dispose() {
    jumlahController.dispose();
    keteranganController.dispose();
  }
}

