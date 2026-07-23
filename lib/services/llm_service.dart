import 'dart:async';

import 'package:fllama/fllama.dart';
import 'package:fllama/fllama_type.dart';

import '../core/constants.dart';
import '../models/chat_message.dart';

class LlmService {
  LlmService();

  double _contextId = -1;
  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;
  bool get isReady => _contextId > 0;

  StreamSubscription<Map<Object?, dynamic>>? _tokenSubscription;

  void Function(String token)? _onToken;
  void Function()? _onComplete;
  void Function(String error)? _onError;

  Future<void> initModel(
    String modelPath, {
    void Function(double progress)? onLoadProgress,
  }) async {
    _tokenSubscription = Fllama.instance()?.onTokenStream?.listen(
      _handleStreamEvent,
    );

    final result = await Fllama.instance()?.initContext(
      modelPath,
      nCtx: AppConstants.contextSize,
      nBatch: AppConstants.batchSize,
      emitLoadProgress: true,
    );

    final id = result?['contextId'];
    if (id == null || (id is num && id <= 0)) {
      throw Exception('Failed to initialise model context (result=$result)');
    }
    _contextId = (id as num).toDouble();
  }

  Future<void> sendMessage({
    required List<ChatMessage> history,
    required void Function(String token) onToken,
    required void Function() onComplete,
    void Function(String error)? onError,
  }) async {
    if (_isGenerating || !isReady) return;
    _isGenerating = true;
    _onToken = onToken;
    _onComplete = onComplete;
    _onError = onError;

    try {
      final messages = <RoleContent>[
        RoleContent(role: 'system', content: AppConstants.systemPrompt),
        ...history.map((m) => RoleContent(role: m.role, content: m.content)),
      ];

      String? prompt;
      try {
        prompt = await Fllama.instance()?.getFormattedChat(
          _contextId,
          messages: messages,
        );
      } catch (_) {
        prompt = _buildChatMlPrompt(messages);
      }

      prompt ??= _buildChatMlPrompt(messages);

      await Fllama.instance()?.completion(
        _contextId,
        prompt: prompt,
        nPredict: AppConstants.maxTokens,
        temperature: AppConstants.temperature,
        emitRealtimeCompletion: true,
        stop: ['<|endoftext|>', '<|im_end|>'],
      );

      _isGenerating = false;
      _onComplete?.call();
    } catch (e) {
      _isGenerating = false;
      _onError?.call(e.toString());
    } finally {
      _onToken = null;
      _onComplete = null;
      _onError = null;
    }
  }

  Future<void> stopGeneration() async {
    if (!_isGenerating || !isReady) return;
    try {
      await Fllama.instance()?.stopCompletion(contextId: _contextId);
    } catch (_) {}
    _isGenerating = false;
    _onComplete?.call();
    _onToken = null;
    _onComplete = null;
    _onError = null;
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    try {
      await Fllama.instance()?.releaseAllContexts();
    } catch (_) {}
    _contextId = -1;
  }

  void _handleStreamEvent(Map<Object?, dynamic> data) {
    final function = data['function'];
    if (function == 'completion') {
      final token = data['result']?['token'] as String? ?? '';
      if (token.isNotEmpty) {
        _onToken?.call(token);
      }
    }
  }

  String _buildChatMlPrompt(List<RoleContent> messages) {
    final buffer = StringBuffer();
    for (final msg in messages) {
      buffer.writeln('<|im_start|>${msg.role}');
      buffer.writeln(msg.content);
      buffer.writeln('<|im_end|>');
    }
    buffer.writeln('<|im_start|>assistant');
    return buffer.toString();
  }
}
