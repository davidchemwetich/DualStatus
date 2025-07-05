import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/status_model.dart';
import 'package:path/path.dart' as path;

class WhatsAppBusinessStatusService {
  static const String _downloadFolderKey = 'download_folder';
  static const String _defaultDownloadFolder = 'WhatsApp Status Downloads';

  // Get WhatsApp Business status directory paths
  List<String> get _whatsappBusinessStatusPaths {
    return [
      '/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
      '/storage/emulated/0/WhatsApp Business/Media/.Statuses',
      '/sdcard/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses',
      '/sdcard/WhatsApp Business/Media/.Statuses',
    ];
  }

  // Get all WhatsApp Business statuses
  Future<List<StatusModel>> getWhatsAppBusinessStatuses() async {
    final Set<String> processedFilePaths = {};
    final List<StatusModel> allStatuses = [];

    final businessStatuses = await _getStatusesFromPaths(_whatsappBusinessStatusPaths, processedFilePaths);
    allStatuses.addAll(businessStatuses);

    allStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return allStatuses;
  }

  // Get statuses from specific paths, avoiding duplicates
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

    downloads.add(record.toString());
    await prefs.setStringList('downloaded_statuses', downloads);
  }
}
