import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tus_client_dart/tus_client_dart.dart';

import '../../core/config/app_config.dart';
import '../../domain/gateways/auth_gateway.dart';
import '../../domain/gateways/media_uploader.dart';
import '../repositories/occurrence_repository.dart';
import 'media_upload_exception.dart';
import 'sentinel_tus_client.dart';
import 'tus_upload_stall_guard.dart';

/// Upload TUS resumable para Supabase Storage — único ponto que importa tus_client_dart.
class TusMediaUploader implements MediaUploader {
  TusMediaUploader({
    required AppConfig config,
    required AuthGateway authGateway,
    required OccurrenceRepository occurrenceRepository,
    Duration? stallTimeout,
  })  : _config = config,
        _auth = authGateway,
        _occurrences = occurrenceRepository,
        _stallTimeout = stallTimeout ??
            Duration(seconds: config.tusUploadStallTimeoutSeconds);

  static const bucketName = 'sentinel-media';
  static const chunkSize = 6 * 1024 * 1024;

  final AppConfig _config;
  final AuthGateway _auth;
  final OccurrenceRepository _occurrences;
  final Duration _stallTimeout;

  Uri get _tusEndpoint => Uri.parse(
        '${_config.supabaseUrl.replaceAll(RegExp(r'/+$'), '')}/storage/v1/upload/resumable',
      );

  @override
  Future<void> uploadOccurrenceMedia({required String occurrenceId}) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      throw MediaUploadException(null, 'Sessão offline — upload adiado.');
    }

    final media = await _occurrences.getMedia(occurrenceId);
    if (media.any((item) => item.remotePath == null)) {
      await _applyDebugUploadDelayIfConfigured();
    }

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
    final client = SentinelTusClient(
      xFile,
      stallTimeout: _stallTimeout,
      store: TusFileStore(storeDir),
      maxChunkSize: chunkSize,
      retries: 3,
      retryInterval: 2,
      retryScale: RetryScale.exponential,
    );

    final guard = TusUploadStallGuard(
      stallTimeout: _stallTimeout,
      onStalled: () async {
        await client.pauseUpload();
        client.abort();
      },
    );
    guard.start();

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
        onProgress: (_, __) => guard.onProgress(),
      );
    } on ProtocolException catch (e) {
      if (guard.didStall) {
        throw MediaUploadException(null, 'Upload parado por inatividade de rede');
      }
      final code = e.code;
      if (code == 401) {
        throw MediaUploadException(401, e.message);
      }
      throw MediaUploadException(code, e.message);
    } on SocketException catch (e) {
      if (guard.didStall) {
        throw MediaUploadException(null, 'Upload parado por inatividade de rede');
      }
      throw MediaUploadException(null, e.message);
    } on HttpException catch (e) {
      if (guard.didStall) {
        throw MediaUploadException(null, 'Upload parado por inatividade de rede');
      }
      throw MediaUploadException(null, e.message);
    } catch (e) {
      if (guard.didStall) {
        throw MediaUploadException(null, 'Upload parado por inatividade de rede');
      }
      rethrow;
    } finally {
      guard.stop();
      client.abort();
    }
  }

  Future<void> _applyDebugUploadDelayIfConfigured() async {
    final seconds = _config.syncDebugUploadDelaySeconds;
    if (seconds > 0) {
      await Future<void>.delayed(Duration(seconds: seconds));
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
