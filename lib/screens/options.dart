import 'package:travel_app/screens/login.dart';
import 'package:travel_app/screens/signup.dart';
import 'package:travel_app/widgets/triptation_logo.dart';
import 'package:flutter/material.dart';
import 'package:travel_app/widgets/graphical_elements.dart';

class Options extends StatefulWidget {
  const Options({super.key});

  @override
  State<Options> createState() => _OptionsState();
}

class _OptionsState extends State<Options> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.7;

    // Blue gradient colors
    const gradientColors = [
      Color(0xFF0047AB),
      Color(0xFF002E6D),
    ];

    return Scaffold(
      // Remove app bar
      extendBodyBehindAppBar: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Background Blobs for depth
            Positioned(
              left: -50,
              top: -50,
              child: AnimatedBlob(
                color: Colors.blue.withOpacity(0.15),
                offset: const Offset(-50, -50),
                size: 300,
              ),
            ),
            Positioned(
              right: -100,
              bottom: -100,
              child: AnimatedBlob(
                color: Colors.purple.withOpacity(0.15),
                offset: const Offset(200, 400),
                size: 400,
              ),
            ),

            // SafeArea to prevent notch/edges overlap, but no white gaps
            SafeArea(
              bottom: false, // Let gradient extend to bottom edge fully
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EntranceFader(
                        delay: 0,
                        child: Column(
                          children: [
                            const TripTationLogo(size: 100),
                            const SizedBox(height: 16),
                            const Text(
                              'TripTation',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Sign Up Button (White with Neon Glow)
                      EntranceFader(
                        delay: 200,
                        child: Container(
                          width: buttonWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4DA6FF).withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: const Color(0xFF4DA6FF).withOpacity(0.4),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFF0047AB).withOpacity(0.3),
                                blurRadius: 45,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0047AB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignupScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Log In Button (White with Neon Glow)
                      EntranceFader(
                        delay: 400,
                        child: Container(
                          width: buttonWidth,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4DA6FF).withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: const Color(0xFF4DA6FF).withOpacity(0.4),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: const Color(0xFF0047AB).withOpacity(0.3),
                                blurRadius: 45,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0047AB),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
