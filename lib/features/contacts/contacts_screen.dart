import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../chat/chat_screen.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy contacts
    final List<String> contacts = [
      'Alice Smith',
      'Bob Johnson',
      'Charlie Brown',
      'David Wilson',
      'Eva Davis',
      'Frank Miller',
      'Grace Lee',
      'Henry White',
    ];

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.accentColor),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_add, color: AppTheme.accentColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Invite Banner
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.secondaryBackground,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: AppTheme.accentColor),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Friends',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Invite friends to SMSChat',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          // Contacts List
          Expanded(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondaryBackground,
                    child: Text(
                      contact[0],
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                  ),
                  title: Text(
                    contact,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(userName: contact),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
