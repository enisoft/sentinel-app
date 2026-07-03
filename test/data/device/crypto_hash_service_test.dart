import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentinel_app/data/device/crypto_hash_service.dart';
import 'package:sentinel_app/data/fakes/minimal_jpeg_bytes.dart';

void main() {
  test('hashFile returns SHA-256 hex of file bytes', () async {
    final dir = await Directory.systemTemp.createTemp('sentinel_hash_test_');
    addTearDown(() => dir.deleteSync(recursive: true));

    final file = File('${dir.path}/sample.jpg');
    await file.writeAsBytes(kMinimalJpegBytes);

    final service = CryptoHashService();
    final hash = await service.hashFile(file.path);

    final expected = sha256.convert(kMinimalJpegBytes).toString();
    expect(hash, expected);
    expect(hash, hasLength(64));
    expect(hash, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('hashFile handles larger files via streaming', () async {
    final dir = await Directory.systemTemp.createTemp('sentinel_hash_large_');
    addTearDown(() => dir.deleteSync(recursive: true));

    const totalBytes = 8 * 1024 * 1024;
    const chunkSize = 64 * 1024;
    final file = File('${dir.path}/large.bin');
    final sink = file.openWrite();
    for (var offset = 0; offset < totalBytes; offset += chunkSize) {
      final length = min(chunkSize, totalBytes - offset);
      sink.add(
        Uint8List.fromList(
          List<int>.generate(length, (i) => (offset + i) % 256),
        ),
      );
    }
    await sink.close();

    final expected = (await sha256.bind(file.openRead()).first).toString();

    final service = CryptoHashService();
    final hash = await service.hashFile(file.path);

    expect(hash, expected);
    expect(hash, hasLength(64));
  });
}
