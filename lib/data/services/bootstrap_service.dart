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
    await _profileRepo.fetchAndCache();

    final catalogResult = await _catalogSync.syncAll();

    return BootstrapResult(
      profileLoaded: true,
      catalogSynced: catalogResult.success,
      catalogError: catalogResult.error,
    );
  }
}
