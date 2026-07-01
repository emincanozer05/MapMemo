import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../domain/entities/app_user.dart';

/// Maps between Firebase's [firebase_auth.User] and the domain [AppUser].
/// This is the only file in the app allowed to know both types.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoUrl,
  });

  factory AppUserModel.fromFirebaseUser(firebase_auth.User user) {
    return AppUserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
