import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMembersService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get family members stream with document IDs included
  static Stream<List<Map<String, dynamic>>> getFamilyMembersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // ← Include document ID
        return data;
      }).toList();
    });
  }
}