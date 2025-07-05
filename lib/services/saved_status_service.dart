import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/status_model.dart';

class SavedStatusService {
  static const String _defaultDownloadFolder = 'WhatsApp Status Downloads';

  // Get the directory where statuses are saved
  Future<Directory?> _getDownloadDirectory() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) return null;

      final downloadPath = '${directory.path}/$_defaultDownloadFolder';
      final downloadDir = Directory(downloadPath);

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir;
    } catch (e) {
      print("Error getting download directory: $e");
      return null;
    }
  }

  // Fetch all saved statuses from the download folder
  Future<List<StatusModel>> getSavedStatuses() async {
    final directory = await _getDownloadDirectory();
    if (directory == null) {
      return [];
    }

    final List<StatusModel> savedStatuses = [];
    final files = await directory.list().toList();

    for (var entity in files) {
      if (entity is File) {
        final status = StatusModel.fromFile(entity);
        if (status.isImage || status.isVideo) {
          savedStatuses.add(status);
        }
      }
    }

    // Sort by creation date (newest first)
    savedStatuses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return savedStatuses;
  }

  // Delete a saved status file
  Future<bool> deleteStatus(StatusModel status) async {
    try {
      final file = File(status.filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print("Error deleting status: $e");
      return false;
    }
  }
}
