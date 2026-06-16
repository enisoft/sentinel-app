/// Contrato de integridade (SHA-256 do original) — implementação real na fase device.
abstract class HashService {
  Future<String> hashFile(String localPath);
}
