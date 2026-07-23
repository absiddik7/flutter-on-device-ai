import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

class DownloadService {
  DownloadService() : _dio = Dio();

  final Dio _dio;
  CancelToken? _cancelToken;

  Future<String> get modelFilePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.modelFileName}';
  }

  Future<bool> isModelDownloaded() async {
    final path = await modelFilePath;
    final file = File(path);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > AppConstants.minValidModelSizeBytes;
  }

  Future<void> downloadModel({
    required String savePath,
    required void Function(double progress, int received, int total) onProgress,
  }) async {
    _cancelToken = CancelToken();

    await _dio.download(
      AppConstants.modelDownloadUrl,
      savePath,
      cancelToken: _cancelToken,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          onProgress(received / total, received, total);
        }
      },
    );
  }

  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
  }

  void dispose() {
    cancelDownload();
    _dio.close();
  }
}
