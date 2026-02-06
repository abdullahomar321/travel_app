import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:travel_app/providers/theme_provider.dart';
import 'package:travel_app/screens/create_doc.dart';
import 'package:travel_app/screens/familymembers.dart';
import 'package:travel_app/screens/home.dart';
import 'package:travel_app/screens/settings.dart';
import 'package:travel_app/screens/your_docs.dart';
import 'package:travel_app/screens/add_family_member.dart';
import 'package:travel_app/screens/profile_pic.dart';
import 'package:travel_app/firebase_logic/profile_service.dart';

import 'package:travel_app/screens/history.dart';
import 'package:travel_app/screens/deleted_members.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  final List<String> travelImages = const [
    "https://images.pexels.com/photos/460672/pexels-photo-460672.jpeg",
    "https://images.pexels.com/photos/338515/pexels-photo-338515.jpeg",
    "https://images.pexels.com/photos/356004/pexels-photo-356004.jpeg",
    "https://images.pexels.com/photos/2422369/pexels-photo-2422369.jpeg",
    "https://images.pexels.com/photos/460621/pexels-photo-460621.jpeg",
    "https://images.pexels.com/photos/164634/pexels-photo-164634.jpeg",
    "https://images.pexels.com/photos/457882/pexels-photo-457882.jpeg",
    "https://images.pexels.com/photos/1054664/pexels-photo-1054664.jpeg",
  ];

  void _onBottomNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 2) {
      _showLogoutDialog();
    } else if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    } else if (index == 1) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DeletedMembersScreen(userId: user.uid)));
      }
    }
  }

  Future<void> _showLogoutDialog() async {
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
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TravShareHomeScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryColor,
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
        decoration: const BoxDecoration(color: Colors.white),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back,',
                      style: TextStyle(
                        color: primaryColor.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email?.split('@')[0] ?? 'Traveler',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Grid of tiles - smaller size
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _DashboardGlassCard(
                      icon: Icons.family_restroom_rounded,
                      label: 'Family Members',
                      subLabel: 'View list',
                      tileColor: primaryColor,
                      onTap: () {
                        _navigateTo(context, (userId) => FamilyMembersScreen(userId: userId));
                      },
                    ),
                    _DashboardGlassCard(
                      icon: Icons.description_rounded,
                      label: 'Your Docs',
                      subLabel: 'View & share',
                      tileColor: primaryColor,
                      onTap: () {
                        _navigateTo(context, (userId) => const YourDocsScreen());
                      },
                    ),
                    _DashboardGlassCard(
                      icon: Icons.create_new_folder_rounded,
                      label: 'Create Doc',
                      subLabel: 'Upload new',
                      tileColor: primaryColor,
                      onTap: () {
                        _navigateTo(context, (userId) => CreateDocumentUI(userId: userId));
                      },
                    ),
                    _DashboardGlassCard(
                      icon: Icons.person_add_rounded,
                      label: 'Add Family',
                      subLabel: 'New member',
                      tileColor: primaryColor,
                      onTap: () {
                        _navigateTo(context, (userId) => AddFamilyMemberScreen(userId: userId));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Carousel Slider Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Explore Destinations',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 3),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  viewportFraction: 0.85,
                ),
                items: travelImages.map((imageUrl) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey[600],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[400],
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_off_rounded),
            label: 'Deleted',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
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
            StreamBuilder<String?>(
              stream: user != null
                  ? ProfileService.profilePictureStream(user.uid)
                  : Stream.value(null),
              builder: (context, snapshot) {
                final profilePicturePath = snapshot.data;

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: themeProvider.primaryColor),
                  accountName: const Text(
                    'TripTation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  accountEmail: Text(user?.email ?? 'No Email'),
                  currentAccountPicture: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await showDialog(
                        context: context,
                        builder: (context) => ProfilePictureDialog(
                          currentImagePath: profilePicturePath,
                        ),
                      );
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
                      child: const Text('Log Out', style: TextStyle(color: Colors.red)),
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
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
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
  final Color tileColor;
  final VoidCallback? onTap;

  const _DashboardGlassCard({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.tileColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: tileColor.withOpacity(0.9),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: tileColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tileColor.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
