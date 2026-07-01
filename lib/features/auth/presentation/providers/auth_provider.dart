import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exceptions.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/watch_auth_state.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Single source of truth for auth state in the widget tree. Screens watch
/// this via `Provider`/`Consumer` instead of touching Firebase directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required SignInWithGoogle signInWithGoogle,
    required SignOut signOut,
    required WatchAuthState watchAuthState,
  }) : _signInWithGoogle = signInWithGoogle,
       _signOut = signOut {
    _authStateSubscription = watchAuthState().listen(_onAuthStateChanged);
  }

  final SignInWithGoogle _signInWithGoogle;
  final SignOut _signOut;
  late final StreamSubscription<AppUser?> _authStateSubscription;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _isSigningIn = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isSigningIn => _isSigningIn;
  String? get errorMessage => _errorMessage;

  void _onAuthStateChanged(AppUser? user) {
    _user = user;
    _status = user == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (_isSigningIn) return;
    _isSigningIn = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _signInWithGoogle();
      // Success path: _onAuthStateChanged will fire via the auth stream and
      // update _status/_user, so nothing else to do here.
    } on AuthCancelledException {
      // User closed the account picker; not an error worth surfacing.
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.';
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() => _signOut();

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
