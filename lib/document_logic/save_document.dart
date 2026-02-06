import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:travel_app/document_logic/expiration.dart';
import 'package:path_provider/path_provider.dart';

class DocumentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save image locally and return the local path
  static Future<String?> saveImageLocally({
    required String userId,
    required String memberId,
    required String memberName,
    required File imageFile,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();

      final userFolder = Directory('${appDir.path}/users/$userId/members/$memberId/documents');

      if (!await userFolder.exists()) {
        await userFolder.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${memberName}_document_$timestamp.jpg';
      final localPath = '${userFolder.path}/$fileName';

      final savedFile = await imageFile.copy(localPath);

      print('Image saved locally to: $localPath');
      return savedFile.path;
    } catch (e) {
      print('Error saving image locally: $e');
      return null;
    }
  }

  static Future<String> createDocument({
    required String userId,
    required String memberId,
    required String memberName,
    required String documentName,
    required String holderName,
    required DateTime issueDate,
    required DateTime expiryDate,
    File? imageFile,
  }) async {
    try {
      print('Creating document for member: $memberName (ID: $memberId)');

      String? imagePath;
      if (imageFile != null) {
        imagePath = await saveImageLocally(
          userId: userId,
          memberId: memberId,
          memberName: memberName,
          imageFile: imageFile,
        );

        if (imagePath == null) {
          return "Failed to save image";
        }
      }

      final documentData = {
        'documentName': documentName,
        'holderName': holderName,
        'memberName': memberName,
        'memberId': memberId,
        'issueDate': Timestamp.fromDate(issueDate),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'imagePath': imagePath ?? '',
        'isDeleted': false, // Add isDeleted flag
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .add(documentData);

      print('Document created successfully with ID: ${docRef.id}');
      return "Document created successfully";

    } on FirebaseException catch (e) {
      print('Firebase error creating document: ${e.code} - ${e.message}');
      return "Firebase error: ${e.message}";
    } catch (e) {
      print('Error creating document: $e');
      return "Failed to create document: $e";
    }
  }

  /// Get documents for a specific member (active only, ordered by recent)
  static Stream<List<Map<String, dynamic>>> getMemberDocumentsStream({
    required String userId,
    required String memberId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
        .doc(memberId)
        .collection('documents')
        .where('isDeleted', isEqualTo: false) // Only active documents
        .orderBy('createdAt', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['issueDate'] is Timestamp) {
          data['issueDateParsed'] = (data['issueDate'] as Timestamp).toDate();
        }
        if (data['expiryDate'] is Timestamp) {
          data['expiryDateParsed'] = (data['expiryDate'] as Timestamp).toDate();
        }

        return data;
      }).toList();
    });
  }

  /// Get all active documents across all members (ordered by recent)
  static Future<List<Map<String, dynamic>>> getAllUserDocuments({
    required String userId,
  }) async {
    try {
      final membersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .where('isDeleted', isEqualTo: false) // Only active members
          .get();

      List<Map<String, dynamic>> allDocuments = [];

      for (var memberDoc in membersSnapshot.docs) {
        final documentsSnapshot = await memberDoc.reference
            .collection('documents')
            .where('isDeleted', isEqualTo: false) // Only active documents
            .get();

        for (var doc in documentsSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['memberId'] = memberDoc.id;

          if (data['issueDate'] is Timestamp) {
            data['issueDateParsed'] = (data['issueDate'] as Timestamp).toDate();
          }
          if (data['expiryDate'] is Timestamp) {
            data['expiryDateParsed'] = (data['expiryDate'] as Timestamp).toDate();
          }
          if (data['createdAt'] is Timestamp) {
            data['createdAtParsed'] = (data['createdAt'] as Timestamp).toDate();
          }

          allDocuments.add(data);
        }
      }

      // Sort by createdAt (most recent first)
      allDocuments.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate); // Descending order
      });

      return allDocuments;
    } catch (e) {
      print('Error getting all user documents: $e');
      return [];
    }
  }

  /// Get deleted documents for a specific member
  static Stream<List<Map<String, dynamic>>> getDeletedMemberDocumentsStream({
    required String userId,
    required String memberId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
        .doc(memberId)
        .collection('documents')
        .where('isDeleted', isEqualTo: true)
        .orderBy('deletedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['issueDate'] is Timestamp) {
          data['issueDateParsed'] = (data['issueDate'] as Timestamp).toDate();
        }
        if (data['expiryDate'] is Timestamp) {
          data['expiryDateParsed'] = (data['expiryDate'] as Timestamp).toDate();
        }

        return data;
      }).toList();
    });
  }

  static Future<String> updateDocument({
    required String userId,
    required String memberId,
    required String documentId,
    String? documentName,
    DateTime? issueDate,
    DateTime? expiryDate,
    File? newImageFile,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (documentName != null) {
        updates['documentName'] = documentName;
      }
      if (issueDate != null) {
        updates['issueDate'] = Timestamp.fromDate(issueDate);
      }
      if (expiryDate != null) {
        updates['expiryDate'] = Timestamp.fromDate(expiryDate);
      }

      if (newImageFile != null) {
        final memberDoc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('familymembers')
            .doc(memberId)
            .get();

        final memberName = memberDoc.data()?['name'] ?? 'Unknown';

        final imagePath = await saveImageLocally(
          userId: userId,
          memberId: memberId,
          memberName: memberName,
          imageFile: newImageFile,
        );

        if (imagePath != null) {
          updates['imagePath'] = imagePath;
        }
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .doc(documentId)
          .update(updates);

      return "Document updated successfully";
    } catch (e) {
      print('Error updating document: $e');
      return "Failed to update document: $e";
    }
  }

  /// Soft delete a document
  static Future<String> deleteDocument({
    required String userId,
    required String memberId,
    required String documentId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .doc(documentId)
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return "Document moved to trash";
    } catch (e) {
      print('Error deleting document: $e');
      return "Failed to delete document: $e";
    }
  }

  /// Restore a soft-deleted document
  static Future<String> restoreDocument({
    required String userId,
    required String memberId,
    required String documentId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .doc(documentId)
          .update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'restoredAt': FieldValue.serverTimestamp(),
      });

      return "Document restored successfully";
    } catch (e) {
      print('Error restoring document: $e');
      return "Failed to restore document: $e";
    }
  }

  /// Permanently delete a document
  static Future<String> permanentlyDeleteDocument({
    required String userId,
    required String memberId,
    required String documentId,
  }) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .doc(documentId)
          .get();

      final imagePath = docSnapshot.data()?['imagePath'];

      await docSnapshot.reference.delete();

      if (imagePath != null && imagePath.isNotEmpty) {
        try {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            await imageFile.delete();
            print('Local image deleted');
          }
        } catch (e) {
          print('Error deleting local image: $e');
        }
      }

      return "Document permanently deleted";
    } catch (e) {
      print('Error permanently deleting document: $e');
      return "Failed to permanently delete document: $e";
    }
  }

  /// Get active document count for a member
  static Future<int> getMemberDocumentCount({
    required String userId,
    required String memberId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting document count: $e');
      return 0;
    }
  }

  /// Get deleted document count for a member
  static Future<int> getDeletedDocumentCount({
    required String userId,
    required String memberId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .where('isDeleted', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting deleted document count: $e');
      return 0;
    }
  }

  static bool isExpiringSoon(DateTime expiryDate) {
    return ExpiryUtils.getStatus(expiryDate) == 'EXPIRING SOON';
  }

  static bool isExpired(DateTime expiryDate) {
    return ExpiryUtils.getStatus(expiryDate) == 'EXPIRED';
  }

  static String getExpiryStatus(DateTime expiryDate) {
    return ExpiryUtils.getStatus(expiryDate);
  }

  static Color getExpiryStatusColor(DateTime expiryDate) {
    return ExpiryUtils.getStatusColor(expiryDate);
  }

  static int daysLeft(DateTime expiryDate) {
    return ExpiryUtils.daysLeft(expiryDate);
  }
}