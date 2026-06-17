import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/fakes/fake_auth_gateway.dart';
import 'package:sentinel_app/presentation/auth/login_screen.dart';

void main() {
  testWidgets('shows validation when fields are empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authGateway: _TestAuthGateway()),
      ),
    );

    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('calls signIn with trimmed email', (tester) async {
    final auth = _TestAuthGateway();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(authGateway: auth),
      ),
    );

    await tester.enterText(find.byKey(const Key('login_email')), '  op@test.com  ');
    await tester.enterText(find.byKey(const Key('login_password')), 'secret');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();

    expect(auth.lastEmail, 'op@test.com');
    expect(auth.lastPassword, 'secret');
  });
}

class _TestAuthGateway extends FakeAuthGateway {
  String? lastEmail;
  String? lastPassword;

  @override
  Future<void> signIn({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    await super.signIn(email: email, password: password);
  }
}
