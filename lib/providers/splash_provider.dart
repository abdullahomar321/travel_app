import 'package:flutter/material.dart';
import 'package:travel_app/screens/options.dart';

class SplashProvider with ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> initSplash(BuildContext context) async {

    await Future.delayed(const Duration(seconds: 3));
    
    _isLoading = false;
    notifyListeners();

    // Navigate to Options Screen
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Options()),
      );
    }
  }
}
