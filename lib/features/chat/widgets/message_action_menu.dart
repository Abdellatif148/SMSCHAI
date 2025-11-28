import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class MessageActionMenu extends StatelessWidget {
  final bool isMe;
  final bool isPinned;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onPin;
  final VoidCallback? onReact;
  final VoidCallback? onForward;
  final VoidCallback? onInfo;

  const MessageActionMenu({
    super.key,
    required this.isMe,
    required this.isPinned,
    required this.onReply,
    required this.onCopy,
    this.onEdit,
    this.onDelete,
    required this.onPin,
    this.onReact,
    this.onForward,
    this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOption(
              icon: Icons.reply,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            _buildOption(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () {
                Navigator.pop(context);
                onCopy();
              },
            ),
            if (onReact != null)
              _buildOption(
                icon: Icons.add_reaction_outlined,
                label: 'React',
                onTap: () {
                  Navigator.pop(context);
                  onReact!();
                },
              ),
            if (isMe) ...[
              _buildOption(
                icon: Icons.edit,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              _buildOption(
                icon: Icons.delete,
                label: 'Delete',
                color: AppTheme.errorColor,
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
            _buildOption(
              icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              label: isPinned ? 'Unpin' : 'Pin',
              onTap: () {
                Navigator.pop(context);
                onPin();
              },
            ),
            if (onForward != null)
              _buildOption(
                icon: Icons.forward,
                label: 'Forward',
                onTap: () {
                  Navigator.pop(context);
                  onForward!();
                },
              ),
            if (onInfo != null)
              _buildOption(
                icon: Icons.info_outline,
                label: 'Info',
                onTap: () {
                  Navigator.pop(context);
                  onInfo!();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textPrimary),
      title: Text(
        label,
        style: TextStyle(color: color ?? AppTheme.textPrimary, fontSize: 16),
      ),
      onTap: onTap,
    );
  }

  static void show(
    BuildContext context, {
    required bool isMe,
    required bool isPinned,
    required VoidCallback onReply,
    required VoidCallback onCopy,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    required VoidCallback onPin,
    VoidCallback? onReact,
    VoidCallback? onForward,
    VoidCallback? onInfo,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MessageActionMenu(
        isMe: isMe,
        isPinned: isPinned,
        onReply: onReply,
        onCopy: onCopy,
        onEdit: onEdit,
        onDelete: onDelete,
        onPin: onPin,
        onReact: onReact,
        onForward: onForward,
        onInfo: onInfo,
      ),
    );
  }
}
