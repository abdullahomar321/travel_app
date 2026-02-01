import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send verification email
  static Future<void> sendEmailVerification() async {

    final user = _auth.currentUser;

    if (user == null) {
      throw Exception("No logged-in user");
    }

    if (user.emailVerified) {
      throw Exception("Email already verified");
    }

    await user.sendEmailVerification();
  }

  // Check verification status
  static Future<bool> isEmailVerified() async {

    final user = _auth.currentUser;

    if (user == null) return false;

    await user.reload();

    return _auth.currentUser!.emailVerified;
  }
}
