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

  /// Read/Get all family members
  static Stream<List<Map<String, dynamic>>> getFamilyMembersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
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

  /// Delete a family member
  static Future<Map<String, dynamic>> deleteFamilyMember({
    required String userId,
    required String memberId,
  }) async {
    try {
      // First delete all documents for this member
      final documentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .doc(memberId)
          .collection('documents')
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in documentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the family member
      batch.delete(
        _firestore
            .collection('users')
            .doc(userId)
            .collection('familymembers')
            .doc(memberId),
      );

      await batch.commit();

      return {
        'success': true,
        'message': 'Family member deleted successfully',
      };
    } catch (e) {
      print('Error deleting family member: $e');
      return {
        'success': false,
        'message': 'Failed to delete family member: $e',
      };
    }
  }

  /// Get family member count
  static Future<int> getFamilyMemberCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting family member count: $e');
      return 0;
    }
  }
}