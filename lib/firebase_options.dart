// Bu dosyayı Firebase Console'dan aldığınız config ile doldurun.
// Adımlar için README veya mesajları okuyun.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError('Bu uygulama sadece web için yapılandırılmıştır.');
  }

  // ↓↓↓ Firebase Console → Project Settings → Your apps → Web app config ↓↓↓
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'FIREBASE_API_KEY',
    authDomain:        'FIREBASE_AUTH_DOMAIN',
    projectId:         'FIREBASE_PROJECT_ID',
    storageBucket:     'FIREBASE_STORAGE_BUCKET',
    messagingSenderId: 'FIREBASE_MESSAGING_SENDER_ID',
    appId:             'FIREBASE_APP_ID',
  );
}
