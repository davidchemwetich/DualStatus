import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/status_model.dart';
import 'package:path/path.dart' as path;

class WhatsAppBusinessStatusService {
  static const String _downloadFolderKey = 'download_folder';
  static const String _defaultDownloadFolder = 'WhatsApp Status Downloads';
  static const String _cacheKey = 'cached_statuses';
  static const String _cacheTimeKey = 'cache_time';
  static const int _cacheValidityMinutes = 5;
  
  // Singleton pattern to prevent multiple instances
  static final WhatsAppBusinessStatusService _instance = WhatsAppBusinessStatusService._internal();
  factory WhatsAppBusinessStatusService() => _instance;
  WhatsAppBusinessStatusService._internal();
  
  // Cache for statuses
  List<StatusModel>? _cachedStatuses;
  DateTime? _cacheTime;
  
  // Lock to prevent concurrent access
  bool _isLoading = false;

  // Get WhatsApp Business status directory paths
  List<String> get _whatsappBusinessStatusPaths {
    return [
      '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
      '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
      '/sdcard/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
      '/sdcard/WhatsApp Business/Media/.Statuses',
    ];
  }

  // Get all WhatsApp Business statuses with caching and deduplication
  Future<List<StatusModel>> getWhatsAppBusinessStatuses({bool forceRefresh = false}) async {
    // Check if we have valid cached data
    if (!forceRefresh && _isCacheValid()) {
      return _cachedStatuses!;
    }
    
    // Prevent concurrent loading
    if (_isLoading) {
      // Wait for current loading to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _cachedStatuses ?? [];
    }
    
    _isLoading = true;
    
    try {
      final Set<String> processedFileHashes = {};
      final List<StatusModel> allStatuses = [];

      final businessStatuses = await _getStatusesFromPaths(
        _whatsappBusinessStatusPaths, 
        processedFileHashes
      );
      allStatuses.addAll(businessStatuses);

      // Sort by creation time (newest first)
      allStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Cache the results
      _cachedStatuses = allStatuses;
      _cacheTime = DateTime.now();
      await _saveCacheToStorage(allStatuses);

      return allStatuses;
    } finally {
      _isLoading = false;
    }
  }

  // Get statuses from specific paths with improved deduplication
  Future<List<StatusModel>> _getStatusesFromPaths(
    List<String> paths, 
    Set<String> processedFileHashes
  ) async {
    final List<StatusModel> statuses = [];
    final Set<String> processedPaths = {};

    for (String dirPath in paths) {
      try {
        final directory = Directory(dirPath);
        if (!await directory.exists()) continue;

        // Get the canonical path to handle symbolic links
        final String canonicalPath = await _getCanonicalPath(dirPath);
        
        // Skip if we've already processed this canonical path
        if (processedPaths.contains(canonicalPath)) {
          continue;
        }
        processedPaths.add(canonicalPath);

        final files = await directory.list().toList();

        for (var entity in files) {
          if (entity is File) {
            try {
              // Create unique hash for file content to detect true duplicates
              final String fileHash = await _generateFileHash(entity);
              
              if (!processedFileHashes.contains(fileHash)) {
                final status = StatusModel.fromFile(entity);
                if (status.isImage || status.isVideo) {
                  statuses.add(status);
                  processedFileHashes.add(fileHash);
                }
              }
            } catch (e) {
              // Skip files that can't be processed
              print('Error processing file ${entity.path}: $e');
              continue;
            }
          }
        }
      } catch (e) {
        print('Error accessing path $dirPath: $e');
      }
    }

    return statuses;
  }

  // Generate hash for file to detect true duplicates
  Future<String> _generateFileHash(File file) async {
    try {
      final stat = await file.stat();
      final String pathBaseName = path.basename(file.path);
      final String sizeModified = '${stat.size}_${stat.modified.millisecondsSinceEpoch}';
      
      // Create hash from filename, size, and modification time
      final bytes = utf8.encode('$pathBaseName$sizeModified');
      final digest = sha256.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      // Fallback to file path if stat fails
      return file.path;
    }
  }

  // Get canonical path to handle symbolic links
  Future<String> _getCanonicalPath(String dirPath) async {
    try {
      final directory = Directory(dirPath);
      final resolved = await directory.resolveSymbolicLinks();
      return resolved;
    } catch (e) {
      // Return original path if resolution fails
      return dirPath;
    }
  }

  // Check if cache is still valid
  bool _isCacheValid() {
    if (_cachedStatuses == null || _cacheTime == null) {
      return false;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_cacheTime!);
    
    return difference.inMinutes < _cacheValidityMinutes;
  }

  // Save cache to persistent storage
  Future<void> _saveCacheToStorage(List<StatusModel> statuses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> statusPaths = statuses.map((s) => s.filePath).toList();
      
      await prefs.setStringList(_cacheKey, statusPaths);
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving cache: $e');
    }
  }

  // Load cache from persistent storage
  Future<void> _loadCacheFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? cachedPaths = prefs.getStringList(_cacheKey);
      final String? cacheTimeString = prefs.getString(_cacheTimeKey);
      
      if (cachedPaths != null && cacheTimeString != null) {
        _cacheTime = DateTime.parse(cacheTimeString);
        
        if (_isCacheValid()) {
          _cachedStatuses = [];
          for (String filePath in cachedPaths) {
            final file = File(filePath);
            if (await file.exists()) {
              try {
                final status = StatusModel.fromFile(file);
                _cachedStatuses!.add(status);
              } catch (e) {
                print('Error loading cached status: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading cache: $e');
    }
  }

  // Clear cache manually
  Future<void> clearCache() async {
    _cachedStatuses = null;
    _cacheTime = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Force refresh statuses
  Future<List<StatusModel>> refreshStatuses() async {
    await clearCache();
    return await getWhatsAppBusinessStatuses(forceRefresh: true);
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

    final directory = await getExternalStorageDirectory();
    final downloadPath = '${directory!.path}/$_defaultDownloadFolder';

    final downloadDir = Directory(downloadPath);
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadPath;
  }

  // Generate unique file name to avoid conflicts
  String _generateUniqueFileName(String originalFileName, String directory) {
    if (!File('$directory/$originalFileName').existsSync()) {
      return originalFileName;
    }

    final nameWithoutExt = path.basenameWithoutExtension(originalFileName);
    final extension = path.extension(originalFileName);
    int counter = 1;
    
    while (true) {
      final newFileName = '${nameWithoutExt}_$counter$extension';
      if (!File('$directory/$newFileName').existsSync()) {
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

    downloads.add(jsonEncode(record));
    await prefs.setStringList('downloaded_statuses', downloads);
  }

  // Get download history
  Future<List<Map<String, dynamic>>> getDownloadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloads = prefs.getStringList('downloaded_statuses') ?? [];
      
      return downloads.map((recordString) {
        try {
          return jsonDecode(recordString) as Map<String, dynamic>;
        } catch (e) {
          print('Error parsing download record: $e');
          return <String, dynamic>{};
        }
      }).where((record) => record.isNotEmpty).toList();
    } catch (e) {
      print('Error getting download history: $e');
      return [];
    }
  }

  // Initialize service (call this when app starts)
  Future<void> initialize() async {
    await _loadCacheFromStorage();
  }

  // Get cache info for debugging
  Map<String, dynamic> getCacheInfo() {
    return {
      'hasCachedData': _cachedStatuses != null,
      'cachedItemCount': _cachedStatuses?.length ?? 0,
      'cacheTime': _cacheTime?.toIso8601String(),
      'isCacheValid': _isCacheValid(),
      'isLoading': _isLoading,
    };
  }
}