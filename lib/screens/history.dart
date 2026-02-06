import 'package:provider/provider.dart';
import 'package:travel_app/providers/theme_provider.dart';
import 'package:travel_app/document_logic/save_document.dart';
import 'package:travel_app/widgets/graphical_elements.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.primaryColor;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please log in to view history',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

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
                'Document History',
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
                      primaryColor.withOpacity(0.7),
                      primaryColor.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedBlob(
            color: primaryColor.withOpacity(0.08),
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
            child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DocumentService.getAllUserDocuments(userId: user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading history',
                    style: TextStyle(color: primaryColor, fontSize: 16),
                  ),
                );
              }

              final documents = snapshot.data ?? [];

              if (documents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents yet',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.7),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Documents you create will appear here',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group documents by date
              final groupedDocs = _groupDocumentsByDate(documents);

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: groupedDocs.length,
                itemBuilder: (context, index) {
                  final dateKey = groupedDocs.keys.elementAt(index);
                  final docsForDate = groupedDocs[dateKey]!;

                  return EntranceFader(
                    delay: 100 * index,
                    child: _DateGroup(
                      dateLabel: dateKey,
                      documents: docsForDate,
                    ),
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

  Map<String, List<Map<String, dynamic>>> _groupDocumentsByDate(
      List<Map<String, dynamic>> documents) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in documents) {
      final createdAt = doc['createdAtParsed'] as DateTime?;
      if (createdAt != null) {
        final dateKey = _getDateLabel(createdAt);
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(doc);
      }
    }

    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final docDate = DateTime(date.year, date.month, date.day);

    if (docDate == today) {
      return 'Today';
    } else if (docDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }
}

class _DateGroup extends StatelessWidget {
  final String dateLabel;
  final List<Map<String, dynamic>> documents;

  const _DateGroup({
    required this.dateLabel,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            dateLabel,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...documents.map((doc) => _DocumentHistoryCard(document: doc)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DocumentHistoryCard extends StatelessWidget {
  final Map<String, dynamic> document;

  const _DocumentHistoryCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final documentName = document['documentName'] ?? 'Untitled';
    final holderName = document['holderName'] ?? 'Unknown';
    final memberName = document['memberName'] ?? 'Unknown';
    final imagePath = document['imagePath'];
    final createdAt = document['createdAtParsed'] as DateTime?;
    final expiryDate = document['expiryDateParsed'] as DateTime?;

    final timeString = createdAt != null
        ? DateFormat('hh:mm a').format(createdAt)
        : 'Unknown time';

    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;

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
          child: InkWell(
            onTap: () => _showDocumentDetails(context),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Document Image or Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imagePath != null && imagePath.isNotEmpty
                          ? Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.description,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 35,
                                );
                              },
                            )
                          : Icon(
                              Icons.description,
                              color: Colors.white.withOpacity(0.8),
                              size: 35,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Document Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          documentName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                holderName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeString,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expiry Badge
                  if (expiryDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: DocumentService.getExpiryStatusColor(expiryDate).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        DocumentService.getExpiryStatus(expiryDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetails(BuildContext context) {
    final expiryDate = document['expiryDateParsed'] as DateTime?;
    final issueDate = document['issueDateParsed'] as DateTime?;
    final memberName = document['memberName'] ?? 'Unknown';
    final documentName = document['documentName'] ?? 'Untitled';
    final holderName = document['holderName'] ?? 'Unknown';
    final imagePath = document['imagePath'];
    final createdAt = document['createdAtParsed'] as DateTime?;

    final primaryColor =
        Provider.of<ThemeProvider>(context, listen: false).primaryColor;
    final secondaryColor =
        Provider.of<ThemeProvider>(context, listen: false).secondaryColor;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Document Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (imagePath != null && imagePath.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(imagePath),
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.white.withOpacity(0.1),
                            child: const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.white, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  _DetailRow(label: 'Document Name', value: documentName),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Holder Name', value: holderName),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Family Member', value: memberName),
                  const SizedBox(height: 12),

                  if (createdAt != null) ...[
                    _DetailRow(
                      label: 'Created On',
                      value:
                      DateFormat('MMMM dd, yyyy · hh:mm a').format(createdAt),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (issueDate != null) ...[
                    _DetailRow(
                      label: 'Issue Date',
                      value: DateFormat('MMMM dd, yyyy').format(issueDate),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (expiryDate != null) ...[
                    _DetailRow(
                      label: 'Expiry Date',
                      value: DateFormat('MMMM dd, yyyy').format(expiryDate),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: DocumentService.getExpiryStatusColor(expiryDate)
                                .withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            DocumentService.getExpiryStatus(expiryDate),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Days remaining: ${DocumentService.daysLeft(expiryDate)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
