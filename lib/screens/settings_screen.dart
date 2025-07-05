import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _fallbackVersion = '1.0.0';
  static const Color _primaryColor = Color(0xFF075E54);
  
  // App configuration - Replace with your actual URLs
  static const String _appPackageId = 'ink.netops.status';
  static const String _privacyPolicyUrl = 'https://netops.ink';
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=$_appPackageId';
  static const String _appStoreUrl = 'https://apps.apple.com/app/id123456789'; // Add your App Store ID
  
  String _appVersion = _fallbackVersion;
  String _appName = 'Status Saver';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAppInfo();
  }

  Future<void> _initializeAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _appName = packageInfo.appName.isNotEmpty ? packageInfo.appName : _appName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading app info: $e');
    }
  }

  Future<void> _launchURL(String url, {String? fallbackUrl}) async {
    try {
      final Uri uri = Uri.parse(url);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched && fallbackUrl != null) {
        final Uri fallbackUri = Uri.parse(fallbackUrl);
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Unable to open link. Please try again later.');
      }
      debugPrint('Error launching URL: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _shareApp() async {
    try {
      final String shareText = '''
🌟 Check out $_appName!

Save and download WhatsApp statuses easily with this amazing app.

Download now:
📱 Android: $_playStoreUrl
🍎 iOS: $_appStoreUrl

#WhatsAppStatus #StatusSaver #$_appName
      '''.trim();
      
      await Share.share(shareText, subject: 'Check out $_appName');
    } catch (e) {
      _showSnackBar('Unable to share app. Please try again.');
      debugPrint('Error sharing app: $e');
    }
  }

  Future<void> _rateApp() async {
    // Detect platform and use appropriate store URL
    const String androidUrl = _playStoreUrl;
    const String iosUrl = _appStoreUrl;
    
    // Try Android first, then iOS as fallback
    await _launchURL(androidUrl, fallbackUrl: iosUrl);
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: _appName,
      applicationVersion: _appVersion,
      applicationIcon: const Icon(
        Icons.download_rounded,
        size: 48,
        color: _primaryColor,
      ),
      applicationLegalese: '© 2025 ByNetOps. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        Text(
          'Save and download WhatsApp statuses with ease. '
          'Never miss your favorite moments!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Features:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text('• Download images and videos\n'
                   '• Easy-to-use interface\n'
                   '• No root required\n'
                   '• Fast and secure'),
      ],
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon!'),
        content: Text('We\'re working hard to bring you $feature in the next update. Stay tuned!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: _primaryColor,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryColor))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _buildSectionHeader('General'),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  subtitle: 'English (US)',
                  onTap: () => _showComingSoonDialog('Language selection'),
                ),
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: 'System Default',
                  onTap: () => _showComingSoonDialog('Theme customization'),
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your preferences',
                  onTap: () => _showComingSoonDialog('Notification settings'),
                ),
                
                const Divider(height: 32),
                
                _buildSectionHeader('Storage & Privacy'),
                _SettingsTile(
                  icon: Icons.folder_outlined,
                  title: 'Download Location',
                  subtitle: 'Internal Storage/StatusSaver',
                  onTap: () => _showComingSoonDialog('Storage management'),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => _launchURL(_privacyPolicyUrl),
                ),
                
                const Divider(height: 32),
                
                _buildSectionHeader('Support & Feedback'),
                _SettingsTile(
                  icon: Icons.star_border_rounded,
                  title: 'Rate Us',
                  subtitle: 'Love the app? Rate us on the store!',
                  onTap: _rateApp,
                ),
                _SettingsTile(
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  subtitle: 'Tell your friends about $_appName',
                  onTap: _shareApp,
                ),
                _SettingsTile(
                  icon: Icons.bug_report_outlined,
                  title: 'Report Bug',
                  subtitle: 'Help us improve the app',
                  onTap: () => _showComingSoonDialog('Bug reporting'),
                ),
                
                const Divider(height: 32),
                
                _buildSectionHeader('About'),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'About $_appName',
                  subtitle: 'Version $_appVersion',
                  onTap: _showAboutDialog,
                ),
                
                const SizedBox(height: 32),
                
                // App branding footer
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.download_rounded,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Made with ❤️ by ByNetOps',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Version $_appVersion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF075E54).withOpacity(0.1),
        highlightColor: const Color(0xFF075E54).withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF075E54).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF075E54),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}