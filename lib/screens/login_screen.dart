import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _error = false;
  bool _loading = false;
  Image? _logo;

  static const _password = 'M@yeducoachuniversite2026';

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      await rootBundle.load('assets/images/logo.png');
      if (mounted) setState(() => _logo = Image.asset('assets/images/logo.png', fit: BoxFit.contain));
    } catch (_) {}
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() async {
    if (_loading) return;
    final input = _ctrl.text;
    if (input == _password) {
      setState(() { _loading = true; _error = false; });
      html.window.localStorage['isLoggedIn'] = 'true';
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      setState(() { _error = true; _loading = false; });
      _ctrl.clear();
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
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                if (_logo != null)
                  SizedBox(width: 140, height: 80, child: _logo)
                else
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  ),
                const SizedBox(height: 28),

                // Card
                Container(
                  width: 380,
                  padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hoş Geldiniz',
                        style: GoogleFonts.poppins(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F2057),
                        )),
                      const SizedBox(height: 4),
                      Text('Devam etmek için şifrenizi girin',
                        style: GoogleFonts.poppins(
                          fontSize: 13, color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        )),
                      const SizedBox(height: 28),

                      // Password field
                      TextField(
                        controller: _ctrl,
                        obscureText: _obscure,
                        autofocus: true,
                        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1A1A2E)),
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) { if (_error) setState(() => _error = false); },
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF6B7280), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF5F7FA),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF6B7280)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18, color: const Color(0xFF6B7280),
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          errorText: _error ? 'Hatalı şifre, tekrar deneyin' : null,
                          errorStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF8B1A4A)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE8ECF2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _error ? const Color(0xFF8B1A4A) : const Color(0xFFE8ECF2),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF0F2057), width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF8B1A4A), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F2057), Color(0xFF8B1A4A)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B1A4A).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text('Giriş Yap',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white, fontSize: 14,
                                      fontWeight: FontWeight.w700, letterSpacing: 0.3,
                                    )),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Text('© 2026 Myeducoach — Dahili Araç',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
