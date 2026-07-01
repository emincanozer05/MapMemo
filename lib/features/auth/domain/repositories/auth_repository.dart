import '../entities/app_user.dart';

/// Contract the data layer must fulfil. Presentation code (and use cases)
/// depend only on this abstraction, never on Firebase directly.
abstract class AuthRepository {
  /// Emits the current user whenever the auth state changes, and `null`
  /// when signed out. Emits once immediately with the current state.
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
