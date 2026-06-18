import 'dart:async';

import '../../domain/gateways/auth_gateway.dart';

/// Auth fake para testes — token fixo, sem Supabase.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({
    this.token = 'test-jwt',
    bool signedIn = true,
  }) : _signedIn = signedIn;

  bool _signedIn;
  final String token;
  String? _loginNotice;

  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool> get sessionStream => _controller.stream;

  @override
  bool get isSignedIn => _signedIn;

  @override
  String? get accessToken => _signedIn ? token : null;

  @override
  String? get loginNotice => _loginNotice;

  @override
  void clearLoginNotice() => _loginNotice = null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    _signedIn = true;
    _controller.add(true);
  }

  @override
  Future<void> signOut({String? loginNotice}) async {
    if (loginNotice != null) {
      _loginNotice = loginNotice;
    }
    _signedIn = false;
    _controller.add(false);
  }

  void dispose() => _controller.close();
}
