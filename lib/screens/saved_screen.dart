import 'package:flutter/material.dart';
import '../services/saved_status_service.dart';
import '../models/status_model.dart';
import '../widgets/status_grid_widget.dart';
import '../widgets/status_viewer_widget.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SavedStatusService _savedStatusService = SavedStatusService();
  List<StatusModel> _imageStatuses = [];
  List<StatusModel> _videoStatuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedStatuses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedStatuses() async {
    setState(() => _isLoading = true);
    try {
      final statuses = await _savedStatusService.getSavedStatuses();
      if (mounted) {
        setState(() {
          _imageStatuses = statuses.where((s) => s.isImage).toList();
          _videoStatuses = statuses.where((s) => s.isVideo).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Error loading saved statuses: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteStatus(StatusModel status) async {
    try {
      final success = await _savedStatusService.deleteStatus(status);
      if (success) {
        _showSnackBar('Status deleted successfully!');
        // Refresh the list after deletion
        _loadSavedStatuses();
      } else {
        _showSnackBar('Failed to delete status.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error deleting status: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _viewStatus(StatusModel status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatusViewerWidget(
          status: status,
          // The download button in the viewer won't do anything here,
          // as the file is already saved.
          onDownload: () => _showSnackBar('This status is already saved.'),
        ),
      ),
    );
  }
  
  Widget _buildEmptyStateWidget(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'Images' ? Icons.image_not_supported : Icons.video_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved $type',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Your downloaded statuses will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Statuses'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              // icon: const Icon(Icons.image),
              text: 'Images (${_imageStatuses.length})',
            ),
            Tab(
              // icon: const Icon(Icons.video_library),
              text: 'Videos (${_videoStatuses.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSavedStatuses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Images Tab
                _imageStatuses.isEmpty
                    ? _buildEmptyStateWidget('Images')
                    : StatusGridWidget(
                        statuses: _imageStatuses,
                        onStatusTap: _viewStatus,
                        onDownload: (status) {}, // Not used here
                        onDelete: _deleteStatus,
                      ),
                // Videos Tab
                _videoStatuses.isEmpty
                    ? _buildEmptyStateWidget('Videos')
                    : StatusGridWidget(
                        statuses: _videoStatuses,
                        onStatusTap: _viewStatus,
                        onDownload: (status) {}, // Not used here
                        onDelete: _deleteStatus,
                      ),
              ],
            ),
    );
  }
}
