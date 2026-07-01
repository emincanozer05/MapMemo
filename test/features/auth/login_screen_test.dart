import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapmemo/features/auth/domain/entities/app_user.dart';
import 'package:mapmemo/features/auth/domain/repositories/auth_repository.dart';
import 'package:mapmemo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:mapmemo/features/auth/domain/usecases/sign_out.dart';
import 'package:mapmemo/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:mapmemo/features/auth/presentation/providers/auth_provider.dart';
import 'package:mapmemo/features/auth/presentation/screens/login_screen.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthProvider authProvider;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.authStateChanges,
    ).thenAnswer((_) => const Stream<AppUser?>.empty());
    authProvider = AuthProvider(
      signInWithGoogle: SignInWithGoogle(repository),
      signOut: SignOut(repository),
      watchAuthState: WatchAuthState(repository),
    );
  });

  Widget buildSubject() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  testWidgets('shows app name and the Google sign-in button', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.text('MapMemo'), findsOneWidget);
    expect(find.text('Google ile Giriş Yap'), findsOneWidget);
  });

  testWidgets('tapping the button calls signInWithGoogle on the repository', (
    tester,
  ) async {
    when(() => repository.signInWithGoogle()).thenAnswer(
      (_) async => const AppUser(uid: 'u1', email: 'test@example.com'),
    );

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Google ile Giriş Yap'));
    await tester.pump();

    verify(() => repository.signInWithGoogle()).called(1);
  });

  testWidgets('shows the error message when sign-in fails', (tester) async {
    when(() => repository.signInWithGoogle()).thenThrow(Exception('boom'));

    await tester.pumpWidget(buildSubject());
    await tester.tap(find.text('Google ile Giriş Yap'));
    await tester.pump();

    expect(
      find.text('Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.'),
      findsOneWidget,
    );
  });
}
