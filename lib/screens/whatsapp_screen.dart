import 'package:flutter/material.dart';
import 'package:status/widgets/whatsapp_link_generator.dart';
import '../services/status_service.dart';
import '../models/status_model.dart';
import '../widgets/status_grid_widget.dart';
import '../widgets/status_viewer_widget.dart';
import '../utils/permissions_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

class WhatsAppScreen extends StatefulWidget {
  const WhatsAppScreen({super.key});

  @override
  State<WhatsAppScreen> createState() => _WhatsAppScreenState();
}

class _WhatsAppScreenState extends State<WhatsAppScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StatusService _statusService = StatusService();
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

    bool hasPermission = await PermissionsHelper.requestStoragePermission();

    if (hasPermission) {
      setState(() => _hasPermission = true);
      await _loadStatuses();
    } else {
      setState(() => _hasPermission = false);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadStatuses() async {
    try {
      final statuses = await _statusService.getWhatsAppStatuses();

      setState(() {
        _imageStatuses = statuses.where((status) => status.isImage).toList();
        _videoStatuses = statuses.where((status) => status.isVideo).toList();
      });
    } catch (e) {
      _showErrorSnackBar('Error loading statuses: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _downloadStatus(StatusModel status) async {
    try {
      final success = await _statusService.downloadStatus(status);
      if (success) {
        _showSuccessSnackBar('Status downloaded successfully!');
      } else {
        _showErrorSnackBar('Failed to download status');
      }
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

  Widget _buildPermissionDeniedWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Storage Permission Required',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please grant storage permission to access WhatsApp statuses',
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
    );
  }

  Widget _buildEmptyStateWidget(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'Images' ? Icons.image : Icons.video_library,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No $type Found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure WhatsApp is installed and you have viewed some statuses',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Text(
          'Status Saver',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: _hasPermission
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'Images (${_imageStatuses.length})'),
                  Tab(text: 'Videos (${_videoStatuses.length})'),
                ],
              )
            : null,
        actions: _hasPermission
            ? [
                IconButton(
                  icon: const Icon(Icons.link),
                  tooltip: 'WhatsApp Link Generator',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WhatsAppLinkGenerator(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.chat),
                  tooltip: 'Open WhatsApp', // Added a helpful tooltip
                  onPressed: () async {
                    // This is the new, reliable code to launch WhatsApp
                    if (defaultTargetPlatform == TargetPlatform.android) {
                      const intent = AndroidIntent(
                        action: 'action_main',
                        category: 'category_launcher',
                        package:
                            'com.whatsapp', // The official WhatsApp package
                      );
                      try {
                        await intent.launch();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("WhatsApp not found")),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    Share.share(
                      'Check out this awesome WhatsApp Status Saver app!',
                      subject: 'WhatsApp Status Saver',
                    );
                  },
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
          ? _buildPermissionDeniedWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                // Your existing TabBarView children
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
