import '../../domain/services/hash_service.dart';

/// SHA-256 determinístico em memória — sem leitura de arquivo real.
class FakeHashService implements HashService {
  FakeHashService({this.prefix = 'fake-sha256'});

  final String prefix;
  int hashCallCount = 0;

  @override
  Future<String> hashFile(String localPath) async {
    hashCallCount++;
    return '$prefix:${localPath.hashCode.abs().toRadixString(16).padLeft(8, '0')}';
  }
}
