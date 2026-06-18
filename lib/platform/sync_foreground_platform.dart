import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ponte nativa para Foreground Service de sync (Android).
abstract class SyncForegroundPlatform {
  Future<void> startForegroundService();

  Future<void> stopForegroundService();

  Future<void> requestNotificationPermission();
}

class MethodChannelSyncForegroundPlatform implements SyncForegroundPlatform {
  MethodChannelSyncForegroundPlatform({
    MethodChannel? channel,
  }) : _channel = channel ??
            const MethodChannel('com.sentinel.sentinel_app/sync_foreground');

  final MethodChannel _channel;

  @override
  Future<void> startForegroundService() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('startForegroundService');
  }

  @override
  Future<void> stopForegroundService() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('stopForegroundService');
  }

  @override
  Future<void> requestNotificationPermission() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('requestNotificationPermission');
  }
}

class NoOpSyncForegroundPlatform implements SyncForegroundPlatform {
  @override
  Future<void> startForegroundService() async {}

  @override
  Future<void> stopForegroundService() async {}

  @override
  Future<void> requestNotificationPermission() async {}
}

SyncForegroundPlatform createSyncForegroundPlatform() {
  if (kIsWeb || !Platform.isAndroid) {
    return NoOpSyncForegroundPlatform();
  }
  return MethodChannelSyncForegroundPlatform();
}
