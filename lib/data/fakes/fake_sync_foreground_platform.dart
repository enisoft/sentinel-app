import '../../platform/sync_foreground_platform.dart';

class FakeSyncForegroundPlatform implements SyncForegroundPlatform {
  int startCallCount = 0;
  int stopCallCount = 0;
  int permissionRequestCount = 0;

  @override
  Future<void> startForegroundService() async {
    startCallCount++;
  }

  @override
  Future<void> stopForegroundService() async {
    stopCallCount++;
  }

  @override
  Future<void> requestNotificationPermission() async {
    permissionRequestCount++;
  }
}
