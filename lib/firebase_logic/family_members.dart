import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addDummyFamilyMembers(String userId) async {
    final familyMembersCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('familymembers');

    List<Map<String, dynamic>> dummyMembers = List.generate(20, (index) {
      return {
        'name': 'Member ${index + 1}',
        'age': 20 + index,
        'relation': 'Relation ${index + 1}',
        // Add other dummy fields if you want
      };
    });

    WriteBatch batch = _firestore.batch();

    for (var member in dummyMembers) {
      final docRef = familyMembersCollection.doc(); // random doc id
      batch.set(docRef, member);
    }

    await batch.commit();
  }
}
