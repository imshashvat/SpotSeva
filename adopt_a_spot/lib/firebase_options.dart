// lib/firebase_options.dart
// Auto-populated from google-services.json (project: adopt-a-spot-prod)
// Generated manually — run `flutterfire configure` to regenerate if needed.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  // ── Web / Chrome (same Firebase project) ──────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUMMY_KEY_PLACEHOLDER_SPOTSEVA',
    appId: '1:308526071935:web:e0ac0b8fdffe9651b2ff4a',
    messagingSenderId: '308526071935',
    projectId: 'adopt-a-spot-prod',
    authDomain: 'adopt-a-spot-prod.firebaseapp.com',
    storageBucket: 'adopt-a-spot-prod.firebasestorage.app',
  );

  // ── Android ───────────────────────────────────────────────────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUMMY_KEY_PLACEHOLDER_SPOTSEVA',
    appId: '1:308526071935:android:e0ac0b8fdffe9651b2ff4a',
    messagingSenderId: '308526071935',
    projectId: 'adopt-a-spot-prod',
    storageBucket: 'adopt-a-spot-prod.firebasestorage.app',
  );

  // ── iOS (placeholder — configure if needed) ────────────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUMMY_KEY_PLACEHOLDER_SPOTSEVA',
    appId: '1:308526071935:ios:e0ac0b8fdffe9651b2ff4a',
    messagingSenderId: '308526071935',
    projectId: 'adopt-a-spot-prod',
    storageBucket: 'adopt-a-spot-prod.firebasestorage.app',
    iosBundleId: 'com.shashvat.adoptASpot',
  );

  // ── Windows desktop ───────────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDUMMY_KEY_PLACEHOLDER_SPOTSEVA',
    appId: '1:308526071935:web:e0ac0b8fdffe9651b2ff4a',
    messagingSenderId: '308526071935',
    projectId: 'adopt-a-spot-prod',
    authDomain: 'adopt-a-spot-prod.firebaseapp.com',
    storageBucket: 'adopt-a-spot-prod.firebasestorage.app',
  );
}
