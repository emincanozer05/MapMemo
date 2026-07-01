// Hide firebase_auth's own `AuthProvider` (used for reauthentication
// credential providers) — it collides with this app's `AuthProvider`
// (the ChangeNotifier registered below).
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_google.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/watch_auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final GetIt sl = GetIt.instance;

/// Registers every dependency for every feature. Call once from `main()`
/// after `Firebase.initializeApp()` and `GoogleSignIn.instance.initialize()`
/// have both completed.
void setupServiceLocator() {
  // --- External SDKs ---
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  // --- Auth feature ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), googleSignIn: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => SignInWithGoogle(sl()));
  sl.registerLazySingleton(() => SignOut(sl()));
  sl.registerLazySingleton(() => WatchAuthState(sl()));

  sl.registerFactory(
    () => AuthProvider(
      signInWithGoogle: sl(),
      signOut: sl(),
      watchAuthState: sl(),
    ),
  );
}
