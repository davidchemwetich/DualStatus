import 'dart:io';
import 'package:path/path.dart' as path;

class StatusModel {
  final String fileName;
  final String filePath;
  final DateTime createdAt;
  final int fileSize;
  final String fileExtension;

  StatusModel({
    required this.fileName,
    required this.filePath,
    required this.createdAt,
    required this.fileSize,
    required this.fileExtension,
  });

  // Check if the status is an image
  bool get isImage {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    return imageExtensions.contains(fileExtension.toLowerCase());
  }

  // Check if the status is a video
  bool get isVideo {
    final videoExtensions = ['.mp4', '.avi', '.mov', '.mkv', '.webm', '.3gp'];
    return videoExtensions.contains(fileExtension.toLowerCase());
  }

  // Get file size in readable format
  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  // Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Create StatusModel from File
  factory StatusModel.fromFile(File file) {
    final stat = file.statSync();
    return StatusModel(
      fileName: path.basename(file.path),
      filePath: file.path,
      createdAt: stat.modified,
      fileSize: stat.size,
      fileExtension: path.extension(file.path),
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'fileSize': fileSize,
      'fileExtension': fileExtension,
    };
  }

  // Create from JSON
  factory StatusModel.fromJson(Map<String, dynamic> json) {
    return StatusModel(
      fileName: json['fileName'],
      filePath: json['filePath'],
      createdAt: DateTime.parse(json['createdAt']),
      fileSize: json['fileSize'],
      fileExtension: json['fileExtension'],
    );
  }

  @override
  String toString() {
    return 'StatusModel(fileName: $fileName, isImage: $isImage, isVideo: $isVideo, size: $fileSizeFormatted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatusModel && other.filePath == filePath;
  }

  @override
  int get hashCode => filePath.hashCode;
}