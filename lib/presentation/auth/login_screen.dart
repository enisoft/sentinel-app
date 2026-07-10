import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../app/di.dart';
import '../../app/theme.dart';
import '../../domain/gateways/auth_gateway.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authGateway});

  final AuthGateway? authGateway;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;

  AuthGateway get _auth => widget.authGateway ?? getIt<AuthGateway>();

  @override
  void initState() {
    super.initState();
    final notice = _auth.loginNotice;
    if (notice != null) {
      _error = notice;
      _auth.clearLoginNotice();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tela de marca: sempre escura (carvão + amarelo-sinalização),
    // independente do tema do sistema — casa com o splash.
    final dark = RelatoTheme.dark();
    return Theme(
      data: dark,
      child: Scaffold(
        backgroundColor: RelatoColors.charcoal,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'docs/favicon.png',
                          width: 72,
                          height: 72,
                          semanticLabel: 'Relato',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Relato',
                      style: dark.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: RelatoColors.inkDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registro de ocorrências em campo',
                      style: dark.textTheme.bodyMedium?.copyWith(
                        color: RelatoColors.inkMutedDark,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      key: const Key('login_email'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o e-mail'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('login_password'),
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                      ),
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Informe a senha' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        key: const Key('login_error'),
                        style: TextStyle(color: dark.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('login_submit'),
                      onPressed: _loading ? null : _onSubmit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Text(
                        'Acesso restrito a operadores autorizados',
                        style: dark.textTheme.bodySmall?.copyWith(
                          color: RelatoColors.inkMutedDark,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
