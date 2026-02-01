import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    final result = await permission.request();

    if (result.isDenied) {
      return false;
    } else if (result.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return result.isGranted;
  }

  /// Compress image to reduce file size
  static Future<File?> compressImage(File file) async {
    try {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print("Compressing image...");
      print("Original size: ${await file.length()} bytes");

      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Adjust quality (0-100, lower = smaller file)
        minWidth: 1024, // Maximum width
        minHeight: 1024, // Maximum height
        format: CompressFormat.jpeg,
      );

      if (result == null) {
        print("Compression failed, using original image");
        return file;
      }

      final compressedFile = File(result.path);
      print("Compressed size: ${await compressedFile.length()} bytes");

      return compressedFile;
    } catch (e) {
      print("Error compressing image: $e");
      return file; // Return original if compression fails
    }
  }

  /// Pick image from camera or gallery with proper permission checks
  static Future<File?> pickImage({required bool fromCamera}) async {
    try {
      Permission permission;

      if (fromCamera) {
        permission = Permission.camera;
      } else {
        // For Android 13+ and iOS, use Permission.photos
        permission = Permission.photos;
      }

      print("Checking permission: $permission");
      final hasPermission = await requestPermission(permission);

      if (!hasPermission) {
        print("Permission denied or not granted.");
        return null;
      }

      print("Opening image picker...");
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920, // Increased since we'll compress anyway
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        print("No image selected.");
        return null;
      }

      print("Image picked: ${pickedFile.path}");

      // Compress the picked image
      final originalFile = File(pickedFile.path);
      final compressedFile = await compressImage(originalFile);

      return compressedFile;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }
}