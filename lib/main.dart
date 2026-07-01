import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'core/config/google_sign_in_config.dart';
import 'core/di/service_locator.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must complete before any other GoogleSignIn call is made anywhere in
  // the app (see AuthRemoteDataSourceImpl.signInWithGoogle).
  await GoogleSignIn.instance.initialize(
    serverClientId: googleSignInServerClientId,
  );

  setupServiceLocator();

  runApp(const MapMemoApp());
}
