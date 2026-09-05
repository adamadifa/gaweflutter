import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gaweflutter/core/config/app_config.dart';

class ServerConfigScreen extends StatefulWidget {
  final bool isModal;

  const ServerConfigScreen({
    super.key,
    this.isModal = false,
  });

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoadingInitial = true;
  bool _isTesting = false;
  bool _isSaving = false;
  ({bool success, String message, int? latencyMs})? _testResult;

  // Modern corporate color tokens
  static const Color _primary = Color(0xFF1E6152);
  static const Color _surfaceBg = Color(0xFFF8FAFC);
  static const Color _cardBorder = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF475569);
  static const Color _textMuted = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _loadCurrentServerUrl();
    _urlController.addListener(_onUrlChanged);
  }

  void _onUrlChanged() {
    if (_testResult != null) {
      setState(() {
        _testResult = null;
      });
    }
  }

  Future<void> _loadCurrentServerUrl() async {
    final currentUrl = await AppConfig.getBaseUrl();
    if (currentUrl != null && currentUrl.isNotEmpty) {
      final display = AppConfig.getDisplayUrl(currentUrl);
      _urlController.text = display;
    }
    if (mounted) {
      setState(() {
        _isLoadingInitial = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.removeListener(_onUrlChanged);
    _urlController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection() async {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan URL server terlebih dahulu'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _focusNode.unfocus();
    HapticFeedback.lightImpact();

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final result = await AppConfig.testConnection(input);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = result;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    _focusNode.unfocus();
    HapticFeedback.mediumImpact();

    final input = _urlController.text.trim();

    setState(() {
      _isSaving = true;
    });

    // Jika belum pernah tes koneksi, lakukan tes singkat terlebih dahulu
    if (_testResult == null || !_testResult!.success) {
      final testResult = await AppConfig.testConnection(input);
      if (!testResult.success && mounted) {
        setState(() {
          _isSaving = false;
          _testResult = testResult;
        });

        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Peringatan Koneksi'),
            content: Text(
              '${testResult.message}\n\nApakah Anda tetap ingin menyimpan URL ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primary),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tetap Simpan'),
              ),
            ],
          ),
        );

        if (shouldProceed != true) return;
      }
    }

    await AppConfig.saveServerUrl(input);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text(
                'Endpoint server berhasil disimpan!',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.isModal || Navigator.canPop(context)) {
        context.pop(true);
      } else {
        context.go('/login');
      }
    }
  }

  void _insertChipText(String text) {
    HapticFeedback.selectionClick();
    final current = _urlController.text;
    if (text == 'https://' || text == 'http://') {
      if (!current.startsWith('http://') && !current.startsWith('https://')) {
        _urlController.text = '$text$current';
      }
    } else {
      _urlController.text = '$current$text';
    }
    _urlController.selection = TextSelection.fromPosition(
      TextPosition(offset: _urlController.text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isModal || Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Konfigurasi Server',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingInitial
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header Icon & Description
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF7ED),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFFFEDD5),
                                        width: 1.5,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Hubungkan ke Server',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: _textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Masukkan domain atau alamat IP server backend presensi perusahaan Anda untuk memulai.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _textSecondary,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Input URL Card
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _surfaceBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'URL Endpoint Server',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _urlController,
                                    focusNode: _focusNode,
                                    keyboardType: TextInputType.url,
                                    autocorrect: false,
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w500,
                                      color: _textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'https://absensi.kantoranda.com',
                                      hintStyle: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 13.5,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      prefixIcon: const Icon(
                                        Icons.dns_outlined,
                                        color: _primary,
                                        size: 20,
                                      ),
                                      suffixIcon: _urlController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: _textMuted,
                                                size: 18,
                                              ),
                                              onPressed: () {
                                                _urlController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: _cardBorder),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: _cardBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: _primary, width: 1.8),
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Alamat URL server wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Quick helper chips
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      _buildHelperChip('https://'),
                                      _buildHelperChip('http://'),
                                      _buildHelperChip(':8000'),
                                      _buildHelperChip('10.0.2.2:8000'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Test Result Feedback Card
                            if (_testResult != null)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _testResult!.success
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _testResult!.success
                                        ? const Color(0xFFBBF7D0)
                                        : const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      _testResult!.success
                                          ? Icons.check_circle_rounded
                                          : Icons.error_rounded,
                                      color: _testResult!.success
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFDC2626),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _testResult!.success
                                                ? 'Server Terhubung'
                                                : 'Koneksi Gagal',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _testResult!.success
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFFB91C1C),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _testResult!.message +
                                                (_testResult!.latencyMs != null
                                                    ? ' (${_testResult!.latencyMs} ms)'
                                                    : ''),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _testResult!.success
                                                  ? const Color(0xFF166534)
                                                  : const Color(0xFF991B1B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 20),

                            // Button Tes Koneksi
                            OutlinedButton.icon(
                              onPressed: _isTesting || _isSaving
                                  ? null
                                  : _handleTestConnection,
                              icon: _isTesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primary,
                                      ),
                                    )
                                  : const Icon(Icons.network_check_rounded,
                                      size: 18),
                              label: Text(
                                _isTesting ? 'Menguji Koneksi...' : 'Tes Koneksi Server',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                side: const BorderSide(
                                    color: _primary, width: 1.2),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Button Simpan & Lanjutkan
                            ElevatedButton.icon(
                              onPressed:
                                  _isSaving ? null : () => _handleSave(),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded, size: 20),
                              label: Text(
                                _isSaving
                                    ? 'Menyimpan...'
                                    : 'Simpan & Lanjutkan',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom Copyright
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16, top: 8),
                    child: Text(
                      'adamadifa | Programmer Introvert',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textMuted,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHelperChip(String text) {
    return InkWell(
      onTap: () => _insertChipText(text),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
      ),
    );
  }
}
