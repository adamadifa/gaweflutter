import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gaweflutter/core/storage/secure_storage.dart';
import 'package:gaweflutter/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Modern corporate color tokens
  static const Color _primaryGreen = Color(0xFF1E6152);
  static const Color _surfaceBg = Color(0xFFF8FAFC); // Slate-50
  static const Color _cardBorder = Color(0xFFE2E8F0); // Slate-200
  static const Color _textPrimary = Color(0xFF0F172A); // Slate-900
  static const Color _textSecondary = Color(0xFF475569); // Slate-600
  static const Color _textMuted = Color(0xFF94A3B8); // Slate-400

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onTextChanged);
    _loadRememberedUsername();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRememberedUsername() async {
    try {
      final saved = await SecureStorage.read('remembered_username');
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _usernameController.text = saved;
          _rememberMe = true;
        });
      }
    } catch (_) {
      // Storage access fail-safe
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onTextChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();

      if (_rememberMe) {
        SecureStorage.write('remembered_username', _usernameController.text.trim());
      } else {
        SecureStorage.delete('remembered_username');
      }

      ref.read(authProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text,
          );
    }
  }

  void _showForgotPasswordSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.contact_support_outlined,
                    color: _primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lupa Kata Sandi?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pusat Bantuan Akun Presensi',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surfaceBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demi alasan keamanan data kepegawaian dan riwayat presensi:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  _HelpStepItem(
                    number: '1',
                    text: 'Hubungi divisi HRD / Personalia di kantor Anda.',
                  ),
                  SizedBox(height: 8),
                  _HelpStepItem(
                    number: '2',
                    text: 'Sebutkan NIK dan Nama Lengkap sesuai KTP.',
                  ),
                  SizedBox(height: 8),
                  _HelpStepItem(
                    number: '3',
                    text: 'Admin HRD akan memverifikasi dan mereset kata sandi Anda.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Error notification listener
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B), // Elegant Dark Slate
            behavior: SnackBarBehavior.floating,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final isLoading = authState.status == AuthStatus.authenticating;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Modern Background Accent: Subtle curved top banner & soft dot mesh
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: CustomPaint(
                painter: _TopCurvedBackgroundPainter(),
              ),
            ),

            // Top-right subtle geometric dot grid
            Positioned(
              top: 40,
              right: 20,
              child: CustomPaint(
                size: const Size(90, 90),
                painter: _DotGridPainter(),
              ),
            ),

            // Bottom-left subtle decorative circle ring
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _primaryGreen.withValues(alpha: 0.08),
                    width: 28,
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Brand Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _primaryGreen,
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryGreen.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.fingerprint_rounded,
                                size: 26,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GAWE',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: _textPrimary,
                                  ),
                                ),
                                Text(
                                  'HR & Presensi Mobile',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Title & Description (Compact & Clear)
                        const Text(
                          'Masuk Akun',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Silakan masukkan NIK atau email terdaftar Anda.',
                          style: TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Form with Notch Outline Labels (Label nempel di garis border)
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Field 1: Username / NIK
                              TextFormField(
                                controller: _usernameController,
                                focusNode: _usernameFocus,
                                enabled: !isLoading,
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: _textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'NIK / Email Kantor',
                                  labelStyle: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: _primaryGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: 'Contoh: 20240101 atau email',
                                  hintStyle: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 13,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  suffixIcon: _usernameController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.close_rounded,
                                            size: 16,
                                            color: _textMuted,
                                          ),
                                          onPressed: () {
                                            _usernameController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _primaryGreen,
                                      width: 1.8,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEF4444),
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'NIK atau email tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // Field 2: Password
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _handleLogin(),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  color: _textPrimary,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi',
                                  labelStyle: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    color: _primaryGreen,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  hintText: '••••••••',
                                  hintStyle: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                    color: Color(0xFF64748B),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: _primaryGreen,
                                      width: 1.8,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFEF4444),
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kata sandi tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Row: Remember Me & Forgot Password
                              Row(
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: isLoading
                                          ? null
                                          : (val) {
                                              setState(() {
                                                _rememberMe = val ?? false;
                                              });
                                            },
                                      activeColor: _primaryGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _rememberMe = !_rememberMe;
                                            });
                                          },
                                    child: const Text(
                                      'Ingat akun saya',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: isLoading ? null : _showForgotPasswordSheet,
                                    child: const Text(
                                      'Lupa sandi?',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 22),

                              // Submit Button
                              SizedBox(
                                height: 48,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryGreen,
                                    disabledBackgroundColor: _primaryGreen.withValues(alpha: 0.65),
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: _primaryGreen.withValues(alpha: 0.35),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Minimal Footer with Copyright
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'HR & Presensi Mobile',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '© @adamadifa',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
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
}

class _TopCurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE6F3EE),
          Color(0xFFF3FAF7),
          Color(0x00F9FBFA),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height - 40)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 20,
        size.width,
        size.height - 30,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E6152).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const double spacing = 16.0;
    const double dotRadius = 1.8;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HelpStepItem extends StatelessWidget {
  final String number;
  final String text;

  const _HelpStepItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

