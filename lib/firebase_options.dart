import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAteCT13AtvX1_pA6vbR4mMLj1V3Lo4Uvo',
    appId: '1:758102825814:web:f7853f7b9dc6cc598454f7',
    messagingSenderId: '758102825814',
    projectId: 'ppb-midterm',
    authDomain: 'ppb-midterm.firebaseapp.com',
    storageBucket: 'ppb-midterm.firebasestorage.app',
    measurementId: 'G-HSCK2CTT4X',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtzVfoitA0xImaJRQzKOWNBsznsZ1B81k',
    appId: '1:758102825814:android:0f21396b3b3d76c48454f7',
    messagingSenderId: '758102825814',
    projectId: 'ppb-midterm',
    storageBucket: 'ppb-midterm.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAJEh3KJclpXAr77TiGGCBQPuAcJWZSbD8',
    appId: '1:758102825814:ios:faa3dbeeec4aa1758454f7',
    messagingSenderId: '758102825814',
    projectId: 'ppb-midterm',
    storageBucket: 'ppb-midterm.firebasestorage.app',
    iosClientId:
        '758102825814-rt531b900dccodqu27ra697gnkm9nk2k.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAJEh3KJclpXAr77TiGGCBQPuAcJWZSbD8',
    appId: '1:758102825814:ios:faa3dbeeec4aa1758454f7',
    messagingSenderId: '758102825814',
    projectId: 'ppb-midterm',
    storageBucket: 'ppb-midterm.firebasestorage.app',
    iosClientId:
        '758102825814-rt531b900dccodqu27ra697gnkm9nk2k.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAteCT13AtvX1_pA6vbR4mMLj1V3Lo4Uvo',
    appId: '1:758102825814:web:528a362c5e65de558454f7',
    messagingSenderId: '758102825814',
    projectId: 'ppb-midterm',
    authDomain: 'ppb-midterm.firebaseapp.com',
    storageBucket: 'ppb-midterm.firebasestorage.app',
    measurementId: 'G-GDW2RSSHDJ',
  );
}
