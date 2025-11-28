import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final List<String> quickReactions;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    this.quickReactions = const ['❤️', '😂', '😮', '😢', '🙏', '👍'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C34),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: quickReactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              onReactionSelected(emoji);
              Navigator.of(context).pop();
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          );
        }).toList(),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required Function(String) onReactionSelected,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) =>
          Center(child: ReactionPicker(onReactionSelected: onReactionSelected)),
    );
  }
}
