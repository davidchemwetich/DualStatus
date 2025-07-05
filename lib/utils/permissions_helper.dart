import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionsHelper {
  // Request storage permission for accessing WhatsApp statuses
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Check Android version and request appropriate permissions
      final androidInfo = Platform.version;
      
      // For Android 11+ (API 30+), we need to request MANAGE_EXTERNAL_STORAGE
      // or use scoped storage approach
      if (await _isAndroid11OrHigher()) {
        return await _requestAndroid11Permissions();
      } else {
        return await _requestLegacyStoragePermissions();
      }
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit storage permissions for app directories
      return true;
    }
    
    return false;
  }

  // Check if device is running Android 11 or higher
  static Future<bool> _isAndroid11OrHigher() async {
    try {
      // This is a simplified check - in production, you'd want to check the actual API level
      return Platform.version.contains('11') || 
             Platform.version.contains('12') || 
             Platform.version.contains('13') ||
             Platform.version.contains('14');
    } catch (e) {
      return false;
    }
  }

  // Request permissions for Android 11+
  static Future<bool> _requestAndroid11Permissions() async {
    // Check if we already have permission
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Request MANAGE_EXTERNAL_STORAGE permission
    final status = await Permission.manageExternalStorage.request();
    
    if (status.isGranted) {
      return true;
    }

    // If manage external storage is denied, try storage permission
    return await _requestLegacyStoragePermissions();
  }

  // Request permissions for Android 10 and below
  static Future<bool> _requestLegacyStoragePermissions() async {
    final permissions = [
      Permission.storage,
    ];

    // Check current status
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    // Check if all permissions are granted
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    return allGranted;
  }

  // Check if storage permission is granted
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid11OrHigher()) {
        return await Permission.manageExternalStorage.isGranted ||
               await Permission.storage.isGranted;
      } else {
        return await Permission.storage.isGranted;
      }
    }
    return true; // iOS
  }

  // Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Request camera permission (if needed for camera features)
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request notification permission (for download notifications)
  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true; // iOS handles notifications differently
  }

  // Check multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }

  // Get permission status as string for UI display
  static String getPermissionStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      default:
        return 'Unknown';
    }
  }

  // Show permission rationale dialog
  static Future<bool> shouldShowRequestPermissionRationale(Permission permission) async {
    if (Platform.isAndroid) {
      final status = await permission.status;
      return status.isDenied && !status.isPermanentlyDenied;
    }
    return false;
  }

  // Request all required permissions for the app
  static Future<Map<String, bool>> requestAllRequiredPermissions() async {
    final results = <String, bool>{};
    
    // Storage permission
    results['storage'] = await requestStoragePermission();
    
    // Notification permission (optional)
    results['notification'] = await requestNotificationPermission();
    
    return results;
  }

  // Check if permission is permanently denied and user needs to go to settings
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }
}