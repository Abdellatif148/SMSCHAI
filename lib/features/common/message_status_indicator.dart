import 'package:flutter/material.dart';
import '../../core/theme.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final bool isMe;

  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.isMe = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMe) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_getIcon(), size: 14, color: _getColor()),
        if (status == MessageStatus.read ||
            status == MessageStatus.delivered) ...[
          const SizedBox(width: 2),
          Icon(_getIcon(), size: 14, color: _getColor()),
        ],
      ],
    );
  }

  IconData _getIcon() {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
      case MessageStatus.delivered:
      case MessageStatus.read:
        return Icons.check;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getColor() {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
      case MessageStatus.delivered:
        return Colors.grey.withValues(alpha: 0.7);
      case MessageStatus.read:
        return AppTheme.accentColor;
      case MessageStatus.failed:
        return AppTheme.errorColor;
    }
  }
}

// Extension to get MessageStatus from message data
extension MessageStatusExtension on Map<String, dynamic> {
  MessageStatus get messageStatus {
    if (this['sending'] == true) return MessageStatus.sending;
    if (this['failed'] == true) return MessageStatus.failed;
    if (this['read'] == true || this['read'] == 1) return MessageStatus.read;
    if (this['delivered'] == true) return MessageStatus.delivered;
    if (this['type'] == 2) return MessageStatus.sent;
    return MessageStatus.sent;
  }
}
