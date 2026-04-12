// Bu dosyayı Firebase Console'dan aldığınız config ile doldurun.
// Adımlar için README veya mesajları okuyun.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Bu uygulama sadece web için yapılandırılmıştır.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBBt2-x7I1FWnWSKROOnn4PzRpfe_njkFk',
    appId: '1:452157463225:web:198189f440c94fa04c9968',
    messagingSenderId: '452157463225',
    projectId: 'myeducoach-6389a',
    authDomain: 'myeducoach-6389a.firebaseapp.com',
    storageBucket: 'myeducoach-6389a.firebasestorage.app',
  );

  // ↓↓↓ Firebase Console → Project Settings → Your apps → Web app config ↓↓↓
}