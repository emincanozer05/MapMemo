import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> get authStateChanges => _remoteDataSource.authStateChanges
      .map((user) => user == null ? null : AppUserModel.fromFirebaseUser(user));

  @override
  AppUser? get currentUser {
    final user = _remoteDataSource.currentUser;
    return user == null ? null : AppUserModel.fromFirebaseUser(user);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final user = await _remoteDataSource.signInWithGoogle();
    return AppUserModel.fromFirebaseUser(user);
  }

  @override
  Future<void> signOut() => _remoteDataSource.signOut();
}
