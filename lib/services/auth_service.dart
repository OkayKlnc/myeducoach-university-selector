import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db   = FirebaseFirestore.instance;

  static const _allowedDomain = '@myeducoach.com';

  // Mevcut kullanıcı stream'i
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  // Kullanıcı profilini Firestore'dan çek
  static Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  // Kayıt
  static Future<String?> register({
    required String name,
    required String surname,
    required String email,
    required String password,
  }) async {
    if (!email.toLowerCase().endsWith(_allowedDomain)) {
      return 'Sadece @myeducoach.com e-posta adresleri kabul edilmektedir.';
    }
    if (name.trim().isEmpty || surname.trim().isEmpty) {
      return 'Ad ve soyad zorunludur.';
    }
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalıdır.';
    }
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final uid = cred.user!.uid;

      // Firestore'a profil kaydet
      await _db.collection('users').doc(uid).set({
        'email':     email.trim().toLowerCase(),
        'name':      name.trim(),
        'surname':   surname.trim(),
        'role':      'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Aktivasyon e-postası gönder
      await cred.user!.sendEmailVerification();
      return null; // başarı
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // Giriş
  static Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      if (!cred.user!.emailVerified) {
        await _auth.signOut();
        return 'E-postanız henüz doğrulanmamış. Lütfen gelen kutunuzu kontrol edin.';
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  // Çıkış
  static Future<void> signOut() => _auth.signOut();

  // Aktivasyon e-postasını tekrar gönder
  static Future<void> resendVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen bir süre bekleyin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmıştır.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
