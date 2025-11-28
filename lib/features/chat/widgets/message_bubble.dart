import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../common/message_status_indicator.dart';

import 'dart:io';

class MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final MessageStatus? status;
  final String? attachmentUrl;
  final String? attachmentType;
  final Map<String, dynamic>? reactions;
  final bool isPinned;
  final bool isEdited;
  final bool isDeleted;
  final VoidCallback? onLongPress;
  final Function(String emoji)? onReactionTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    this.status,
    this.attachmentUrl,
    this.attachmentType,
    this.reactions,
    this.isPinned = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.onLongPress,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDeleted
                    ? Colors.grey.withValues(alpha: 0.2)
                    : (isMe
                          ? AppTheme.messageBubbleSent
                          : AppTheme.messageBubbleReceived),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: isPinned
                    ? Border.all(color: AppTheme.accentColor, width: 2)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pinned',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (attachmentUrl != null && !isDeleted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildAttachmentPreview(context),
                      ),
                    ),
                  if (message.isNotEmpty || isDeleted)
                    Text(
                      isDeleted ? 'This message was deleted' : message,
                      style: TextStyle(
                        color: isDeleted
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.white,
                        fontSize: 16,
                        fontStyle: isDeleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isEdited && !isDeleted)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            '(edited)',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                      if (isMe && status != null && !isDeleted) ...[
                        const SizedBox(width: 4),
                        MessageStatusIndicator(status: status!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (reactions != null && reactions!.isNotEmpty && !isDeleted)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 20,
                  right: isMe ? 20 : 0,
                  top: 0,
                ),
                child: Wrap(
                  spacing: 4,
                  children: reactions!.entries.map((entry) {
                    final emoji = entry.key;
                    final users = entry.value as List;
                    final count = users.length;
                    final hasReacted = users.contains('me');

                    return GestureDetector(
                      onTap: () => onReactionTap?.call(emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasReacted
                              ? AppTheme.accentColor.withValues(alpha: 0.3)
                              : const Color(0xFF1F2C34),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF1F2C34),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '$emoji $count',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(BuildContext context) {
    if (attachmentType != null && attachmentType!.startsWith('video/')) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.black26,
        child: const Center(
          child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
        ),
      );
    } else if (attachmentType != null &&
        attachmentType!.startsWith('application/')) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white.withValues(alpha: 0.1),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Document',
                style: const TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Image.file(
      File(attachmentUrl!),
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Try network image if file not found (for synced messages)
        if (attachmentUrl!.startsWith('http')) {
          return Image.network(
            attachmentUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, color: Colors.white),
          );
        }
        return const Icon(Icons.broken_image, color: Colors.white);
      },
    );
  }
}
