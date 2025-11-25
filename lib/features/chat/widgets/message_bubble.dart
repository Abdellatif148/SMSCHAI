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

  const MessageBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    this.status,
    this.attachmentUrl,
    this.attachmentType,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppTheme.messageBubbleSent
              : AppTheme.messageBubbleReceived,
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attachmentUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(attachmentUrl!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
            if (message.isNotEmpty)
              Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
                if (isMe && status != null) ...[
                  const SizedBox(width: 4),
                  MessageStatusIndicator(status: status!, isMe: isMe),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
