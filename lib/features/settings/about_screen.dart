import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'SMSChat',
      applicationVersion: _version,
      applicationIcon: const Icon(
        Icons.message,
        size: 48,
        color: AppTheme.accentColor,
      ),
    );
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
          'About & Help',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          // App Info Section
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.message,
                    size: 40,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SMSChat',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $_version',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                if (_buildNumber.isNotEmpty)
                  Text(
                    'Build $_buildNumber',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(color: AppTheme.secondaryBackground),

          // App Description
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'A secure, privacy-focused SMS messaging app with optional cloud backup and end-to-end encryption.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ),

          const Divider(color: AppTheme.secondaryBackground),

          // Links Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'INFORMATION',
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
            leading: const Icon(Icons.article, color: AppTheme.textSecondary),
            title: const Text(
              'Licenses',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'View open source licenses',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: _showLicenses,
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(
              Icons.privacy_tip,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon')),
              );
            },
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(
              Icons.description,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Terms of Service',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of service coming soon')),
              );
            },
          ),

          const Divider(color: AppTheme.secondaryBackground, height: 32),

          // Support Section
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Text(
              'SUPPORT',
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
            leading: const Icon(Icons.help, color: AppTheme.textSecondary),
            title: const Text(
              'Help Center',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Get help and support',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon')),
              );
            },
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(
              Icons.bug_report,
              color: AppTheme.textSecondary,
            ),
            title: const Text(
              'Report a Bug',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Help us improve the app',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug reporting coming soon')),
              );
            },
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 4,
            ),
            leading: const Icon(Icons.email, color: AppTheme.textSecondary),
            title: const Text(
              'Contact Us',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            subtitle: const Text(
              'Send us feedback',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact form coming soon')),
              );
            },
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '© 2025 SMSChat\nMade with ❤️ for privacy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
