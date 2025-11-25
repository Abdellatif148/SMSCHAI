import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _soundEnabledKey = 'notification_sound';
  static const String _vibrationEnabledKey = 'notification_vibration';
  static const String _previewEnabledKey = 'notification_preview';
  static const String _badgeEnabledKey = 'notification_badge';

  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _previewEnabled = true;
  bool _badgeEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _soundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
      _vibrationEnabled = prefs.getBool(_vibrationEnabledKey) ?? true;
      _previewEnabled = prefs.getBool(_previewEnabledKey) ?? true;
      _badgeEnabled = prefs.getBool(_badgeEnabledKey) ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
          'Notifications',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Master Switch
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'GENERAL',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            activeTrackColor: AppTheme.accentColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 8,
            ),
            title: const Text(
              'Enable Notifications',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Receive notifications for new messages',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _savePreference(_notificationsEnabledKey, value);
            },
          ),

          const Divider(color: AppTheme.secondaryBackground, height: 32),

          // Notification Settings
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'NOTIFICATION BEHAVIOR',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Sound
          SwitchListTile(
            activeTrackColor: AppTheme.accentColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            secondary: const Icon(
              Icons.volume_up,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Sound',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Play sound for new messages',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            value: _soundEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                    _savePreference(_soundEnabledKey, value);
                  }
                : null,
          ),

          // Vibration
          SwitchListTile(
            activeTrackColor: AppTheme.accentColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            secondary: const Icon(
              Icons.vibration,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Vibration',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Vibrate for new messages',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            value: _vibrationEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                    _savePreference(_vibrationEnabledKey, value);
                  }
                : null,
          ),

          const Divider(color: AppTheme.secondaryBackground, height: 32),

          // Privacy Settings
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'PRIVACY',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Message Preview
          SwitchListTile(
            activeTrackColor: AppTheme.accentColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            secondary: const Icon(
              Icons.visibility,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Message Preview',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Show message content in notifications',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            value: _previewEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _previewEnabled = value;
                    });
                    _savePreference(_previewEnabledKey, value);
                  }
                : null,
          ),

          // Badge Count
          SwitchListTile(
            activeTrackColor: AppTheme.accentColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            secondary: const Icon(
              Icons.circle_notifications,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Badge Count',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Show unread message count on app icon',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            value: _badgeEnabled && _notificationsEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _badgeEnabled = value;
                    });
                    _savePreference(_badgeEnabledKey, value);
                  }
                : null,
          ),

          const SizedBox(height: 16),

          // Info Card
          if (!_notificationsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                color: AppTheme.secondaryBackground,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.accentColor,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enable notifications to customize settings',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
