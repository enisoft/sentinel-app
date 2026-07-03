import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../domain/services/hash_service.dart';

/// SHA-256 real do arquivo original — hex lowercase 64 chars.
class CryptoHashService implements HashService {
  @override
  Future<String> hashFile(String localPath) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw StateError('Arquivo não encontrado para hash: $localPath');
    }

    final digest = await sha256.bind(file.openRead()).first;
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
