import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import 'service_providers.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isModelReady = false,
    this.isModelLoading = true,
    this.isGenerating = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isModelReady;
  final bool isModelLoading;
  final bool isGenerating;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isModelReady,
    bool? isModelLoading,
    bool? isGenerating,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isModelReady: isModelReady ?? this.isModelReady,
      isModelLoading: isModelLoading ?? this.isModelLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      error:
          error, // intentionally can be set to null if not provided, but wait, error ?? this.error is better if we want to retain it, however usually we clear error on new actions. We'll use a specific clearError parameter or just pass null to clear it. Let's do `error ?? this.error` and we can manually reset by passing '' or another mechanism, actually dart doesn't let us easily null out. We'll just manage error manually or pass an empty string to clear.
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return const ChatState();
  }

  Future<void> initModel(String modelPath) async {
    state = state.copyWith(isModelLoading: true, error: '');
    try {
      final llmService = ref.read(llmServiceProvider);
      await llmService.initModel(modelPath);
      state = state.copyWith(isModelReady: true, isModelLoading: false);
    } catch (e) {
      state = state.copyWith(isModelLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty || state.isGenerating || !state.isModelReady) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    final emptyAssistantMessage = ChatMessage(
      role: 'assistant',
      content: '',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, emptyAssistantMessage],
      isGenerating: true,
      error: '',
    );

    final history = state.messages.where((m) => m.content.isNotEmpty).toList();

    await ref
        .read(llmServiceProvider)
        .sendMessage(
          history: history,
          onToken: (token) {
            final messages = List<ChatMessage>.from(state.messages);
            if (messages.isNotEmpty) {
              final lastMessage = messages.last;
              messages[messages.length - 1] = lastMessage.copyWith(
                content: lastMessage.content + token,
              );
              state = state.copyWith(messages: messages);
            }
          },
          onComplete: () {
            state = state.copyWith(isGenerating: false);
          },
          onError: (error) {
            final messages = List<ChatMessage>.from(state.messages);
            if (messages.isNotEmpty) {
              final lastMessage = messages.last;
              messages[messages.length - 1] = lastMessage.copyWith(
                content: '${lastMessage.content}\n\n⚠️ Error: $error',
              );
            }
            state = state.copyWith(
              messages: messages,
              isGenerating: false,
              error: error,
            );
          },
        );
  }

  void stopGeneration() {
    ref.read(llmServiceProvider).stopGeneration();
    state = state.copyWith(isGenerating: false);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
