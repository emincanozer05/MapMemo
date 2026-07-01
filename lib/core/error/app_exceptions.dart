/// Base type for all expected, handled failures in the app.
///
/// Data sources throw these instead of leaking Firebase/platform-specific
/// exception types into the domain and presentation layers.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message);
}

/// Thrown when the user closes the Google account picker without choosing
/// an account. Callers typically swallow this instead of showing an error.
class AuthCancelledException extends AuthException {
  const AuthCancelledException() : super('Giriş işlemi iptal edildi.');
}
