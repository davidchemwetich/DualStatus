import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/status_model.dart';
import 'package:path/path.dart' as path;

class StatusService {
  static const String _downloadFolderKey = 'download_folder';
  static const String _defaultDownloadFolder = 'WhatsApp Status Downloads';
  
  // Cache for better performance
  List<StatusModel>? _cachedStatuses;
  DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Get WhatsApp status directory paths
  List<String> get _whatsappStatusPaths {
    return [
      '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      '/storage/emulated/0/WhatsApp/Media/.Statuses',
      '/sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      '/sdcard/WhatsApp/Media/.Statuses',
    ];
  }

  // Get all WhatsApp statuses with enhanced deduplication
  Future<List<StatusModel>> getWhatsAppStatuses() async {
    // Check cache first
    if (_cachedStatuses != null && 
        _lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration) {
      return _cachedStatuses!;
    }

    final statuses = await _loadStatusesFromDisk();
    
    // Cache the results
    _cachedStatuses = statuses;
    _lastCacheTime = DateTime.now();
    
    return statuses;
  }

  // Load statuses from disk with enhanced deduplication
  Future<List<StatusModel>> _loadStatusesFromDisk() async {
    final Set<String> processedFilePaths = {};
    final Set<String> processedFileNames = {};
    final Map<String, StatusModel> statusMap = {};
    
    for (String dirPath in _whatsappStatusPaths) {
      try {
        final directory = Directory(dirPath);
        if (await directory.exists()) {
          final files = await directory.list().toList();

          for (var entity in files) {
            if (entity is File) {
              final filePath = entity.path;
              final fileName = path.basename(filePath);
              
              // Skip if we've already processed this file path or filename
              if (processedFilePaths.contains(filePath) || 
                  processedFileNames.contains(fileName)) {
                continue;
              }
              
              try {
                final status = StatusModel.fromFile(entity);
                if (status.isImage || status.isVideo) {
                  // Create unique key for deduplication (filename + size + extension)
                  final uniqueKey = '${status.fileName}_${status.fileSize}_${status.fileExtension}';
                  
                  // Only add if we haven't seen this exact file before
                  if (!statusMap.containsKey(uniqueKey)) {
                    statusMap[uniqueKey] = status;
                    processedFilePaths.add(filePath);
                    processedFileNames.add(fileName);
                  }
                }
              } catch (e) {
                print('Error processing file $filePath: $e');
                continue;
              }
            }
          }
        }
      } catch (e) {
        print('Error accessing path $dirPath: $e');
      }
    }

    // Convert map values to list and sort by creation date (newest first)
    final List<StatusModel> allStatuses = statusMap.values.toList();
    allStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return allStatuses;
  }

  // Clear cache to force refresh
  void clearCache() {
    _cachedStatuses = null;
    _lastCacheTime = null;
  }

  // Refresh statuses (clear cache and reload)
  Future<List<StatusModel>> refreshStatuses() async {
    clearCache();
    return await getWhatsAppStatuses();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloads = prefs.getStringList('downloaded_statuses') ?? [];

      final record = {
        'originalPath': status.filePath,
        'downloadPath': downloadPath,
        'downloadDate': DateTime.now().toIso8601String(),
        'fileName': status.fileName,
        'type': status.isImage ? 'image' : 'video',
        'fileSize': status.fileSize.toString(),
      };

      // Convert to JSON string for proper storage
      downloads.add(_mapToString(record));
      
      // Keep only last 100 downloads to prevent excessive storage
      if (downloads.length > 100) {
        downloads.removeRange(0, downloads.length - 100);
      }
      
      await prefs.setStringList('downloaded_statuses', downloads);
    } catch (e) {
      print('Error saving download record: $e');
    }
  }

  // Helper method to convert map to string
  String _mapToString(Map<String, String> map) {
    return map.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  // Helper method to convert string back to map
  Map<String, String> _stringToMap(String str) {
    final Map<String, String> map = {};
    final pairs = str.split('|');
    for (final pair in pairs) {
      final keyValue = pair.split(':');
      if (keyValue.length == 2) {
        map[keyValue[0]] = keyValue[1];
      }
    }
    return map;
  }

  // Get downloaded statuses history
  Future<List<Map<String, String>>> getDownloadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloads = prefs.getStringList('downloaded_statuses') ?? [];

      return downloads.map((record) => _stringToMap(record)).toList();
    } catch (e) {
      print('Error getting download history: $e');
      return [];
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('downloaded_statuses');
    } catch (e) {
      print('Error clearing download history: $e');
    }
  }

  // Check if file is already downloaded
  Future<bool> isStatusDownloaded(StatusModel status) async {
    try {
      final downloadPath = await _getDownloadPath();
      final file = File('$downloadPath/${status.fileName}');
      return await file.exists();
    } catch (e) {
      print('Error checking download status: $e');
      return false;
    }
  }

  // Get downloaded statuses (files that exist in download directory)
  Future<List<StatusModel>> getDownloadedStatuses() async {
    try {
      final downloadPath = await _getDownloadPath();
      final downloadDir = Directory(downloadPath);
      
      if (!await downloadDir.exists()) {
        return [];
      }

      final files = await downloadDir.list().toList();
      final List<StatusModel> downloadedStatuses = [];

      for (var entity in files) {
        if (entity is File) {
          try {
            final status = StatusModel.fromFile(entity);
            if (status.isImage || status.isVideo) {
              downloadedStatuses.add(status);
            }
          } catch (e) {
            print('Error processing downloaded file ${entity.path}: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      downloadedStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return downloadedStatuses;
    } catch (e) {
      print('Error getting downloaded statuses: $e');
      return [];
    }
  }

  // Delete downloaded status
  Future<bool> deleteDownloadedStatus(StatusModel status) async {
    try {
      final file = File(status.filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting downloaded status: $e');
      return false;
    }
  }

  // Get storage info
  Future<Map<String, int>> getStorageInfo() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final stat = await directory.stat();
        
        // Get download folder size
        final downloadPath = await _getDownloadPath();
        final downloadDir = Directory(downloadPath);
        int downloadFolderSize = 0;
        
        if (await downloadDir.exists()) {
          final files = await downloadDir.list(recursive: true).toList();
          for (var entity in files) {
            if (entity is File) {
              try {
                final fileStat = await entity.stat();
                downloadFolderSize += fileStat.size;
              } catch (e) {
                print('Error getting file size: $e');
              }
            }
          }
        }

        return {
          'totalSpace': 0, // Would need platform-specific code
          'freeSpace': 0,  // Would need platform-specific code
          'downloadFolderSize': downloadFolderSize,
        };
      }
      
      return {'totalSpace': 0, 'freeSpace': 0, 'downloadFolderSize': 0};
    } catch (e) {
      print('Error getting storage info: $e');
      return {'totalSpace': 0, 'freeSpace': 0, 'downloadFolderSize': 0};
    }
  }

  // Get status count by type
  Future<Map<String, int>> getStatusCounts() async {
    try {
      final statuses = await getWhatsAppStatuses();
      final imageCount = statuses.where((s) => s.isImage).length;
      final videoCount = statuses.where((s) => s.isVideo).length;
      
      return {
        'images': imageCount,
        'videos': videoCount,
        'total': statuses.length,
      };
    } catch (e) {
      print('Error getting status counts: $e');
      return {'images': 0, 'videos': 0, 'total': 0};
    }
  }

  // Cleanup old cache and temporary files
  Future<void> cleanup() async {
    try {
      clearCache();
      
      // Clean up any temporary files if needed
      final tempDir = await getTemporaryDirectory();
      final tempFiles = await tempDir.list().toList();
      
      for (var entity in tempFiles) {
        if (entity is File && entity.path.contains('whatsapp_status_temp')) {
          try {
            await entity.delete();
          } catch (e) {
            print('Error deleting temp file: $e');
          }
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}