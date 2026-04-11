import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyeducoachApp());
}

class MyeducoachApp extends StatelessWidget {
  const MyeducoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myeducoach — Üniversite Seçici',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A6E)),
        useMaterial3: true,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A6E))),
          );
        }

        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        if (!user.emailVerified) return const _VerifyEmailScreen();

        return FutureBuilder(
          future: AuthService.getUserProfile(user.uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A6E))),
              );
            }
            final profile = snap.data;
            if (profile == null) return const LoginScreen();
            if (profile.isAdmin) return AdminScreen(profile: profile);
            return HomeScreen(profile: profile);
          },
        );
      },
    );
  }
}

// ─── E-posta doğrulama bekleme ekranı ────────────────────────────────────────
class _VerifyEmailScreen extends StatelessWidget {
  const _VerifyEmailScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF0F2057), Color(0xFF1E3A8A), Color(0xFF8B1A4A)],
          ),
        ),
        child: Center(
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 60, offset: const Offset(0, 24))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.mark_email_unread_rounded, size: 56, color: Color(0xFF1E3A6E)),
              const SizedBox(height: 20),
              Text('E-postanızı Doğrulayın',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F2057))),
              const SizedBox(height: 12),
              Text(
                'Kayıt olduğunuz e-posta adresine aktivasyon bağlantısı gönderdik. '
                'Lütfen e-postanızı kontrol edip bağlantıya tıklayın, ardından tekrar giriş yapın.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B7280), height: 1.6),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.resendVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Aktivasyon e-postası tekrar gönderildi.',
                          style: GoogleFonts.poppins(color: Colors.white)),
                        backgroundColor: const Color(0xFF0F2057),
                      ));
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text('Tekrar Gönder', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1E3A6E)),
                    foregroundColor: const Color(0xFF1E3A6E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: AuthService.signOut,
                child: Text('Çıkış Yap', style: GoogleFonts.poppins(color: const Color(0xFF6B7280))),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
