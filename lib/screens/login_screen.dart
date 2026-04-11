import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Login fields
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Register fields
  final _regNameCtrl     = TextEditingController();
  final _regSurnameCtrl  = TextEditingController();
  final _regEmailCtrl    = TextEditingController();
  final _regPassCtrl     = TextEditingController();
  final _regPassCtrl2    = TextEditingController();

  bool _loginLoading   = false;
  bool _regLoading     = false;
  bool _regSuccess     = false;
  String? _loginError;
  String? _regError;

  bool _loginPassVisible = false;
  bool _regPassVisible   = false;
  bool _regPass2Visible  = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regSurnameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regPassCtrl2.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() { _loginLoading = true; _loginError = null; });
    final err = await AuthService.signIn(
      email:    _loginEmailCtrl.text,
      password: _loginPasswordCtrl.text,
    );
    if (!mounted) return;
    setState(() { _loginLoading = false; _loginError = err; });
  }

  Future<void> _doRegister() async {
    if (_regPassCtrl.text != _regPassCtrl2.text) {
      setState(() { _regError = 'Şifreler eşleşmiyor.'; });
      return;
    }
    setState(() { _regLoading = true; _regError = null; });
    final err = await AuthService.register(
      name:     _regNameCtrl.text,
      surname:  _regSurnameCtrl.text,
      email:    _regEmailCtrl.text,
      password: _regPassCtrl.text,
    );
    if (!mounted) return;
    if (err == null) {
      setState(() { _regLoading = false; _regSuccess = true; });
    } else {
      setState(() { _regLoading = false; _regError = err; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2057), Color(0xFF1E3A8A), Color(0xFF8B1A4A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 60,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo area
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 40),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F2057), Color(0xFF1E3A8A)],
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'MYEDUCOACH',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Üniversite Seçici',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  Container(
                    color: const Color(0xFFF8FAFF),
                    child: TabBar(
                      controller: _tab,
                      labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle:
                          GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                      labelColor: const Color(0xFF1E3A6E),
                      unselectedLabelColor: const Color(0xFF9CA3AF),
                      indicatorColor: const Color(0xFF8B1A4A),
                      indicatorWeight: 3,
                      tabs: const [
                        Tab(text: 'Giriş Yap'),
                        Tab(text: 'Hesap Oluştur'),
                      ],
                    ),
                  ),

                  // Tab content
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      height: 360,
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          _buildLoginTab(),
                          _buildRegisterTab(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inputField(
          controller: _loginEmailCtrl,
          label: 'E-posta',
          hint: 'ad.soyad@myeducoach.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _inputField(
          controller: _loginPasswordCtrl,
          label: 'Şifre',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: !_loginPassVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _loginPassVisible ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF9CA3AF),
              size: 20,
            ),
            onPressed: () => setState(() => _loginPassVisible = !_loginPassVisible),
          ),
        ),
        if (_loginError != null) ...[
          const SizedBox(height: 12),
          _errorBox(_loginError!),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loginLoading ? null : _doLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A6E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100)),
              elevation: 0,
            ),
            child: _loginLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text('Giriş Yap',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab() {
    if (_regSuccess) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read_rounded,
              size: 56, color: Color(0xFF1E3A6E)),
          const SizedBox(height: 16),
          Text(
            'Aktivasyon E-postası Gönderildi!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F2057)),
          ),
          const SizedBox(height: 8),
          Text(
            'E-posta adresinize aktivasyon bağlantısı gönderildi. '
            'Bağlantıya tıkladıktan sonra Giriş Yap sekmesinden giriş yapabilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
                height: 1.6),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() { _regSuccess = false; });
              _tab.animateTo(0);
            },
            child: Text('Giriş Yap\'a Geç',
                style: GoogleFonts.poppins(
                    color: const Color(0xFF1E3A6E),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _inputField(
                  controller: _regNameCtrl,
                  label: 'Ad',
                  hint: 'Adınız',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _inputField(
                  controller: _regSurnameCtrl,
                  label: 'Soyad',
                  hint: 'Soyadınız',
                  icon: Icons.person_outline_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _regEmailCtrl,
            label: 'E-posta',
            hint: 'ad.soyad@myeducoach.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _regPassCtrl,
            label: 'Şifre',
            hint: 'En az 8 karakter',
            icon: Icons.lock_outline_rounded,
            obscure: !_regPassVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _regPassVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
              onPressed: () => setState(() => _regPassVisible = !_regPassVisible),
            ),
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _regPassCtrl2,
            label: 'Şifre Tekrar',
            hint: 'Şifrenizi tekrar girin',
            icon: Icons.lock_outline_rounded,
            obscure: !_regPass2Visible,
            suffixIcon: IconButton(
              icon: Icon(
                _regPass2Visible ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF9CA3AF),
                size: 20,
              ),
              onPressed: () => setState(() => _regPass2Visible = !_regPass2Visible),
            ),
          ),
          if (_regError != null) ...[
            const SizedBox(height: 10),
            _errorBox(_regError!),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _regLoading ? null : _doRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1A4A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              child: _regLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Hesap Oluştur',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFFD1D5DB)),
            prefixIcon:
                Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1E3A6E), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}
