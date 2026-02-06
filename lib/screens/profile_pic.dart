import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_app/document_logic/image_upload.dart';
import 'package:travel_app/firebase_logic/profile_service.dart';

class ProfilePictureDialog extends StatefulWidget {
  final String? currentImagePath;

  const ProfilePictureDialog({super.key, this.currentImagePath});

  @override
  State<ProfilePictureDialog> createState() => _ProfilePictureDialogState();
}

class _ProfilePictureDialogState extends State<ProfilePictureDialog> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(BuildContext context, bool fromCamera) async {
    Navigator.pop(context); // Close bottom sheet

    setState(() {
      _isUploading = true;
    });

    final File? pickedFile = await ImagePickerService.pickImage(fromCamera: fromCamera);

    if (pickedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('User not logged in');
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final result = await ProfileService.updateProfilePicture(
        userId: user.uid,
        imageFile: pickedFile,
      );

      setState(() {
        _isUploading = false;
      });

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return success
        }
      } else {
        _showError(result['message']);
      }
    } else {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteProfilePicture() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isUploading = true;
      });

      final result = await ProfileService.deleteProfilePicture(userId: user.uid);

      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );

        if (result['success'] == true) {
          Navigator.pop(context, true);
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0047AB), Color(0xFF002E6D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () => _pickAndUploadImage(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () => _pickAndUploadImage(context, false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0047AB), Color(0xFF002E6D)], // Cobalt Blue Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Picture',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipOval(
                child: widget.currentImagePath != null && widget.currentImagePath!.isNotEmpty
                    ? Image.file(
                  File(widget.currentImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder();
                  },
                )
                    : _buildPlaceholder(),
              ),
            ),

            const SizedBox(height: 24),

            if (_isUploading)
              const CircularProgressIndicator(color: Colors.white)
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showImageSourceOptions,
                    icon: const Icon(Icons.upload),
                    label: Text(
                      widget.currentImagePath != null ? 'Change Picture' : 'Upload Picture',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  if (widget.currentImagePath != null && widget.currentImagePath!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _deleteProfilePicture,
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      label: const Text(
                        'Remove Picture',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }
}
