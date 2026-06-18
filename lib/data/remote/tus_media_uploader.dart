import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

import '../../core/config/app_config.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/gateways/media_uploader.dart';
import '../repositories/occurrence_repository.dart';
import 'media_upload_exception.dart';

/// Upload TUS resumable para Supabase Storage — único ponto que importa tus_client_dart.
class TusMediaUploader implements MediaUploader {
  TusMediaUploader({
    required AppConfig config,
    required AuthGateway authGateway,
    required OccurrenceRepository occurrenceRepository,
  })  : _config = config,
        _auth = authGateway,
        _occurrences = occurrenceRepository;

  static const bucketName = 'sentinel-media';
  static const chunkSize = 6 * 1024 * 1024;

  final AppConfig _config;
  final AuthGateway _auth;
  final OccurrenceRepository _occurrences;

  Uri get _tusEndpoint => Uri.parse(
        '${_config.supabaseUrl.replaceAll(RegExp(r'/+$'), '')}/storage/v1/upload/resumable',
      );

  @override
  Future<void> uploadOccurrenceMedia({required String occurrenceId}) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      throw MediaUploadException(401, 'Sessão ausente para upload de mídia.');
    }

    final media = await _occurrences.getMedia(occurrenceId);
    for (final item in media) {
      if (item.remotePath != null) continue;

      final objectPath = OccurrenceRepository.canonicalStoragePath(
        occurrenceId: occurrenceId,
        mediaId: item.id,
        mimeType: item.mimeType,
      );

      await _uploadSingle(
        localPath: item.localPath,
        objectPath: objectPath,
        mimeType: item.mimeType,
        mediaId: item.id,
        accessToken: token,
      );

      await _occurrences.setRemotePath(item.id, objectPath);
    }
  }

  Future<void> _uploadSingle({
    required String localPath,
    required String objectPath,
    required String mimeType,
    required String mediaId,
    required String accessToken,
  }) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      throw MediaUploadException(null, 'Arquivo local não encontrado: $localPath');
    }

    final storeDir = await _storeDirectoryFor(mediaId);
    final xFile = XFile(localPath);
    final client = TusClient(
      xFile,
      store: TusFileStore(storeDir),
      maxChunkSize: chunkSize,
      retries: 3,
      retryInterval: 2,
      retryScale: RetryScale.exponential,
    );

    try {
      await client.upload(
        uri: _tusEndpoint,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'x-upsert': 'true',
        },
        metadata: {
          'bucketName': bucketName,
          'objectName': objectPath,
          'contentType': mimeType,
        },
      );
    } on ProtocolException catch (e) {
      final code = e.code;
      if (code == 401) {
        throw MediaUploadException(401, e.message);
      }
      throw MediaUploadException(code, e.message);
    } on SocketException catch (e) {
      throw MediaUploadException(null, e.message);
    } on HttpException catch (e) {
      throw MediaUploadException(null, e.message);
    }
  }

  Future<Directory> _storeDirectoryFor(String mediaId) async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory('${tempDir.path}/tus_uploads/$mediaId');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
