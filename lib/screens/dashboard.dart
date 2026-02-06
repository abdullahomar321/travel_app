import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/theme_provider.dart';
import 'package:travel_app/screens/create_doc.dart';
import 'package:travel_app/screens/familymembers.dart';
import 'package:travel_app/screens/home.dart';
import 'package:travel_app/screens/settings.dart';
import 'package:travel_app/screens/your_docs.dart';
import 'package:travel_app/screens/add_family_member.dart';
import 'package:travel_app/screens/profile_pic.dart';
import 'package:travel_app/firebase_logic/profile_service.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final secondaryColor = themeProvider.secondaryColor;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TripTation',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(context, themeProvider),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email?.split('@')[0] ?? 'Traveler',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _DashboardGlassCard(
                      icon: Icons.family_restroom_rounded,
                      label: 'Family Members',
                      subLabel: 'View list',
                      onTap: () {
                        _navigateTo(context, (userId) => FamilyMembersScreen(userId: userId));
                      },
                    ),
                    _DashboardGlassCard(
                      icon: Icons.description_rounded,
                      label: 'Your Docs',
                      subLabel: 'View & share',
                      onTap: () {
                        _navigateTo(context, (userId) => const YourDocsScreen());
                      },
                    ),
                    _DashboardGlassCard(
                      icon: Icons.create_new_folder_rounded,
                      label: 'Create Doc',
                      subLabel: 'Upload new',
                      onTap: () {
                        _navigateTo(context, (userId) => CreateDocumentUI(userId: userId));
                      },
                    ),
                    _DashboardGlassCard(
                      icon: Icons.person_add_rounded,
                      label: 'Add Family',
                      subLabel: 'New member',
                      onTap: () {
                        _navigateTo(context, (userId) => AddFamilyMemberScreen(userId: userId));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget Function(String) pageBuilder) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => pageBuilder(user.uid)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Widget _buildDrawer(BuildContext context, ThemeProvider themeProvider) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Profile Picture Header with StreamBuilder
            StreamBuilder<String?>(
              stream: user != null
                  ? ProfileService.profilePictureStream(user.uid)
                  : Stream.value(null),
              builder: (context, snapshot) {
                final profilePicturePath = snapshot.data;

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor,
                  ),
                  accountName: const Text(
                    'TripTation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  accountEmail: Text(user?.email ?? 'No Email'),
                  currentAccountPicture: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context); // Close drawer

                      final result = await showDialog(
                        context: context,
                        builder: (context) => ProfilePictureDialog(
                          currentImagePath: profilePicturePath,
                        ),
                      );

                      // Dialog returns true if picture was updated
                      // StreamBuilder will automatically update the avatar
                    },
                    child: Hero(
                      tag: 'profile_avatar',
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: profilePicturePath != null &&
                            profilePicturePath.isNotEmpty &&
                            File(profilePicturePath).existsSync()
                            ? FileImage(File(profilePicturePath))
                            : null,
                        child: profilePicturePath == null ||
                            profilePicturePath.isEmpty ||
                            !File(profilePicturePath).existsSync()
                            ? Icon(Icons.person, size: 40, color: themeProvider.primaryColor)
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),

            _buildDrawerItem(Icons.settings_outlined, 'Account Settings', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }, themeProvider.primaryColor),

            ExpansionTile(
              leading: Icon(Icons.palette_outlined, color: themeProvider.primaryColor),
              title: const Text('Appearance'),
              children: [
                _buildThemeOption(context, themeProvider, 'Cobalt Blue', const Color(0xFF0047AB)),
                _buildThemeOption(context, themeProvider, 'Teal', Colors.teal),
                _buildThemeOption(context, themeProvider, 'Deep Purple', Colors.deepPurple),
                _buildThemeOption(context, themeProvider, 'Dark Elegant', Colors.black87),
              ],
            ),

            const Divider(),

            _buildDrawerItem(Icons.logout_rounded, 'Log Out', () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const TravShareHomeScreen()),
                        (route) => false,
                  );
                }
              }
            }, Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildThemeOption(BuildContext context, ThemeProvider provider, String name, Color color) {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 18),
      title: Text(name),
      onTap: () => provider.setTheme(color),
      trailing: provider.primaryColor == color
          ? const Icon(Icons.check, color: Colors.green)
          : null,
    );
  }
}

class _DashboardGlassCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final VoidCallback? onTap;

  const _DashboardGlassCard({
    required this.icon,
    required this.label,
    required this.subLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
              boxShadow: [
                // Base elevation
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
                // Subtle neon elevation (edge glow)
                BoxShadow(
                  color: const Color(0xFF4DA6FF).withOpacity(0.18),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(minHeight: 180),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subLabel,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}