import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/firebase_logic/fetchfamily.dart';
import 'package:travel_app/providers/theme_provider.dart';


class FamilyMembersScreen extends StatelessWidget {
  final String userId;

  const FamilyMembersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Family Members',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeProvider.primaryColor,
              themeProvider.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: FamilyCRUDService.getFamilyMembersStream(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading family members',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }

              final familyMembers = snapshot.data ?? [];

              if (familyMembers.isEmpty) {
                return const Center(
                  child: Text(
                    'No family members found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final member = familyMembers[index];
                          return _buildFamilyMemberTile(context, member);
                        },
                        childCount: familyMembers.length,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyMemberTile(BuildContext context, Map<String, dynamic> member) {
    // Replaced with Dismissible for swipe-to-delete or just a trailing delete icon for "Control"
    // User asked for "Control over creation and deleting"
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.purple.withOpacity(0.5),
          child: Text(
            member['name'] != null && member['name'].toString().isNotEmpty
                ? member['name'][0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          member['name'] ?? 'Unknown',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Age: ${member['age'] ?? 'N/A'} · Relation: ${member['relation'] ?? 'N/A'}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white70),
          onPressed: () => _confirmDelete(context, member['id']),
        ),
        onTap: () {
          // Future: Edit member details?
        },
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
              await FamilyCRUDService.deleteFamilyMember(userId: userId, memberId: memberId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
