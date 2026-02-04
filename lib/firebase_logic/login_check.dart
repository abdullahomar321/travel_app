import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FireStoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validate user login and sign in with Firebase Auth
  static Future<Map<String, dynamic>> validateAndSignIn({
    required String username,
    required String password,
  }) async {
    try {
      // Step 1: Find user by username in Firestore
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Username not found',
        };
      }

      final userDoc = querySnapshot.docs.first;
      final data = userDoc.data();

      final storedPassword = data['password'] as String?;
      final email = data['email'] as String?;

      // Step 2: Validate password
      if (storedPassword == null || storedPassword != password) {
        return {
          'success': false,
          'message': 'Incorrect password',
        };
      }

      // Step 3: Sign in with Firebase Auth using email
      if (email == null) {
        return {
          'success': false,
          'message': 'Email not found for this user',
        };
      }

      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        return {
          'success': true,
          'message': 'Login successful',
          'userId': userCredential.user?.uid,
          'user': userCredential.user,
        };
      } on FirebaseAuthException catch (authError) {
        print('Firebase Auth Error: ${authError.code} - ${authError.message}');
        return {
          'success': false,
          'message': 'Authentication failed: ${authError.message}',
        };
      }
    } catch (e) {
      print("Error validating login: $e");
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Legacy method for backward compatibility
  static Future<bool> validateUserLogin({
    required String username,
    required String password,
  }) async {
    final result = await validateAndSignIn(
      username: username,
      password: password,
    );
    return result['success'] ?? false;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Check if user is logged in
  static bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}