// File generated for PRM393 Final Assignment.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps on Web and Android.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBNDRg8O_RS-a4Mq_WfkK3R_yrO3q21ScU',
    appId: '1:420624932039:web:d6e86b9e79327f5b5132e2',
    messagingSenderId: '420624932039',
    projectId: 'prm393-eduplan',
    authDomain: 'prm393-eduplan.firebaseapp.com',
    storageBucket: 'prm393-eduplan.firebasestorage.app',
    measurementId: 'G-F6E93GCK2B',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC9xT-x8XjC50tgUQxMXeU0N3dTx0o-DXY',
    appId: '1:420624932039:android:c5d0526147f341ea5132e2',
    messagingSenderId: '420624932039',
    projectId: 'prm393-eduplan',
    storageBucket: 'prm393-eduplan.firebasestorage.app',
  );
}
