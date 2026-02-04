import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:travel_app/document_logic/expiration.dart';
import 'dart:io';
import 'package:travel_app/document_logic/image_upload.dart';
import 'package:travel_app/firebase_logic/fetchfamily.dart';
import 'package:provider/provider.dart';
import 'package:travel_app/providers/theme_provider.dart';
import 'package:travel_app/document_logic/save_document.dart';

class CreateDocumentUI extends StatefulWidget {
  final String userId;

  const CreateDocumentUI({super.key, required this.userId});

  @override
  State<CreateDocumentUI> createState() => _CreateDocumentUIState();
}

class _CreateDocumentUIState extends State<CreateDocumentUI> {
  final TextEditingController _documentNameController = TextEditingController();
  DateTime? _issueDate;
  DateTime? _expiryDate;
  File? _pickedImage;

  Map<String, dynamic>? _selectedMember;
  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoadingMembers = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _documentNameController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() {
      _isLoadingMembers = true;
    });

    final stream = FamilyCRUDService.getFamilyMembersStream(widget.userId);
    stream.listen((members) {
      if (mounted) {
        setState(() {
          _familyMembers = members;
          _isLoadingMembers = false;
        });
      }
    });
  }

  Future<void> _pickDate(BuildContext context, bool isIssueDate) async {
    final now = DateTime.now();
    final initialDate = isIssueDate ? (_issueDate ?? now) : (_expiryDate ?? now);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = pickedDate;
        } else {
          _expiryDate = pickedDate;
        }
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final source = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeProvider.primaryColor, themeProvider.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final File? pickedFile = await ImagePickerService.pickImage(fromCamera: source);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<void> _createDocument() async {
    // Validation
    if (_selectedMember == null) {
      _showError('Please select a family member');
      return;
    }
    if (_documentNameController.text.trim().isEmpty) {
      _showError('Please enter document name');
      return;
    }
    if (_issueDate == null) {
      _showError('Please select issue date');
      return;
    }
    if (_expiryDate == null) {
      _showError('Please select expiry date');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading document...\nThis may take a moment'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final result = await DocumentService.createDocument(
        userId: widget.userId,
        memberId: _selectedMember!['id'],
        memberName: _selectedMember!['name'],
        documentName: _documentNameController.text.trim(),
        holderName: _selectedMember!['name'],
        issueDate: _issueDate!,
        expiryDate: _expiryDate!,
        imageFile: _pickedImage,
      );

      setState(() {
        _isSaving = false;
      });

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (result == "Document created successfully") {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showError(result);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // Close progress dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showError('Error creating document: $e');
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [themeProvider.primaryColor, themeProvider.secondaryColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Create Document",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: gradientDecoration,
        child: SafeArea(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Document Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Family Member Selector
                        _FamilyMemberSelector(
                          isLoading: _isLoadingMembers,
                          members: _familyMembers,
                          selectedMember: _selectedMember,
                          onMemberSelected: (member) {
                            setState(() {
                              _selectedMember = member;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _InputField(
                          label: "Document Name",
                          hint: "e.g. Passport, CNIC",
                          icon: Icons.description_outlined,
                          controller: _documentNameController,
                        ),
                        const SizedBox(height: 16),

                        // Holder Name Display (Auto-filled from selected member)
                        _DisplayField(
                          label: "Holder Name",
                          value: _selectedMember?['name'] ?? 'Select a member first',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: _DatePickerField(
                                label: "Issue Date",
                                icon: Icons.calendar_today_outlined,
                                selectedDate: _issueDate,
                                onTap: () => _pickDate(context, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DatePickerField(
                                label: "Expiry Date",
                                icon: Icons.event_busy_outlined,
                                selectedDate: _expiryDate,
                                onTap: () => _pickDate(context, false),
                                statusText: _expiryDate != null
                                    ? ExpiryUtils.getStatus(_expiryDate!)
                                    : null,
                                statusColor: _expiryDate != null
                                    ? ExpiryUtils.getStatusColor(_expiryDate!)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          "Upload Image",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),

                        _UploadBox(
                          onTap: _pickAndUploadImage,
                        ),

                        if (_pickedImage != null) ...[
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _pickedImage!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _createDocument,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0047AB), // Cobalt Blue
                              disabledBackgroundColor: Colors.white.withOpacity(0.3),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0047AB)),
                              ),
                            )
                                : const Text(
                              "Create Document",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyMemberSelector extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? selectedMember;
  final Function(Map<String, dynamic>) onMemberSelected;

  const _FamilyMemberSelector({
    required this.isLoading,
    required this.members,
    required this.selectedMember,
    required this.onMemberSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Family Member",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          )
              : DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              value: selectedMember,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select a member',
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ),
              icon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.arrow_drop_down, color: Colors.white70),
              ),
              dropdownColor: const Color(0xFF2196F3),
              style: const TextStyle(color: Colors.white),
              items: members.map((member) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: member,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${member['name']} - ${member['relation']}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onMemberSelected(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DisplayField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DisplayField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController? controller;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final DateTime? selectedDate;
  final VoidCallback onTap;
  final String? statusText;
  final Color? statusColor;

  const _DatePickerField({
    required this.label,
    required this.icon,
    required this.selectedDate,
    required this.onTap,
    this.statusText,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        selectedDate != null
                            ? "${selectedDate!.day.toString().padLeft(2, '0')}-"
                            "${selectedDate!.month.toString().padLeft(2, '0')}-"
                            "${selectedDate!.year}"
                            : "Select",
                        style: TextStyle(
                          color: selectedDate != null ? Colors.white : Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (statusText != null && statusColor != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final VoidCallback? onTap;
  const _UploadBox({this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Tap to upload image",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "JPG, PNG up to 5MB",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}