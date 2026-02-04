// File generated based on google-services.json configuration.
// flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAI8tnm4R4UqeW1hFY_fMLuVpXNEvRkXBA',
    appId: '1:591141789204:android:2fca63773c6891b9b2d101',
    messagingSenderId: '591141789204',
    projectId: 'depotakip-ccfcc',
    storageBucket: 'depotakip-ccfcc.firebasestorage.app',
  );

  // Web configuration from Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyClKaDa51RbD1PUKKauZQ4gAVd3_1lvyPU',
    appId: '1:591141789204:web:3c65d48962dd5f2fb2d101',
    messagingSenderId: '591141789204',
    projectId: 'depotakip-ccfcc',
    storageBucket: 'depotakip-ccfcc.firebasestorage.app',
    authDomain: 'depotakip-ccfcc.firebaseapp.com',
    measurementId: 'G-W7N9SXH39Z',
  );

  // iOS için yapılandırma (henüz eklenmemiş)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAI8tnm4R4UqeW1hFY_fMLuVpXNEvRkXBA',
    appId: '1:591141789204:ios:YOUR_IOS_APP_ID',
    messagingSenderId: '591141789204',
    projectId: 'depotakip-ccfcc',
    storageBucket: 'depotakip-ccfcc.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  // macOS için yapılandırma
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAI8tnm4R4UqeW1hFY_fMLuVpXNEvRkXBA',
    appId: '1:591141789204:ios:YOUR_MACOS_APP_ID',
    messagingSenderId: '591141789204',
    projectId: 'depotakip-ccfcc',
    storageBucket: 'depotakip-ccfcc.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  // Windows için yapılandırma - Web ile aynı
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyClKaDa51RbD1PUKKauZQ4gAVd3_1lvyPU',
    appId: '1:591141789204:web:3c65d48962dd5f2fb2d101',
    messagingSenderId: '591141789204',
    projectId: 'depotakip-ccfcc',
    storageBucket: 'depotakip-ccfcc.firebasestorage.app',
    authDomain: 'depotakip-ccfcc.firebaseapp.com',
    measurementId: 'G-W7N9SXH39Z',
  );
}
