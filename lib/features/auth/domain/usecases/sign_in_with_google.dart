import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Encapsulates the "user taps the Google button" action so presentation
/// code never talks to [AuthRepository] directly.
class SignInWithGoogle {
  const SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call() => _repository.signInWithGoogle();
}
