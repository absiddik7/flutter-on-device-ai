import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../services/download_service.dart';
import 'chat_screen.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with SingleTickerProviderStateMixin {
  final DownloadService _downloadService = DownloadService();

  bool _isChecking = true;
  bool _isDownloading = false;
  bool _hasError = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String _errorMessage = '';

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkModel();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _downloadService.dispose();
    super.dispose();
  }

  Future<void> _checkModel() async {
    setState(() {
      _isChecking = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (await _downloadService.isModelDownloaded()) {
        final path = await _downloadService.modelFilePath;
        _navigateToChat(path);
        return;
      }
      final path = await _downloadService.modelFilePath;
      setState(() {
        _isChecking = false;
        _isDownloading = true;
      });
      await _startDownload(path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _startDownload(String savePath) async {
    try {
      await _downloadService.downloadModel(
        savePath: savePath,
        onProgress: (progress, received, total) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            _receivedBytes = received;
            _totalBytes = total;
          });
        },
      );
      _navigateToChat(savePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _hasError = true;
        _errorMessage = _friendlyError(e);
      });
    }
  }

  void _navigateToChat(String modelPath) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(modelPath: modelPath),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  if (_isChecking) _buildCheckingState(),
                  if (_isDownloading && !_hasError) _buildDownloadingState(),
                  if (_hasError) _buildErrorState(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.06);
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: AppTheme.accentGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentPurple.withValues(alpha: 0.35),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.smart_toy_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCheckingState() {
    return Column(
      children: [
        Text(
          AppConstants.downloadTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          'Checking for existing model…',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ],
    );
  }

  Widget _buildDownloadingState() {
    final percentText = '${(_progress * 100).toStringAsFixed(1)}%';
    final sizeText = _totalBytes > 0
        ? '${_formatBytes(_receivedBytes)} / ${_formatBytes(_totalBytes)}'
        : '';

    return Column(
      children: [
        Text(
          AppConstants.downloadTitle,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.downloadSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.5,
              ),
        ),
        const SizedBox(height: 36),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceInput,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: _progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.progressGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              percentText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentPurple,
                  ),
            ),
            Text(
              sizeText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_off_rounded,
            size: 32,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Download Failed',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _checkModel,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Retry Download'),
        ),
      ],
    );
  }
}
