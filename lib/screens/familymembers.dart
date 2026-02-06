import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/firebase_logic/fetchfamily.dart';
import 'package:travel_app/providers/theme_provider.dart';
import 'package:travel_app/widgets/graphical_elements.dart';
import 'dart:ui';

class FamilyMembersScreen extends StatelessWidget {
  final String userId;

  const FamilyMembersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Family Members',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: 0.5,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      themeProvider.primaryColor.withOpacity(0.7),
                      themeProvider.primaryColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedBlob(
            color: themeProvider.primaryColor.withOpacity(0.08),
            offset: const Offset(-100, 100),
            size: 300,
          ),
          AnimatedBlob(
            color: themeProvider.secondaryColor.withOpacity(0.08),
            offset: const Offset(200, 500),
            size: 400,
          ),
          Container(
            color: Colors.white.withOpacity(0.6),
          ),
          SafeArea(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: FamilyCRUDService.getFamilyMembersStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: themeProvider.primaryColor),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading family members',
                      style: TextStyle(color: themeProvider.primaryColor),
                    ),
                  );
                }

                final familyMembers = snapshot.data ?? [];

                if (familyMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 80, color: themeProvider.primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No family members found',
                          style: TextStyle(color: themeProvider.primaryColor.withOpacity(0.7), fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: familyMembers.length,
                  itemBuilder: (context, index) {
                    final member = familyMembers[index];
                    return EntranceFader(
                      delay: 100 * index,
                      child: _buildFamilyMemberTile(context, member, themeProvider.primaryColor),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberTile(
      BuildContext context, Map<String, dynamic> member, Color primaryColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.85),
                primaryColor.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member['name'] != null && member['name'].toString().isNotEmpty
                      ? member['name'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            ),
            title: Text(
              member['name'] ?? 'Unknown',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              'Age: ${member['age'] ?? 'N/A'} · Relation: ${member['relation'] ?? 'N/A'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _confirmDelete(context, member['id']),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String? memberId) {
    if (memberId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: const Text('Are you sure you want to remove this family member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FamilyCRUDService.deleteFamilyMember(
                userId: userId,
                memberId: memberId,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
