import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<String> deleteAccountByUsernamePassword({
  required BuildContext context,
  required String inputUsername,
  required String inputPassword,
  required Widget homeScreen, // Add this parameter
}) async {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final currentUser = auth.currentUser;

  if (currentUser == null) {
    return "No logged-in user found";
  }

  try {
    // Query Firestore users collection to find document with matching username
    final querySnapshot = await firestore
        .collection('users')
        .where('username', isEqualTo: inputUsername)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return "Username not found";
    }

    final userDoc = querySnapshot.docs.first;
    final data = userDoc.data();

    if (data['password'] != inputPassword) {
      return "Incorrect password";
    }

    final email = data['email'];

    final credential = EmailAuthProvider.credential(email: email, password: inputPassword);

    await currentUser.reauthenticateWithCredential(credential);

    // Delete Firestore document
    await firestore.collection('users').doc(userDoc.id).delete();

    // Delete Firebase Auth user
    await currentUser.delete();

    // Navigate back to home screen (remove all previous routes)
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => homeScreen),
            (route) => false,
      );
    }

    return "Account deleted successfully";

  } catch (e) {
    return "Failed to delete account: $e";
  }
}