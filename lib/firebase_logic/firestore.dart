import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Save user details and create Firebase Auth account
  static Future<Map<String, dynamic>> saveUserDetails({
    required String email,
    required String username,
    required String password,
  }) async {
    try {
      // Step 1: Check if username already exists
      final usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Username already exists',
        };
      }

      // Step 2: Create Firebase Auth account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;

      if (userId == null) {
        return {
          'success': false,
          'message': 'Failed to create account',
        };
      }

      // Step 3: Save user details to Firestore with userId as document ID
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'username': username,
        'password': password,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Account created successfully',
        'userId': userId,
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? 'Registration failed';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      print("Error saving user details: $e");
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

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