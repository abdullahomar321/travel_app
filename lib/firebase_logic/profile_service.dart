import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';

class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> updateProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Get app's document directory
      final appDir = await getApplicationDocumentsDirectory();

      // Create profile folder
      final profileFolder = Directory('${appDir.path}/users/$userId/profile');

      if (!await profileFolder.exists()) {
        await profileFolder.create(recursive: true);
      }

      final fileName = 'profile_picture.jpg';
      final localPath = '${profileFolder.path}/$fileName';

      // Copy image to app directory
      final savedFile = await imageFile.copy(localPath);

      // Update Firestore with image path
      await _firestore.collection('users').doc(userId).update({
        'profilePicturePath': savedFile.path,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Profile picture saved to: $localPath');

      return {
        'success': true,
        'message': 'Profile picture updated successfully',
        'path': savedFile.path,
      };
    } catch (e) {
      print('Error updating profile picture: $e');
      return {
        'success': false,
        'message': 'Failed to update profile picture: $e',
      };
    }
  }

  /// Get profile picture path
  static Future<String?> getProfilePicturePath(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        return userDoc.data()?['profilePicturePath'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting profile picture: $e');
      return null;
    }
  }

  /// Stream profile picture path (real-time updates)
  static Stream<String?> profilePictureStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data()?['profilePicturePath'] as String?;
      }
      return null;
    });
  }

  /// Delete profile picture
  static Future<Map<String, dynamic>> deleteProfilePicture({
    required String userId,
  }) async {
    try {
      // Get current path
      final path = await getProfilePicturePath(userId);

      if (path != null && path.isNotEmpty) {
        // Delete local file
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePicturePath': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Profile picture deleted successfully',
      };
    } catch (e) {
      print('Error deleting profile picture: $e');
      return {
        'success': false,
        'message': 'Failed to delete profile picture: $e',
      };
    }
  }
}