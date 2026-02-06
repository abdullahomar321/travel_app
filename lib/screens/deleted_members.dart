import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/firebase_logic/fetchfamily.dart';
import 'package:travel_app/providers/theme_provider.dart';

class DeletedMembersScreen extends StatelessWidget {
  final String userId;
  const DeletedMembersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Members', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FamilyCRUDService.getDeletedFamilyMembersStream(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
            }

            final deletedMembers = snapshot.data ?? [];

            if (deletedMembers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off_rounded, size: 80, color: primaryColor.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No Deleted Members',
                      style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recently removed family members will show up here.',
                      style: TextStyle(color: primaryColor.withOpacity(0.5), fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: deletedMembers.length,
              itemBuilder: (context, index) {
                final member = deletedMembers[index];
                return _buildDeletedMemberTile(context, member, primaryColor);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDeletedMemberTile(BuildContext context, Map<String, dynamic> member, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Text(
            member['name'] != null ? member['name'][0].toUpperCase() : '?',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          member['name'] ?? 'Unknown',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Relation: ${member['relation'] ?? 'N/A'}'),
        trailing: IconButton(
          icon: const Icon(Icons.restore_rounded, color: Colors.green),
          onPressed: () => _restoreMember(context, member['id']),
          tooltip: 'Restore Member',
        ),
      ),
    );
  }

  void _restoreMember(BuildContext context, String? memberId) async {
    if (memberId == null) return;
    await FamilyCRUDService.restoreFamilyMember(userId: userId, memberId: memberId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member restored!')),
      );
    }
  }
}
