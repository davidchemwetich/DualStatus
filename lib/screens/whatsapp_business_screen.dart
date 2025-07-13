import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:status/widgets/whatsapp_link_generator.dart';
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
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Initialize service and check permissions
  Future<void> _initializeService() async {
    await _statusService.initialize();
    await _checkPermissionsAndLoadStatuses();
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

  Future<void> _loadStatuses({bool forceRefresh = false}) async {
    if (_isLoading || _isRefreshing) return;
    
    setState(() => _isRefreshing = true);

    try {
      final statuses = await _statusService.getWhatsAppBusinessStatuses(
        forceRefresh: forceRefresh
      );

      if (mounted) {
        setState(() {
          _imageStatuses = statuses.where((status) => status.isImage).toList();
          _videoStatuses = statuses.where((status) => status.isVideo).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading statuses: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // Force refresh statuses
  Future<void> _refreshStatuses() async {
    await _loadStatuses(forceRefresh: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) =>
      _showSnackBar(message, isError: true);
  void _showSuccessSnackBar(String message) => _showSnackBar(message);

  Future<void> _downloadStatus(StatusModel status) async {
    try {
      final success = await _statusService.downloadStatus(status);
      _showSnackBar(
        success
            ? 'Status downloaded successfully!'
            : 'Failed to download status',
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
    if (Theme.of(context).platform == TargetPlatform.android) {
      const AndroidIntent intent = AndroidIntent(
        action: 'action_main',
        category: 'category_launcher',
        package: 'com.whatsapp.w4b',
      );

      try {
        await intent.launch();
      } catch (e) {
        _showErrorSnackBar("WhatsApp Business not found. Please install it.");
      }
    } else {
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

  // Clear cache and refresh
  Future<void> _clearCacheAndRefresh() async {
    await _statusService.clearCache();
    await _refreshStatuses();
    _showSuccessSnackBar('Cache cleared and statuses refreshed');
  }

  // Show cache info dialog
  void _showCacheInfo() {
    final cacheInfo = _statusService.getCacheInfo();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Has cached data: ${cacheInfo['hasCachedData']}'),
            Text('Cached items: ${cacheInfo['cachedItemCount']}'),
            Text('Cache time: ${cacheInfo['cacheTime'] ?? 'None'}'),
            Text('Is cache valid: ${cacheInfo['isCacheValid']}'),
            Text('Is loading: ${cacheInfo['isLoading']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCacheAndRefresh();
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _refreshStatuses,
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _openWhatsAppBusiness,
                  child: const Text('Open WhatsApp'),
                ),
              ],
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
                  icon: const Icon(Icons.business),
                  tooltip: 'Open WhatsApp Business',
                  onPressed: _openWhatsAppBusiness,
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: ListTile(
                        leading: Icon(Icons.refresh),
                        title: Text('Refresh Statuses'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cache_info',
                      child: ListTile(
                        leading: Icon(Icons.info),
                        title: Text('Cache Info'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share App'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'refresh':
                        _refreshStatuses();
                        break;
                      case 'cache_info':
                        _showCacheInfo();
                        break;
                      case 'share':
                        _shareApp();
                        break;
                    }
                  },
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF075E54)),
              ),
            )
          else if (!_hasPermission)
            _buildPermissionDeniedWidget()
          else
            TabBarView(
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
          // Loading overlay for refresh
          if (_isRefreshing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Refreshing statuses...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}