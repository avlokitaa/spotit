import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Issue> _issues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllIssues();
  }

  Future<void> _loadAllIssues() async {
    setState(() => _isLoading = true);
    final data = await _firebaseService.getIssues();
    setState(() {
      _issues = data;
      _isLoading = false;
    });
  }

  void _updateStatus(String id, String status) async {
    await _firebaseService.updateIssueStatus(id, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status update logged to Firestore: ${status.toUpperCase()}'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    _loadAllIssues();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Admin Desk Control',
          style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E)))
            : _issues.isEmpty
                ? Center(
                    child: Text('No active local reports to manage', style: GoogleFonts.inter(color: Colors.grey)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _issues.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final issue = _issues[index];
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    issue.category.toUpperCase(),
                                    style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blue),
                                  ),
                                ),
                                Text(
                                  _getDateString(issue.createdAt),
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              issue.title,
                              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              issue.description,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            
                            // Mutator Dropdowns Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Current: ${issue.status.toUpperCase()}',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (issue.status != 'in-progress')
                                      OutlinedButton(
                                        onPressed: () => _updateStatus(issue.id, 'in-progress'),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text('Investigate', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800)),
                                      ),
                                    if (issue.status != 'resolved')
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(issue.id, 'resolved'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          elevation: 0,
                                        ),
                                        child: Text('Resolve', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800)),
                                      ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _getDateString(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
