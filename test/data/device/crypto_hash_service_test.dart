import 'dart:io';

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
}
