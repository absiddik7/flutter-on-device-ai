import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/download_service.dart';
import '../services/llm_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final service = DownloadService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});
