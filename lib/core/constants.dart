library;

class AppConstants {
  AppConstants._();

  // Qwen 2.5 1.5B model 
  static const String modelDownloadUrl =
      'https://huggingface.co/bartowski/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/'
      'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf?download=true';

  static const String modelFileName = 'Qwen2.5-1.5B-Instruct-Q4_K_M.gguf';

  static const int minValidModelSizeBytes = 500 * 1024 * 1024;

  static const int maxTokens = 256;
  static const int contextSize = 2048;
  static const int batchSize = 512;
  static const double temperature = 0.7;
  static const String systemPrompt =
      'You are a helpful, concise AI assistant running locally on-device.';

  static const String appName = 'Local AI';
  static const String downloadTitle = 'Preparing Your AI';
  static const String downloadSubtitle =
      'Downloading the Qwen 2.5 1.5B model (~1.1 GB).\n'
      'This only happens once.';
  static const String chatHint = 'Ask me anything…';
}
