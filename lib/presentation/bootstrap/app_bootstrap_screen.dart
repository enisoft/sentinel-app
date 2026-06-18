import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/auth/auth_messages.dart';
import '../../data/remote/api_exception.dart';
import '../../data/services/bootstrap_service.dart';
import '../../data/services/occurrence_sync_foreground_runner.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../capture/capture_home_screen.dart';

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

    final service = getIt<BootstrapService>();

    try {
      final result = await service.run();
      if (!mounted) return;

      final syncResult = await getIt<OccurrenceSyncForegroundRunner>().runIfPending();
      if (syncResult?.unauthorized == true) {
        return;
      }

      if (!mounted) return;
      setState(() => _result = result);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _auth.signOut(loginNotice: AuthMessages.sessionExpired);
        return;
      }
      if (!mounted) return;
      setState(() {
        _result = BootstrapResult(
          profileLoaded: false,
          catalogSynced: false,
          catalogError: e.message,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_auth.isSignedIn) {
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

    return CaptureHomeScreen(
      catalogSyncWarning: _result?.catalogSynced == false
          ? _result?.catalogError ?? 'Falha ao sincronizar catálogo.'
          : null,
      onRetryCatalogSync: _runBootstrap,
    );
  }
}

