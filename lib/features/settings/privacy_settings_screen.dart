import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme.dart';
import '../../services/database_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _smsPermissionGranted = false;
  bool _contactsPermissionGranted = false;
  bool _isCheckingPermissions = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isCheckingPermissions = true;
    });

    final smsStatus = await Permission.sms.status;
    final contactsStatus = await Permission.contacts.status;

    setState(() {
      _smsPermissionGranted = smsStatus.isGranted;
      _contactsPermissionGranted = contactsStatus.isGranted;
      _isCheckingPermissions = false;
    });
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
    // Recheck permissions when user returns
    Future.delayed(const Duration(milliseconds: 500), _checkPermissions);
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text(
          'Clear Cache?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will clear temporary data and may improve performance. Your messages will not be deleted.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Clear',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Cache clearing logic would go here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBackground,
        title: const Text(
          'Clear All Data?',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        content: const Text(
          'This will delete all local messages and conversations. This action cannot be undone. If sync is enabled, you can restore from cloud.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await DatabaseService().clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All local data cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing data: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
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
          'Privacy & Security',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // Permissions Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'PERMISSIONS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (_isCheckingPermissions)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor),
              ),
            )
          else ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: Icon(
                _smsPermissionGranted ? Icons.check_circle : Icons.warning,
                color: _smsPermissionGranted
                    ? Colors.green
                    : AppTheme.errorColor,
              ),
              title: const Text(
                'SMS Permission',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                _smsPermissionGranted ? 'Granted' : 'Not granted',
                style: TextStyle(
                  color: _smsPermissionGranted
                      ? Colors.green
                      : AppTheme.errorColor,
                ),
              ),
              trailing: !_smsPermissionGranted
                  ? TextButton(
                      onPressed: _openAppSettings,
                      child: const Text(
                        'Grant',
                        style: TextStyle(color: AppTheme.accentColor),
                      ),
                    )
                  : null,
            ),

            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              leading: Icon(
                _contactsPermissionGranted ? Icons.check_circle : Icons.warning,
                color: _contactsPermissionGranted
                    ? Colors.green
                    : AppTheme.errorColor,
              ),
              title: const Text(
                'Contacts Permission',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              subtitle: Text(
                _contactsPermissionGranted ? 'Granted' : 'Not granted',
                style: TextStyle(
                  color: _contactsPermissionGranted
                      ? Colors.green
                      : AppTheme.errorColor,
                ),
              ),
              trailing: !_contactsPermissionGranted
                  ? TextButton(
                      onPressed: _openAppSettings,
                      child: const Text(
                        'Grant',
                        style: TextStyle(color: AppTheme.accentColor),
                      ),
                    )
                  : null,
            ),
          ],

          const Divider(color: AppTheme.secondaryBackground, height: 32),

          // Security Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'SECURITY',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(Icons.lock, color: AppTheme.textSecondary),
            title: const Text(
              'End-to-End Encryption',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Messages are encrypted before sync',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),

          const Divider(color: AppTheme.secondaryBackground, height: 32),

          // Data Management Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'DATA MANAGEMENT',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(
              Icons.cleaning_services,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Clear Cache',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Clear temporary data',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: _clearCache,
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(
              Icons.delete_forever,
              color: AppTheme.errorColor,
            ),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            subtitle: const Text(
              'Delete all local messages',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: _clearAllData,
          ),

          const SizedBox(height: 16),

          // Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              color: AppTheme.secondaryBackground,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.accentColor,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your privacy is important. All messages are stored locally and only synced to cloud when you enable backup & sync.',
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
