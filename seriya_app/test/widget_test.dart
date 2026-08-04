import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seriya_app/app.dart';
import 'package:seriya_app/screens/dashboard_screen.dart';
import 'package:seriya_app/services/auth_service.dart';

void main() {
  testWidgets('opens on the sign-in screen', (tester) async {
    await tester.pumpWidget(SeriyaApp(authService: FakeAuthService()));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('valid sign-in opens the dashboard', (tester) async {
    await tester.pumpWidget(SeriyaApp(authService: FakeAuthService()));

    await tester.enterText(
      find.byKey(const Key('signInEmail')),
      'passenger@seriya.lk',
    );
    await tester.enterText(
      find.byKey(const Key('signInPassword')),
      'secret123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Morning to office'), findsOneWidget);
    expect(find.text('Vehicle is on the way'), findsOneWidget);
  });

  testWidgets('create account opens passenger and driver registration', (
    tester,
  ) async {
    await tester.pumpWidget(SeriyaApp(authService: FakeAuthService()));

    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Submit registration'), findsOneWidget);
  });

  testWidgets('allows the passenger to change attendance', (tester) async {
    await tester.pumpWidget(const TestApp(home: DashboardScreen()));

    await tester.tap(find.text("I'm riding"));
    await tester.pump();

    expect(find.text('Not riding'), findsOneWidget);
    expect(find.text('You are not travelling on this shift'), findsOneWidget);
  });
}

class FakeAuthService implements AuthService {
  @override
  Future<void> register(RegistrationDetails details) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    return const SignInResult(
      status: AccountStatus.approved,
      role: 'passenger',
    );
  }
}

class TestApp extends StatelessWidget {
  const TestApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: home);
  }
}
