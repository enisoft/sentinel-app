import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/auth/auth_messages.dart';
import '../../core/bootstrap/bootstrap_messages.dart';
import '../../data/remote/api_exception.dart';
import '../../data/repositories/operator_profile_repository.dart';
import '../../data/services/bootstrap_service.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../home/home_screen.dart';

/// Executa GET /me + sync de catálogo no startup.
class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key, this.authGateway});

  final AuthGateway? authGateway;

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  BootstrapResult? _result;
  bool _loading = true;

  AuthGateway get _auth => widget.authGateway ?? getIt<AuthGateway>();

  @override
  void initState() {
    super.initState();
    _runBootstrap();
  }

  Future<void> _runBootstrap() async {
    setState(() => _loading = true);

    final refresh = await _auth.tryRefreshSessionSilently();

    final service = getIt<BootstrapService>();

    try {
      final result = await service.run(
        serverUnreachable: refresh.serverUnreachable,
      );
      if (!mounted) return;

      setState(() => _result = result);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        if ((await _auth.tryRefreshSessionSilently()).refreshed) {
          try {
            final result = await service.run();
            if (!mounted) return;
            setState(() => _result = result);
            return;
          } on ApiException catch (retryError) {
            if (!await _handleUnauthorized(retryError)) return;
          }
        } else if (!await _handleUnauthorized(e)) {
          return;
        }
      } else if (e.isNetworkError) {
        if (!mounted) return;
        final cached = await getIt<OperatorProfileRepository>().getCached();
        setState(() {
          _result = BootstrapResult(
            profileLoaded: cached != null,
            catalogSynced: false,
            catalogError: cached == null
                ? BootstrapMessages.offlineFirstAccess
                : null,
          );
        });
      } else {
        if (!mounted) return;
        setState(() {
          _result = BootstrapResult(
            profileLoaded: false,
            catalogSynced: false,
            catalogError: e.message,
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Retorna `true` se deve continuar para estado degradado offline (sem signOut).
  Future<bool> _handleUnauthorized(ApiException e) async {
    if (await _auth.shouldSignOutForUnauthorized(
      statusCode: e.statusCode,
      isNetworkError: e.isNetworkError,
    )) {
      await _auth.signOut(loginNotice: AuthMessages.sessionExpired);
      return false;
    }

    final cached = await getIt<OperatorProfileRepository>().getCached();
    if (!mounted) return false;
    setState(() {
      _result = BootstrapResult(
        profileLoaded: cached != null,
        catalogSynced: false,
        catalogError: cached == null
            ? BootstrapMessages.offlineFirstAccess
            : e.message,
      );
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_auth.canAccessApp) {
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sincronizando...'),
            ],
          ),
        ),
      );
    }

    if (_result?.profileLoaded != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sentinel')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _result?.catalogError ?? 'Falha ao carregar perfil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _runBootstrap,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return HomeScreen(
      catalogSyncWarning: _result?.catalogSynced == false
          ? _result?.catalogError ?? 'Falha ao sincronizar catálogo.'
          : null,
      onRetryCatalogSync: _runBootstrap,
    );
  }
}
