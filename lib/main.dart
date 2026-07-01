import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'core/config/google_sign_in_config.dart';
import 'core/di/service_locator.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Debug providers pass through automatically; Play Integrity / App Attest
  // require the app to be registered in Firebase Console → App Check first
  // (see README "Firebase App Check kurulumu"), otherwise requests are
  // simply unverified rather than rejected.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kDebugMode
        ? const AndroidDebugProvider()
        : const AndroidPlayIntegrityProvider(),
    providerApple: kDebugMode
        ? const AppleDebugProvider()
        : const AppleAppAttestProvider(),
  );

  // Explicit for clarity — this is already the default on Android/iOS, and
  // is what lets the app show cached memories and queue writes offline.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Must complete before any other GoogleSignIn call is made anywhere in
  // the app (see AuthRemoteDataSourceImpl.signInWithGoogle).
  await GoogleSignIn.instance.initialize(
    serverClientId: googleSignInServerClientId,
  );

  setupServiceLocator();

  runApp(const MapMemoApp());
}
