import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/conversation_provider.dart';
import 'widgets/chat_list_item.dart';
import '../chat/chat_screen.dart';
import '../contacts/contacts_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load conversations on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationProvider>().loadConversations();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<ConversationProvider>().refresh();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        conversations: context.read<ConversationProvider>().conversations,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const ContactsScreen()));
    } else if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.textPrimary),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Consumer<ConversationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadConversations(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No messages yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await provider.syncFromDevice();
                    },
                    child: const Text('Sync SMS'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: provider.conversations.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppTheme.secondaryBackground,
                indent: 82,
              ),
              itemBuilder: (context, index) {
                final chat = provider.conversations[index];
                final date = DateTime.fromMillisecondsSinceEpoch(
                  chat['date'] ?? 0,
                );
                final time =
                    "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                return OpenContainer(
                  transitionType: ContainerTransitionType.fadeThrough,
                  openBuilder: (BuildContext context, VoidCallback _) {
                    return ChatScreen(
                      userName: chat['address'] ?? 'Unknown',
                      threadId: chat['thread_id'],
                    );
                  },
                  closedElevation: 0,
                  closedColor: AppTheme.primaryBackground,
                  closedBuilder:
                      (BuildContext context, VoidCallback openContainer) {
                        return ChatListItem(
                          name: chat['address'] ?? 'Unknown',
                          message: chat['snippet'] ?? '',
                          time: time,
                          unread: (chat['unread_count'] ?? 0) > 0,
                          onTap: () {
                            provider.markAsRead(chat['thread_id']);
                            openContainer();
                          },
                        );
                      },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ContactsScreen()),
          );
        },
        child: const Icon(Icons.message),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.secondaryBackground,
        selectedItemColor: AppTheme.accentColor,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Search Dialog Widget
class _SearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> conversations;

  const _SearchDialog({required this.conversations});

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredConversations = [];

  @override
  void initState() {
    super.initState();
    _filteredConversations = widget.conversations;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = widget.conversations;
      } else {
        _filteredConversations = widget.conversations.where((conversation) {
          final address = (conversation['address'] ?? '')
              .toString()
              .toLowerCase();
          final snippet = (conversation['snippet'] ?? '')
              .toString()
              .toLowerCase();
          final searchLower = query.toLowerCase();
          return address.contains(searchLower) || snippet.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.primaryBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Header
            Row(
              children: [
                const Icon(Icons.search, color: AppTheme.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Search conversations...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary),
                      border: InputBorder.none,
                    ),
                    onChanged: _filterConversations,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppTheme.secondaryBackground),
            // Search Results
            Flexible(
              child: _filteredConversations.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No conversations found',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredConversations.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: AppTheme.secondaryBackground,
                      ),
                      itemBuilder: (context, index) {
                        final chat = _filteredConversations[index];
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          chat['date'] ?? 0,
                        );
                        final time =
                            "${date.hour}:${date.minute.toString().padLeft(2, '0')}";

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Text(
                              (chat['address'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            chat['address'] ?? 'Unknown',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            chat['snippet'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: Text(
                            time,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(); // Close search dialog
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  userName: chat['address'] ?? 'Unknown',
                                  threadId: chat['thread_id'],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
