enum SyncState {
  localSaved,
  mediaUploading,
  mediaDone,
  jsonSyncing,
  synced,
  failed;

  String get storageValue => switch (this) {
        SyncState.localSaved => 'local_saved',
        SyncState.mediaUploading => 'media_uploading',
        SyncState.mediaDone => 'media_done',
        SyncState.jsonSyncing => 'json_syncing',
        SyncState.synced => 'synced',
        SyncState.failed => 'failed',
      };

  static SyncState fromStorage(String value) => switch (value) {
        'local_saved' => SyncState.localSaved,
        'media_uploading' => SyncState.mediaUploading,
        'media_done' => SyncState.mediaDone,
        'json_syncing' => SyncState.jsonSyncing,
        'synced' => SyncState.synced,
        'failed' => SyncState.failed,
        _ => throw ArgumentError('Unknown SyncState: $value'),
      };

  bool get isPending => this != SyncState.synced;
}
