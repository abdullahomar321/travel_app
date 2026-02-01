import 'package:cloud_firestore/cloud_firestore.dart';

class NameVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verify if the entered name matches any family member name
  static Future<bool> verifyName(String userId, String enteredName) async {
    try {
      final familyMembersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .get();

      // Check if any family member's name matches (case-insensitive)
      for (var doc in familyMembersSnapshot.docs) {
        final memberName = doc.data()['name']?.toString().toLowerCase() ?? '';
        if (memberName == enteredName.toLowerCase().trim()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error verifying name: $e');
      return false;
    }
  }

  /// Get list of all family member names for suggestions/autocomplete
  static Future<List<String>> getFamilyMemberNames(String userId) async {
    try {
      final familyMembersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .get();

      return familyMembersSnapshot.docs
          .map((doc) => doc.data()['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error fetching family member names: $e');
      return [];
    }
  }

  /// Get list of family members with their IDs for dropdown/selection
  static Future<List<Map<String, dynamic>>> getFamilyMembersWithIds(String userId) async {
    try {
      final familyMembersSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('familymembers')
          .get();

      return familyMembersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Include document ID
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching family members: $e');
      return [];
    }
  }
}