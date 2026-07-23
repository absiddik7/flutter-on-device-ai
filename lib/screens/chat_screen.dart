import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../models/chat_message.dart';
import '../services/llm_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.modelPath});

  final String modelPath;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final LlmService _llm = LlmService();
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _modelReady = false;
  bool _modelLoading = true;
  bool _isGenerating = false;
  String? _loadError;

  late final AnimationController _typingDotController;

  @override
  void initState() {
    super.initState();
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initModel();
  }

  @override
  void dispose() {
    _typingDotController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    _llm.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    try {
      await _llm.initModel(widget.modelPath);
      if (!mounted) return;
      setState(() {
        _modelReady = true;
        _modelLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _modelLoading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isGenerating || !_modelReady) return;

    _inputController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _messages.add(ChatMessage(role: 'assistant', content: ''));
      _isGenerating = true;
    });
    _scrollToBottom();

    final history = _messages
        .where((m) => m.content.isNotEmpty)
        .toList();

    await _llm.sendMessage(
      history: history,
      onToken: (token) {
        if (!mounted) return;
        setState(() {
          _messages.last.content += token;
        });
        _scrollToBottom();
      },
      onComplete: () {
        if (!mounted) return;
        setState(() => _isGenerating = false);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _messages.last.content += '\n\n⚠️ Error: $error';
          _isGenerating = false;
        });
      },
    );
  }

  void _stopGeneration() {
    _llm.stopGeneration();
    setState(() => _isGenerating = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (_modelLoading) _buildLoadingBanner(),
              if (_loadError != null) _buildErrorBanner(),
              Expanded(child: _buildMessageList()),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.smart_toy_rounded, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                _modelReady ? 'Online • On-device' : 'Loading model…',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _modelReady
                          ? AppTheme.successGreen
                          : Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const Spacer(),
          if (_modelReady)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.successGreen,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppTheme.surfaceCard.withValues(alpha: 0.8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Loading model into memory…', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.errorRed.withValues(alpha: 0.15),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Model failed to load: $_loadError',
              style: const TextStyle(fontSize: 12, color: AppTheme.errorRed),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              setState(() {
                _loadError = null;
                _modelLoading = true;
              });
              _initModel();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: _messages.length + (_isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _messages.length) {
          return _buildMessageBubble(_messages[index]);
        }
        return _buildTypingIndicator();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Everything runs privately on your device.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isUser ? AppTheme.userBubble : AppTheme.assistantBubble;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: isUser
                  ? [
                      BoxShadow(
                        color: AppTheme.userBubble.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              message.content.isEmpty ? '…' : message.content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.assistantBubble,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: AnimatedBuilder(
            animation: _typingDotController,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.25;
                  final t = ((_typingDotController.value + delay) % 1.0);
                  final opacity = (1.0 - (t - 0.5).abs() * 2).clamp(0.3, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.accentPurple,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              style: const TextStyle(fontSize: 14.5, color: Colors.white),
              decoration: InputDecoration(
                hintText: AppConstants.chatHint,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: _modelReady && !_isGenerating,
              maxLines: 4,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          _isGenerating
              ? _buildStopButton()
              : _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: _modelReady ? AppTheme.accentGradient : null,
        color: _modelReady ? null : AppTheme.surfaceInput,
        borderRadius: BorderRadius.circular(22),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_upward_rounded, size: 22),
        color: Colors.white,
        onPressed: _modelReady ? _sendMessage : null,
      ),
    );
  }

  Widget _buildStopButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
      ),
      child: IconButton(
        icon: const Icon(Icons.stop_rounded, size: 22),
        color: AppTheme.errorRed,
        onPressed: _stopGeneration,
      ),
    );
  }
}
