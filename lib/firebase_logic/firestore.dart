import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> saveUserDetails({
    required String email,
    required String username,
    required String password,
  }) async {
    await _firestore.collection('users').add({
      'email': email,
      'username': username,
      'password': password,
    });
  }
}
