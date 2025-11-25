import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../../services/sms_service.dart';
import '../auth/login_screen.dart';
import 'appearance_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSyncEnabled = false;
  final SupabaseService _supabaseService = SupabaseService();
  static const String _syncEnabledKey = 'sync_enabled';

  @override
  void initState() {
    super.initState();
    _loadSyncPreference();
  }

  Future<void> _loadSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreference = prefs.getBool(_syncEnabledKey) ?? false;
    final isLoggedIn = _supabaseService.currentUser != null;

    setState(() {
      // Sync is enabled only if both the preference is saved AND user is logged in
      _isSyncEnabled = savedPreference && isLoggedIn;
    });

    // If preference says enabled but user is not logged in, update the preference
    if (savedPreference && !isLoggedIn) {
      await prefs.setBool(_syncEnabledKey, false);
    }
  }

  Future<void> _saveSyncPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncEnabledKey, value);
  }

  Future<void> _toggleSync(bool value) async {
    if (value) {
      // Enable Sync -> Login
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      if (success == true) {
        setState(() {
          _isSyncEnabled = true;
        });
        await _saveSyncPreference(true);
        // Trigger restore and start sync
        await SmsService().restoreFromCloud();
        await SmsService().startSync();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync enabled and messages restoring...'),
            ),
          );
        }
      }
    } else {
      // Disable Sync -> Logout
      await SmsService().stopSync();
      await _supabaseService.signOut();
      setState(() {
        _isSyncEnabled = false;
      });
      await _saveSyncPreference(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.secondaryBackground,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isSyncEnabled
                          ? (_supabaseService.currentUser?.email ?? 'Logged In')
                          : 'Local Account',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppTheme.secondaryBackground),

          // Sync Switch
          SwitchListTile(
            activeTrackColor: AppTheme.accentColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            title: const Text(
              'Backup & Sync',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Sync messages with cloud',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            value: _isSyncEnabled,
            onChanged: _toggleSync,
          ),

          if (_isSyncEnabled) ...[
            const Divider(color: AppTheme.secondaryBackground),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: const Icon(Icons.lock, color: AppTheme.textSecondary),
              title: const Text(
                'Encryption',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: const Text(
                'End-to-end encryption is active',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Encryption Key Management coming soon'),
                  ),
                );
              },
            ),
          ],

          const Divider(color: AppTheme.secondaryBackground),

          // Other Settings
          _buildSettingItem(Icons.palette_outlined, 'Appearance'),
          _buildSettingItem(Icons.notifications_outlined, 'Notifications'),
          _buildSettingItem(Icons.lock_outline, 'Privacy'),
          _buildSettingItem(Icons.help_outline, 'About & Help'),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: () {
        // Navigate to the appropriate settings screen based on title
        Widget? screen;
        switch (title) {
          case 'Appearance':
            screen = const AppearanceSettingsScreen();
            break;
          case 'Notifications':
            screen = const NotificationSettingsScreen();
            break;
          case 'Privacy':
            screen = const PrivacySettingsScreen();
            break;
          case 'About & Help':
            screen = const AboutScreen();
            break;
        }

        if (screen != null) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (context) => screen!));
        }
      },
    );
  }
}
