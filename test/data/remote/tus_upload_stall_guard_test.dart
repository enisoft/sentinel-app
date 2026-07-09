import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/remote/tus_upload_stall_guard.dart';

void main() {
  test('aborta após stallTimeout sem progresso', () async {
    var stalled = false;
    final guard = TusUploadStallGuard(
      stallTimeout: const Duration(milliseconds: 50),
      onStalled: () async {
        stalled = true;
      },
    );

    guard.start();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(stalled, isTrue);
    expect(guard.didStall, isTrue);
    guard.stop();
  });

  test('progresso contínuo reinicia timer e não aborta', () async {
    var stalled = false;
    final guard = TusUploadStallGuard(
      stallTimeout: const Duration(milliseconds: 80),
      onStalled: () async {
        stalled = true;
      },
    );

    guard.start();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      guard.onProgress();
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(stalled, isFalse);
    expect(guard.didStall, isFalse);
    guard.stop();
  });

  test('onProgress após start evita stall imediato', () async {
    var stalled = false;
    final guard = TusUploadStallGuard(
      stallTimeout: const Duration(milliseconds: 100),
      onStalled: () async {
        stalled = true;
      },
    );

    guard.start();
    guard.onProgress();
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(stalled, isFalse);
    guard.stop();
  });
}
