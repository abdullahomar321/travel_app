import 'package:flutter/material.dart';

class TripTationLogo extends StatelessWidget {
  final double size;
  final Color? shadowColor;

  const TripTationLogo({
    super.key,
    this.size = 200,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? Colors.black.withOpacity(0.2),
            blurRadius: size * 0.2,
            spreadRadius: size * 0.05,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: Image.asset(
          'assets/images/triptation_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
