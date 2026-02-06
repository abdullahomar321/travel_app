import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyCRUDService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new family member
  static Future<Map<String, dynamic>> createFamilyMember({
    required String userId,
    required String name,
    required int age,
    required String relation,
  }) async {
    try {
      final familyMembersCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers');

      final docRef = await familyMembersCollection.add({
        'name': name,
        'age': age,
        'relation': relation,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Family member added successfully',
        'memberId': docRef.id,
      };
    } catch (e) {
      print('Error creating family member: $e');
      return {
        'success': false,
        'message': 'Failed to add family member: $e',
      };
    }
  }

  /// Read/Get all active family members (not deleted)
  static Stream<List<Map<String, dynamic>>> getFamilyMembersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Read/Get only deleted family members
  static Stream<List<Map<String, dynamic>>> getDeletedFamilyMembersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
        .where('isDeleted', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Update a family member
  static Future<Map<String, dynamic>> updateFamilyMember({
    required String userId,
    required String memberId,
    required String name,
    required int age,
    required String relation,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .update({
        'name': name,
        'age': age,
        'relation': relation,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Family member updated successfully',
      };
    } catch (e) {
      print('Error updating family member: $e');
      return {
        'success': false,
        'message': 'Failed to update family member: $e',
      };
    }
  }

  /// Soft delete a family member and their documents
  static Future<Map<String, dynamic>> deleteFamilyMember({
    required String userId,
    required String memberId,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Soft delete the family member
      final memberRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId);

      batch.update(memberRef, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      // Soft delete all documents for this member
      final documentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .get();

      for (var doc in documentsSnapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Family member and their documents moved to trash',
      };
    } catch (e) {
      print('Error soft-deleting family member: $e');
      return {
        'success': false,
        'message': 'Failed to delete: $e',
      };
    }
  }

  /// Restore a soft-deleted family member and their documents
  static Future<Map<String, dynamic>> restoreFamilyMember({
    required String userId,
    required String memberId,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Restore the family member
      final memberRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId);

      batch.update(memberRef, {
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'restoredAt': FieldValue.serverTimestamp(),
      });

      // Restore all documents for this member
      final documentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .where('isDeleted', isEqualTo: true)
          .get();

      for (var doc in documentsSnapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': false,
          'deletedAt': FieldValue.delete(),
          'restoredAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Family member and their documents restored successfully',
      };
    } catch (e) {
      print('Error restoring family member: $e');
      return {
        'success': false,
        'message': 'Failed to restore: $e',
      };
    }
  }

  /// Permanently delete a family member and their documents
  static Future<Map<String, dynamic>> permanentlyDeleteFamilyMember({
    required String userId,
    required String memberId,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();

      // Delete all documents for this member
      final documentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .get();

      for (var doc in documentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the family member
      final memberRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId);

      batch.delete(memberRef);

      await batch.commit();

      return {
        'success': true,
        'message': 'Family member permanently deleted',
      };
    } catch (e) {
      print('Error permanently deleting family member: $e');
      return {
        'success': false,
        'message': 'Failed to permanently delete: $e',
      };
    }
  }

  /// Get family member count (active only)
  static Future<int> getFamilyMemberCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting family member count: $e');
      return 0;
    }
  }

  /// Get deleted family member count
  static Future<int> getDeletedFamilyMemberCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .where('isDeleted', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting deleted family member count: $e');
      return 0;
    }
  }

  /// Empty trash - permanently delete all soft-deleted members
  static Future<Map<String, dynamic>> emptyTrash({
    required String userId,
  }) async {
    try {
      final deletedMembers = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .where('isDeleted', isEqualTo: true)
          .get();

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var memberDoc in deletedMembers.docs) {
        // Delete all documents for this member
        final documentsSnapshot = await memberDoc.reference
            .collection('documents')
            .get();

        for (var doc in documentsSnapshot.docs) {
          batch.delete(doc.reference);
        }

        // Delete the member
        batch.delete(memberDoc.reference);
        count++;
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Permanently deleted $count family member(s)',
        'count': count,
      };
    } catch (e) {
      print('Error emptying trash: $e');
      return {
        'success': false,
        'message': 'Failed to empty trash: $e',
      };
    }
  }
}