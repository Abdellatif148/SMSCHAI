import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/message_provider.dart';
import '../common/skeleton_loader.dart';
import '../common/message_status_indicator.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final int? threadId;

  const ChatScreen({super.key, required this.userName, this.threadId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MessageProvider>().loadMessages(widget.userName);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final provider = context.read<MessageProvider>();
      if (!provider.isLoading) {
        provider.loadMoreMessages(widget.userName, provider.messages.length);
      }
    }
  }

  void _handleSend(String text) async {
    await context.read<MessageProvider>().sendMessage(widget.userName, text);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _onRefresh() async {
    await context.read<MessageProvider>().refresh(widget.userName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.secondaryBackground,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () {
            context.read<MessageProvider>().clear();
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryBackground,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Mobile',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: AppTheme.accentColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: AppTheme.accentColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.messages.isEmpty) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return MessageBubbleSkeleton(isMe: index % 2 == 0);
                    },
                  );
                }

                if (provider.error != null && provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading messages',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              provider.loadMessages(widget.userName),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount:
                        provider.messages.length + (provider.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: MessageBubbleSkeleton(),
                        );
                      }

                      final message = provider.messages[index];
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        message['date'] ?? 0,
                      );
                      final time =
                          "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
                      final isMe = message['type'] == 2;
                      final isSending = message['sending'] == true;

                      return Opacity(
                        opacity: isSending ? 0.6 : 1.0,
                        child: MessageBubble(
                          message: message['body'] ?? '',
                          time: time,
                          isMe: isMe,
                          status: isMe ? message.messageStatus : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          ChatInput(onSend: _handleSend),
        ],
      ),
    );
  }
}
