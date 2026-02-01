import 'package:cloud_firestore/cloud_firestore.dart';

class FireStoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<bool> validateUserLogin({
    required String username,
    required String password,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      final userDoc = querySnapshot.docs.first;
      final data = userDoc.data();

      final storedPassword = data['password'] as String?;

      if (storedPassword != null && storedPassword == password) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error validating login: $e");
      return false;
    }
  }
}
