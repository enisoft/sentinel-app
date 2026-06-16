import 'sync_state.dart';

enum SyncPhase {
  mediaUploading,
  jsonSyncing;

  String get storageValue => switch (this) {
        SyncPhase.mediaUploading => 'media_uploading',
        SyncPhase.jsonSyncing => 'json_syncing',
      };

  static SyncPhase fromStorage(String value) => switch (value) {
        'media_uploading' => SyncPhase.mediaUploading,
        'json_syncing' => SyncPhase.jsonSyncing,
        _ => throw ArgumentError('Unknown SyncPhase: $value'),
      };

  SyncState get correspondingState => switch (this) {
        SyncPhase.mediaUploading => SyncState.mediaUploading,
        SyncPhase.jsonSyncing => SyncState.jsonSyncing,
      };
}
