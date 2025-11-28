import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/message_provider.dart';
import '../../services/database_service.dart';
import '../common/skeleton_loader.dart';
import '../common/message_status_indicator.dart';
import 'widgets/message_bubble.dart';
import 'widgets/chat_input.dart';
import 'widgets/message_action_menu.dart';
import 'widgets/reaction_picker.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final int? threadId;
  final bool isGroup;
  final String? groupId;

  const ChatScreen({
    super.key,
    required this.userName,
    this.threadId,
    this.isGroup = false,
    this.groupId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isGroup && widget.groupId != null) {
        context.read<MessageProvider>().loadGroupMessages(widget.groupId!);
      } else {
        context.read<MessageProvider>().loadMessages(widget.userName);
      }
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
        if (widget.isGroup && widget.groupId != null) {
          provider.loadMoreMessages(widget.groupId!, provider.messages.length);
        } else {
          provider.loadMoreMessages(widget.userName, provider.messages.length);
        }
      }
    }
  }

  void _handleSend(String text) async {
    await context.read<MessageProvider>().sendMessage(
      widget.userName,
      text,
      groupId: widget.isGroup ? widget.groupId : null,
    );
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleAttachment(String filePath) {
    // Send attachment via MMS
    context.read<MessageProvider>().sendMessage(
      widget.userName,
      '', // Empty body for attachment-only message
      attachmentPath: filePath,
      groupId: widget.isGroup ? widget.groupId : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending attachment...'),
        backgroundColor: AppTheme.accentColor,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _handleMessageLongPress(Map<String, dynamic> message) {
    final provider = context.read<MessageProvider>();
    final isMe = message['type'] == 2;
    final isPinned = message['is_pinned'] == 1;
    final messageId = message['id'] as int;

    MessageActionMenu.show(
      context,
      isMe: isMe,
      isPinned: isPinned,
      onReply: () {
        // TODO: Implement reply
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply feature coming soon')),
        );
      },
      onCopy: () {
        Clipboard.setData(ClipboardData(text: message['body'] ?? ''));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
      },
      onEdit: isMe
          ? () {
              _showEditDialog(message);
            }
          : null,
      onDelete: isMe
          ? () {
              _showDeleteConfirmDialog(messageId);
            }
          : null,
      onPin: () {
        provider.togglePin(messageId, !isPinned);
      },
      onReact: () {
        ReactionPicker.show(
          context,
          onReactionSelected: (emoji) {
            provider.addReaction(messageId, emoji);
          },
        );
      },
      onInfo: () {
        // TODO: Show info
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> message) {
    final controller = TextEditingController(text: message['body']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<MessageProvider>().editMessage(
                  message['id'] as int,
                  controller.text.trim(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(int messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<MessageProvider>().deleteMessage(messageId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    if (widget.isGroup && widget.groupId != null) {
      await context.read<MessageProvider>().loadGroupMessages(widget.groupId!);
    } else {
      await context.read<MessageProvider>().refresh(widget.userName);
    }
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
                              widget.isGroup && widget.groupId != null
                              ? provider.loadGroupMessages(widget.groupId!)
                              : provider.loadMessages(widget.userName),
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
                      final messageId = message['id'] as int;

                      // Parse reactions
                      Map<String, dynamic>? reactions;
                      if (message['reactions'] != null) {
                        if (message['reactions'] is String) {
                          reactions = Map<String, dynamic>.from(
                            DatabaseService().parseJson(message['reactions']),
                          );
                        } else if (message['reactions'] is Map) {
                          reactions = Map<String, dynamic>.from(
                            message['reactions'],
                          );
                        }
                      }

                      return Opacity(
                        opacity: isSending ? 0.6 : 1.0,
                        child: MessageBubble(
                          message: message['body'] ?? '',
                          time: time,
                          isMe: isMe,
                          status: isMe ? message.messageStatus : null,
                          attachmentUrl: message['attachment_url'],
                          attachmentType: message['attachment_type'],
                          reactions: reactions,
                          isPinned: message['is_pinned'] == 1,
                          isEdited: message['edited_at'] != null,
                          isDeleted: message['is_deleted'] == 1,
                          onLongPress: () => _handleMessageLongPress(message),
                          onReactionTap: (emoji) {
                            // For now, just add reaction again (provider handles logic)
                            context.read<MessageProvider>().addReaction(
                              messageId,
                              emoji,
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          ChatInput(onSend: _handleSend, onAttachment: _handleAttachment),
        ],
      ),
    );
  }
}
