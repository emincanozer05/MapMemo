import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/app_exceptions.dart';

/// Talks directly to Firebase Auth + google_sign_in. Returns/streams the
/// raw Firebase [User] type; mapping to the domain entity happens one layer
/// up, in [AuthRepositoryImpl].
abstract class AuthRemoteDataSource {
  Stream<User?> get authStateChanges;

  User? get currentUser;

  Future<User> signInWithGoogle();

  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User> signInWithGoogle() async {
    try {
      // GoogleSignIn.instance.initialize() must already have completed by
      // the time this runs; it is awaited once in main() at app startup.
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      final String? idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException(
          'Google hesabından kimlik jetonu alınamadı. Lütfen tekrar deneyin.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Firebase oturumu oluşturulamadı.');
      }
      return user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      throw AuthException(
        'Google ile giriş başarısız oldu: ${e.description ?? e.code}',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        e.message ?? 'Firebase kimlik doğrulama sırasında bir hata oluştu.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await Future.wait<void>([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }
}
