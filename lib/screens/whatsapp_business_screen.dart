import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/whatsapp_business_status_service.dart';
import '../models/status_model.dart';
import '../widgets/status_grid_widget.dart';
import '../widgets/status_viewer_widget.dart';
import '../utils/permissions_helper.dart';

class WhatsAppBusinessScreen extends StatefulWidget {
  const WhatsAppBusinessScreen({super.key});

  @override
  State<WhatsAppBusinessScreen> createState() => _WhatsAppBusinessScreenState();
}

class _WhatsAppBusinessScreenState extends State<WhatsAppBusinessScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final WhatsAppBusinessStatusService _statusService = WhatsAppBusinessStatusService();
  List<StatusModel> _imageStatuses = [];
  List<StatusModel> _videoStatuses = [];
  bool _isLoading = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkPermissionsAndLoadStatuses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndLoadStatuses() async {
    setState(() => _isLoading = true);
    
    final hasPermission = await PermissionsHelper.requestStoragePermission();
    
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
    
    if (hasPermission) {
      await _loadStatuses();
    }
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _statusService.getWhatsAppBusinessStatuses();
      
      if (mounted) {
        setState(() {
          _imageStatuses = statuses.where((status) => status.isImage).toList();
          _videoStatuses = statuses.where((status) => status.isVideo).toList();
        });
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Error loading statuses: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) => _showSnackBar(message, isError: true);
  void _showSuccessSnackBar(String message) => _showSnackBar(message);

  Future<void> _downloadStatus(StatusModel status) async {
    try {
      final success = await _statusService.downloadStatus(status);
      _showSnackBar(
        success ? 'Status downloaded successfully!' : 'Failed to download status',
        isError: !success,
      );
    } catch (e) {
      _showErrorSnackBar('Error downloading status: $e');
    }
  }

  void _viewStatus(StatusModel status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerWidget(
          status: status,
          onDownload: () => _downloadStatus(status),
        ),
      ),
    );
  }

Future<void> _openWhatsAppBusiness() async {
  // Check if the platform is Android
  if (Theme.of(context).platform == TargetPlatform.android) {
    // This is the Android Intent that mimics tapping the app icon
    const AndroidIntent intent = AndroidIntent(
      action: 'action_main', // Corresponds to Intent.ACTION_MAIN
      category: 'category_launcher', // Corresponds to Intent.CATEGORY_LAUNCHER
      package: 'com.whatsapp.w4b', // The package name for WhatsApp Business
    );

    try {
      // Launch the intent
      await intent.launch();
    } catch (e) {
      // If the app is not installed, an exception will be thrown
      _showErrorSnackBar("WhatsApp Business not found. Please install it.");
    }
  } else {
    // Handle other platforms if necessary
    _showErrorSnackBar("This feature is only available on Android.");
  }
}

  Future<void> _shareApp() async {
    try {
      await Share.share(
        'Check out this awesome WhatsApp Status Saver app! Save and download WhatsApp Business statuses easily.',
        subject: 'WhatsApp Status Saver',
      );
    } catch (e) {
      _showErrorSnackBar('Could not share: $e');
    }
  }

  Widget _buildPermissionDeniedWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Storage Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please grant storage permission to access WhatsApp Business statuses.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissionsAndLoadStatuses,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget(String type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'Images' ? Icons.image : Icons.video_library,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure WhatsApp Business is installed and you have viewed some statuses.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadStatuses,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Status Saver',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: _hasPermission
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Images (${_imageStatuses.length})'),
                  Tab(text: 'Videos (${_videoStatuses.length})'),
                ],
              )
            : null,
        actions: _hasPermission
            ? [
                IconButton(
                  icon: const Icon(Icons.business),
                  tooltip: 'Open WhatsApp Business',
                  onPressed: _openWhatsAppBusiness,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share App',
                  onPressed: _shareApp,
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF075E54)),
              ),
            )
          : !_hasPermission
              ? _buildPermissionDeniedWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _imageStatuses.isEmpty
                        ? _buildEmptyStateWidget('Images')
                        : StatusGridWidget(
                            statuses: _imageStatuses,
                            onStatusTap: _viewStatus,
                            onDownload: _downloadStatus,
                          ),
                    _videoStatuses.isEmpty
                        ? _buildEmptyStateWidget('Videos')
                        : StatusGridWidget(
                            statuses: _videoStatuses,
                            onStatusTap: _viewStatus,
                            onDownload: _downloadStatus,
                          ),
                  ],
                ),
    );
  }
}