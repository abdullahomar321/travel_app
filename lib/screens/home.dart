import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/splash_provider.dart';
import 'package:travel_app/providers/theme_provider.dart';
import 'package:travel_app/widgets/triptation_logo.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);
    // final primaryColor = themeProvider.primaryColor; // no longer used for container background

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Themed Container for Logo with neon light blue glow
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 20.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0047AB), // Cobalt Blue background for logo container
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                // Neon light blue glow
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.3),
                  blurRadius: 60,
                  spreadRadius: 15,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                const TripTationLogo(
                  size: 100,
                  shadowColor: Colors.black26,
                ),
                const SizedBox(height: 20),
                const Text(
                  'TripTation',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'YOUR TRAVEL DOCUMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 3.0,
                    color: Colors.white.withOpacity(0.9),
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
