import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/splash_provider.dart';

class TravShareHomeScreen extends StatefulWidget {
  const TravShareHomeScreen({super.key});

  @override
  State<TravShareHomeScreen> createState() => _TravShareHomeScreenState();
}

class _TravShareHomeScreenState extends State<TravShareHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger the splash initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SplashProvider>(context, listen: false).initSplash(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Cobalt Blue Gradient
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0047AB), // Cobalt Blue
              Color(0xFF002E6D), // Darker Cobalt
            ],
          ),
        ),
        child: SafeArea(
          child: refactoredSplashContent(),
        ),
      ),
    );
  }

  Widget refactoredSplashContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // White Container for Logo
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DA6FF).withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: const Color(0xFF4DA6FF).withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: const Color(0xFF0047AB).withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.flight_takeoff_sharp,
                  size: 60,
                  color: Color(0xFF0047AB), // Cobalt Blue Icon
                ),
                SizedBox(height: 16),
                Text(
                  'TripTation',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                    color: Color(0xFF0047AB), // Cobalt Blue Text
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'YOUR TRAVEL DOCUMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3.0,
                    color: Color(0xFF0047AB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
