import '../../core/bootstrap/bootstrap_messages.dart';
import '../remote/api_exception.dart';
import '../repositories/operator_profile_repository.dart';
import 'catalog_sync_service.dart';

class BootstrapResult {
  const BootstrapResult({
    required this.profileLoaded,
    required this.catalogSynced,
    this.catalogError,
  });

  final bool profileLoaded;
  final bool catalogSynced;
  final String? catalogError;
}

class BootstrapService {
  BootstrapService(this._profileRepo, this._catalogSync);

  final OperatorProfileRepository _profileRepo;
  final CatalogSyncService _catalogSync;

  Future<BootstrapResult> run() async {
    try {
      await _profileRepo.fetchAndCache();
    } on ApiException catch (e) {
      if (e.isUnauthorized) rethrow;
      if (e.isNetworkError) {
        final cached = await _profileRepo.getCached();
        if (cached == null) {
          return const BootstrapResult(
            profileLoaded: false,
            catalogSynced: false,
            catalogError: BootstrapMessages.offlineFirstAccess,
          );
        }
      } else {
        rethrow;
      }
    }

    final catalogResult = await _catalogSync.syncAll();

    return BootstrapResult(
      profileLoaded: true,
      catalogSynced: catalogResult.success,
      catalogError: catalogResult.error,
    );
  }
}
