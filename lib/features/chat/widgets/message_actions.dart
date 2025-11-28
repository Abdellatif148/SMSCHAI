import 'package:flutter/material.dart';

enum MessageAction {
  reply,
  forward,
  copy,
  edit,
  delete,
  pin,
  unpin,
  react,
  info,
}

class MessageActionSheet {
  static Future<MessageAction?> show(
    BuildContext context, {
    required bool isMe,
    required bool isPinned,
    bool canEdit = true,
    bool canDelete = true,
  }) async {
    return await showModalBottomSheet<MessageAction>(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Action items
              _ActionItem(
                icon: Icons.reply,
                label: 'Reply',
                onTap: () => Navigator.pop(context, MessageAction.reply),
              ),
              _ActionItem(
                icon: Icons.forward,
                label: 'Forward',
                onTap: () => Navigator.pop(context, MessageAction.forward),
              ),
              _ActionItem(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () => Navigator.pop(context, MessageAction.copy),
              ),
              _ActionItem(
                icon: Icons.add_reaction_outlined,
                label: 'React',
                onTap: () => Navigator.pop(context, MessageAction.react),
              ),

              if (isMe && canEdit)
                _ActionItem(
                  icon: Icons.edit,
                  label: 'Edit',
                  onTap: () => Navigator.pop(context, MessageAction.edit),
                ),

              _ActionItem(
                icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                label: isPinned ? 'Unpin' : 'Pin',
                onTap: () => Navigator.pop(
                  context,
                  isPinned ? MessageAction.unpin : MessageAction.pin,
                ),
              ),

              if (canDelete)
                _ActionItem(
                  icon: Icons.delete_outline,
                  label: isMe ? 'Delete for everyone' : 'Delete for me',
                  onTap: () => Navigator.pop(context, MessageAction.delete),
                  isDestructive: true,
                ),

              _ActionItem(
                icon: Icons.info_outline,
                label: 'Message info',
                onTap: () => Navigator.pop(context, MessageAction.info),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Colors.white;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 16)),
      onTap: onTap,
      dense: true,
    );
  }
}

class EditMessageDialog {
  static Future<String?> show(
    BuildContext context, {
    required String currentText,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: currentText,
    );

    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2C34),
          title: const Text(
            'Edit Message',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type a message',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00A884)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text.trim());
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Color(0xFF00A884)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DeleteMessageDialog {
  static Future<bool> show(BuildContext context, {required bool isMe}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2C34),
          title: const Text(
            'Delete message?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            isMe
                ? 'This message will be deleted for everyone in this chat.'
                : 'This message will be deleted for you only.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
