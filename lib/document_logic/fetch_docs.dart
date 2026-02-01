import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_app/document_logic/expiration.dart';
import 'package:flutter/material.dart';

class DocumentFetchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all documents across all family members for a user
  static Stream<List<Map<String, dynamic>>> getAllUserDocumentsStream({
    required String userId,
  }) async* {
    // First, get all family members
    final membersStream = _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
        .snapshots();

    await for (var membersSnapshot in membersStream) {
      List<Map<String, dynamic>> allDocuments = [];

      // For each family member, get their documents
      for (var memberDoc in membersSnapshot.docs) {
        final memberId = memberDoc.id;
        final memberData = memberDoc.data();

        try {
          final documentsSnapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection('familymembers')
              .doc(memberId)
              .collection('documents')
              .get();

          for (var docSnapshot in documentsSnapshot.docs) {
            final data = docSnapshot.data();
            data['id'] = docSnapshot.id;
            data['memberId'] = memberId;

            // Convert Timestamps to DateTime
            if (data['issueDate'] is Timestamp) {
              data['issueDateParsed'] = (data['issueDate'] as Timestamp).toDate();
            }
            if (data['expiryDate'] is Timestamp) {
              data['expiryDateParsed'] = (data['expiryDate'] as Timestamp).toDate();
            }

            // Add member details
            data['memberDetails'] = memberData;

            allDocuments.add(data);
          }
        } catch (e) {
          print('Error fetching documents for member $memberId: $e');
        }
      }

      // Sort by creation date (newest first)
      allDocuments.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null || bDate == null) return 0;
        return bDate.compareTo(aDate);
      });

      yield allDocuments;
    }
  }

  /// Get document by ID
  static Future<Map<String, dynamic>?> getDocumentById({
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

      if (!docSnapshot.exists) return null;

      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;

      // Convert Timestamps
      if (data['issueDate'] is Timestamp) {
        data['issueDateParsed'] = (data['issueDate'] as Timestamp).toDate();
      }
      if (data['expiryDate'] is Timestamp) {
        data['expiryDateParsed'] = (data['expiryDate'] as Timestamp).toDate();
      }

      return data;
    } catch (e) {
      print('Error fetching document: $e');
      return null;
    }
  }

  /// Get expiry status for a document
  static String getExpiryStatus(DateTime expiryDate) {
    return ExpiryUtils.getStatus(expiryDate);
  }

  /// Get expiry status color for a document
  static Color getExpiryStatusColor(DateTime expiryDate) {
    return ExpiryUtils.getStatusColor(expiryDate);
  }

  /// Format date as dd-MM-yyyy
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.year}";
  }

  /// Get days remaining until expiry
  static int getDaysRemaining(DateTime expiryDate) {
    return ExpiryUtils.daysLeft(expiryDate);
  }
}