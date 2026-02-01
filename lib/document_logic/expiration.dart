import 'package:flutter/material.dart';

class ExpiryUtils {

  static int daysLeft(DateTime expiryDate) {
    final now = DateTime.now();
    return expiryDate.difference(now).inDays;
  }


  static String getStatus(DateTime expiryDate) {
    final remainingDays = daysLeft(expiryDate);

    if (remainingDays < 0) {
      return "EXPIRED";
    }
    else if (remainingDays <= 180) {
      return "EXPIRING SOON";
    }
    else {
      return "VALID";
    }
  }



  static Color getStatusColor(DateTime expiryDate) {
    final remainingDays = daysLeft(expiryDate);

    if (remainingDays < 0) {
      return Colors.red;
    }
    else if (remainingDays <= 180) {
      return Colors.yellow;
    }
    else {
      return Colors.green;
    }
  }
}
