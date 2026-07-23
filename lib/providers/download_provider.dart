import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'service_providers.dart';

class DownloadState {
  const DownloadState({
    this.isChecking = true,
    this.isDownloading = false,
    this.hasError = false,
    this.progress = 0.0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage = '',
    this.modelPath,
  });

  final bool isChecking;
  final bool isDownloading;
  final bool hasError;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final String errorMessage;
  final String? modelPath;

  DownloadState copyWith({
    bool? isChecking,
    bool? isDownloading,
    bool? hasError,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    String? errorMessage,
    String? modelPath,
  }) {
    return DownloadState(
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      hasError: hasError ?? this.hasError,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      modelPath: modelPath ?? this.modelPath,
    );
  }
}

class DownloadNotifier extends Notifier<DownloadState> {
  @override
  DownloadState build() {
    // Automatically start checking the model when the notifier is initialized.
    Future.microtask(_checkModel);
    return const DownloadState();
  }

  Future<void> _checkModel() async {
    state = state.copyWith(isChecking: true, hasError: false, errorMessage: '');

    try {
      final downloadService = ref.read(downloadServiceProvider);
      if (await downloadService.isModelDownloaded()) {
        final path = await downloadService.modelFilePath;
        state = state.copyWith(isChecking: false, modelPath: path);
        return;
      }
      final path = await downloadService.modelFilePath;
      state = state.copyWith(isChecking: false, isDownloading: true);
      await _startDownload(path);
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _startDownload(String savePath) async {
    try {
      final downloadService = ref.read(downloadServiceProvider);
      await downloadService.downloadModel(
        savePath: savePath,
        onProgress: (progress, received, total) {
          state = state.copyWith(
            progress: progress,
            receivedBytes: received,
            totalBytes: total,
          );
        },
      );
      state = state.copyWith(isDownloading: false, modelPath: savePath);
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        hasError: true,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void retryDownload() {
    _checkModel();
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (msg.contains('cancel')) {
      return 'Download was cancelled.';
    }
    return 'Download failed: $msg';
  }
}

final downloadProvider = NotifierProvider<DownloadNotifier, DownloadState>(() {
  return DownloadNotifier();
});
