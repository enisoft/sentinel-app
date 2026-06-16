import 'sync_state.dart';

class InvalidSyncTransitionException implements Exception {
  InvalidSyncTransitionException(this.from, this.to, [this.reason]);

  final SyncState from;
  final SyncState to;
  final String? reason;

  @override
  String toString() {
    final detail = reason == null ? '' : ' ($reason)';
    return 'InvalidSyncTransitionException: $from -> $to$detail';
  }
}
