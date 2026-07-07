import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../bootstrap/app_bootstrap_screen.dart';
import 'login_screen.dart';

/// Redireciona para login ou bootstrap conforme sessão Supabase.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.authGateway});

  final AuthGateway? authGateway;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthGateway get _auth => widget.authGateway ?? getIt<AuthGateway>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _auth.appAccessStream,
      initialData: _auth.canAccessApp,
      builder: (context, snapshot) {
        final canAccess = snapshot.data ?? false;
        if (!canAccess) {
          return LoginScreen(authGateway: widget.authGateway);
        }
        return AppBootstrapScreen(authGateway: widget.authGateway);
      },
    );
  }
}
