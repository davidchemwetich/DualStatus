import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/status_model.dart';
import 'package:path/path.dart' as path;


class StatusService {
  static const String _downloadFolderKey = 'download_folder';
  static const String _defaultDownloadFolder = 'WhatsApp Status Downloads';

  // Get WhatsApp status directory paths
  List<String> get _whatsappStatusPaths {
    return [
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      '/storage/emulated/0/WhatsApp/Media/.Statuses',
      '/sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      '/sdcard/WhatsApp/Media/.Statuses',
    ];
  }

  // Get all WhatsApp statuses
  Future<List<StatusModel>> getWhatsAppStatuses() async {
    final Set<String> processedFilePaths = {};
    final List<StatusModel> allStatuses = [];

    // Get regular WhatsApp statuses
    final regularStatuses = await _getStatusesFromPaths(_whatsappStatusPaths, processedFilePaths);
    allStatuses.addAll(regularStatuses);

    // Sort by creation date (newest first)
    allStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allStatuses;
  }

  // Get statuses from specific paths
  Future<List<StatusModel>> _getStatusesFromPaths(List<String> paths, Set<String> processedFilePaths) async {
    final List<StatusModel> statuses = [];

    for (String path in paths) {
      try {
        final directory = Directory(path);
        if (await directory.exists()) {
          final files = await directory.list().toList();

          for (var entity in files) {
            if (entity is File) {
              if (!processedFilePaths.contains(entity.path)) {
                final status = StatusModel.fromFile(entity);
                if (status.isImage || status.isVideo) {
                  statuses.add(status);
                  processedFilePaths.add(entity.path);
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error accessing path $path: $e');
      }
    }

    return statuses;
  }

  // Download status to device storage
  Future<bool> downloadStatus(StatusModel status) async {
    try {
      final sourceFile = File(status.filePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file does not exist');
      }

      final downloadPath = await _getDownloadPath();
      final fileName = _generateUniqueFileName(status.fileName, downloadPath);
      final destinationPath = '$downloadPath/$fileName';

      await sourceFile.copy(destinationPath);

      // Save download record
      await _saveDownloadRecord(status, destinationPath);

      return true;
    } catch (e) {
      print('Error downloading status: $e');
      return false;
    }
  }

  // Get download directory path
  Future<String> _getDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    String? customPath = prefs.getString(_downloadFolderKey);

    if (customPath != null && await Directory(customPath).exists()) {
      return customPath;
    }

    // Use default downloads directory
    final directory = await getExternalStorageDirectory();
    final downloadPath = '${directory!.path}/$_defaultDownloadFolder';

    // Create directory if it doesn't exist
    final downloadDir = Directory(downloadPath);
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadPath;
  }

  // Generate unique file name to avoid conflicts
  String _generateUniqueFileName(String originalFileName, String directory) {
    final file = File('$directory/$originalFileName');
    if (!file.existsSync()) {
      return originalFileName;
    }

    final nameWithoutExt = path.basenameWithoutExtension(originalFileName);
    final extension = path.extension(originalFileName);

    int counter = 1;
    while (true) {
      final newFileName = '${nameWithoutExt}_$counter$extension';
      final newFile = File('$directory/$newFileName');
      if (!newFile.existsSync()) {
        return newFileName;
      }
      counter++;
    }
  }

  // Save download record for history
  Future<void> _saveDownloadRecord(StatusModel status, String downloadPath) async {
    final prefs = await SharedPreferences.getInstance();
    final downloads = prefs.getStringList('downloaded_statuses') ?? [];

    final record = {
      'originalPath': status.filePath,
      'downloadPath': downloadPath,
      'downloadDate': DateTime.now().toIso8601String(),
      'fileName': status.fileName,
      'type': status.isImage ? 'image' : 'video',
    };

    downloads.add(record.toString());
    await prefs.setStringList('downloaded_statuses', downloads);
  }

  // Get downloaded statuses history
  Future<List<Map<String, dynamic>>> getDownloadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final downloads = prefs.getStringList('downloaded_statuses') ?? [];

    return downloads.map((record) {
      // Parse the string back to map (simplified parsing)
      // In a real app, you'd use proper JSON serialization
      return <String, dynamic>{};
    }).toList();
  }

  // Set custom download directory
  Future<bool> setDownloadDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_downloadFolderKey, path);
      return true;
    } catch (e) {
      print('Error setting download directory: $e');
      return false;
    }
  }

  // Get current download directory
  Future<String> getCurrentDownloadDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_downloadFolderKey) ?? await _getDownloadPath();
  }

  // Clear download history
  Future<void> clearDownloadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('downloaded_statuses');
  }

  // Check if file is already downloaded
  Future<bool> isStatusDownloaded(StatusModel status) async {
    final downloadPath = await _getDownloadPath();
    final file = File('$downloadPath/${status.fileName}');
    return await file.exists();
  }

  // Get storage info
  Future<Map<String, int>> getStorageInfo() async {
    try {
      final directory = await getExternalStorageDirectory();
      final stat = await directory!.stat();

      return {
        'totalSpace': 0, // Would need platform-specific code
        'freeSpace': 0,  // Would need platform-specific code
        'usedSpace': 0,
      };
    } catch (e) {
      print('Error getting storage info: $e');
      return {'totalSpace': 0, 'freeSpace': 0, 'usedSpace': 0};
    }
  }
}
