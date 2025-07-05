import 'package:flutter/material.dart';
import 'dart:io';
import '../models/status_model.dart';

class StatusGridWidget extends StatelessWidget {
  final List<StatusModel> statuses;
  final Function(StatusModel) onStatusTap;
  final Function(StatusModel) onDownload;
  final Function(StatusModel)? onDelete; // Optional: for deleting

  const StatusGridWidget({
    Key? key,
    required this.statuses,
    required this.onStatusTap,
    required this.onDownload,
    this.onDelete, // Make onDelete optional
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.8,
      ),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        return StatusGridItem(
          status: status,
          onTap: () => onStatusTap(status),
          onDownload: () => onDownload(status),
          onDelete: onDelete != null ? () => onDelete!(status) : null,
        );
      },
    );
  }
}

class StatusGridItem extends StatelessWidget {
  final StatusModel status;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback? onDelete; // Optional delete callback

  const StatusGridItem({
    Key? key,
    required this.status,
    required this.onTap,
    required this.onDownload,
    this.onDelete,
  }) : super(key: key);

  Widget _buildImagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(status.filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.broken_image,
                color: Colors.grey,
                size: 40,
              ),
            );
          },
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.image,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.black,
          child: const Icon(
            Icons.play_circle_outline,
            color: Colors.white,
            size: 50,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.videocam,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white,
            size: 40,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  color: Colors.grey[200],
                  child: status.isImage
                      ? _buildImagePreview()
                      : _buildVideoPreview(),
                ),
              ),
            ),
            // SOLUTION 1: Reduce padding and use SingleChildScrollView
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduced padding
                child: SingleChildScrollView( // Allow scrolling if content overflows
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Use minimum space needed
                    children: [
                      Row(
                        children: [
                          Icon(
                            status.isImage ? Icons.image : Icons.video_library,
                            size: 14, // Slightly smaller icon
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              status.fileName,
                              style: const TextStyle(
                                fontSize: 11, // Slightly smaller font
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2), // Small spacing instead of spaceBetween
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              status.formattedDate,
                              style: TextStyle(
                                fontSize: 9, // Smaller font for date
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status.fileSizeFormatted,
                            style: TextStyle(
                              fontSize: 9, // Smaller font for size
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Action buttons
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF075E54),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Download Button (or a placeholder if not needed)
                  if (onDelete == null)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDownload,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8), // Reduced padding
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download, color: Colors.white, size: 14), // Smaller icon
                                SizedBox(width: 4),
                                Text('Download', style: TextStyle(color: Colors.white, fontSize: 11)), // Smaller text
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Delete Button (shown only if onDelete is provided)
                  if (onDelete != null)
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8), // Reduced padding
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete, color: Colors.white, size: 14), // Smaller icon
                                SizedBox(width: 4),
                                Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11)), // Smaller text
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}