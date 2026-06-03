import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/issue.dart';
import '../services/firebase_service.dart';
import '../main.dart'; 

class IssueTrackingScreen extends StatefulWidget {
  const IssueTrackingScreen({super.key});

  @override
  State<IssueTrackingScreen> createState() => _IssueTrackingScreenState();
}

class _IssueTrackingScreenState extends State<IssueTrackingScreen> {
  Issue? _issue;
  bool _isUpdating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Issue) {
      _issue = arg;
    }
  }

  // --- DYNAMIC VISUAL HELPERS ---
  Map<String, dynamic> _getCategoryStyle(String category, bool isDark) {
    final cat = category.toLowerCase();
    if (cat.contains('waste') || cat.contains('garbage')) return {'emoji': '🗑️', 'color': Colors.amber.shade700, 'bg': isDark ? const Color(0xFF422006) : const Color(0xFFFEF9C3)};
    if (cat.contains('pothole') || cat.contains('road')) return {'emoji': '🕳️', 'color': isDark ? Colors.white : const Color(0xFF0F172A), 'bg': isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)};
    if (cat.contains('tree') || cat.contains('green')) return {'emoji': '🚧', 'color': const Color(0xFF059669), 'bg': isDark ? const Color(0xFF064E3B) : const Color(0xFFFEF3C7)};
    if (cat.contains('water') || cat.contains('leak')) return {'emoji': '💧', 'color': const Color(0xFF3B82F6), 'bg': isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF)};
    if (cat.contains('light')) return {'emoji': '💡', 'color': const Color(0xFFF59E0B), 'bg': isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)};
    return {'emoji': '📍', 'color': const Color(0xFFF43F5E), 'bg': isDark ? const Color(0xFF881337) : const Color(0xFFFFE4E6)};
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return const Color(0xFFF97316); 
      case 'in-progress': return const Color(0xFF3B82F6);
      case 'resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    String hour = date.hour > 12 ? '${date.hour - 12}' : '${date.hour}';
    if (hour == '0') hour = '12';
    String min = date.minute.toString().padLeft(2, '0');
    String ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year}, $hour:$min $ampm';
  }

  String _getShortId(String fullId) {
    return fullId.replaceAll('issue_', '').substring(0, 6).toUpperCase();
  }

  void _updateStatus(String newStatus) async {
    if (_issue == null) return;
    setState(() => _isUpdating = true);
    try {
      await FirebaseService().updateIssueStatus(_issue!.id, newStatus);
      setState(() => _issue!.status = newStatus); 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $newStatus!'), backgroundColor: const Color(0xFF10B981)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status.'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // --- NEW: INTERACTIVE FULL-SCREEN IMAGE VIEWER ---
  void _showFullImage() {
    if (_issue?.imageUrl == null) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _issue!.imageUrl!.startsWith('http') 
                  ? Image.network(_issue!.imageUrl!, fit: BoxFit.contain) 
                  : Image.file(File(_issue!.imageUrl!), fit: BoxFit.contain),
            ),
            Positioned(
              top: 0, right: 0,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20)
                ),
                onPressed: () => Navigator.pop(ctx),
              )
            )
          ]
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_issue == null) return const Scaffold(body: Center(child: Text('Issue not found.')));

    final currentUser = FirebaseService().currentUser;
    final isAdmin = currentUser?.role == 'admin';

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;

        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        final statusColor = _getStatusColor(_issue!.status);
        final style = _getCategoryStyle(_issue!.category, isDark);

        int currentStep = 1;
        if (_issue!.status.toLowerCase() == 'in-progress') currentStep = 3; 
        if (_issue!.status.toLowerCase() == 'resolved') currentStep = 4;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: textColor),
                style: IconButton.styleFrom(backgroundColor: cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor))),
                onPressed: () => Navigator.pop(context)
              ),
            ),
            title: Text('My Reports', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
            centerTitle: false,
            titleSpacing: 16,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  
                  // --- TOP SUMMARY CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(16)),
                              alignment: Alignment.center,
                              child: Text(style['emoji'], style: const TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_issue!.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, height: 1.1)),
                                  const SizedBox(height: 6),
                                  Text(_issue!.address ?? 'Unknown Location', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                              child: Text(_issue!.status == 'reported' ? 'PENDING' : _issue!.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5)),
                            )
                          ],
                        ),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Divider(color: borderColor)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REPORT ID:', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: mutedColor)),
                                const SizedBox(height: 4),
                                Text('#${_getShortId(_issue!.id)}', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('FILED ON:', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: mutedColor)),
                                const SizedBox(height: 4),
                                Text(_formatDate(_issue!.createdAt), style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- INTERACTIVE PROGRESS TIMELINE ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROGRESS TIMELINE', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1)),
                        const SizedBox(height: 24),
                        
                        _buildTimelineStep(step: 1, currentStep: currentStep, title: 'Report Submitted', subtitle: 'Filer logged the issue with GPS evidence.', isLast: false, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor),
                        _buildTimelineStep(step: 2, currentStep: currentStep, title: 'Acknowledged by Authority', subtitle: 'Civic engineer assigned the case.', isLast: false, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor),
                        _buildTimelineStep(step: 3, currentStep: currentStep, title: 'Field Inspector Scheduled', subtitle: 'Team dispatched to investigate site.', isLast: false, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor),
                        _buildTimelineStep(step: 4, currentStep: currentStep, title: 'Issue Resolved', subtitle: 'Repair successfully executed and closed.', isLast: true, textColor: textColor, mutedColor: mutedColor, borderColor: borderColor),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Text('*Upon completion of the task you will be notified on your app.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: mutedColor)),
                  ),

                  // --- ENHANCED DETAILS CARD WITH EVIDENCE IMAGE ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DETAILS', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 1)),
                        const SizedBox(height: 12),
                        Text(_issue!.description, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: textColor, height: 1.5)),
                        
                        const SizedBox(height: 24),
                        Text('ATTACHED EVIDENCE', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: mutedColor, letterSpacing: 1)),
                        const SizedBox(height: 12),

                        if (_issue!.imageUrl != null) 
                          GestureDetector(
                            onTap: _showFullImage,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _issue!.imageUrl!.startsWith('http') 
                                      ? Image.network(_issue!.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover) 
                                      : Image.file(File(_issue!.imageUrl!), height: 180, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  bottom: 12, right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                                    child: const Icon(LucideIcons.maximize2, color: Colors.white, size: 16),
                                  ),
                                )
                              ]
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.imageOff, size: 28, color: mutedColor.withOpacity(0.5)),
                                const SizedBox(height: 8),
                                Text('No evidence photo provided', style: GoogleFonts.inter(fontSize: 12, color: mutedColor, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- ADMIN CONTROLS ---
                  if (isAdmin) ...[
                    const SizedBox(height: 32),
                    Text('Admin Controls', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFFF43F5E))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdating || _issue!.status.toLowerCase() == 'in-progress' ? null : () => _updateStatus('in-progress'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: Text('MARK IN-PROGRESS', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUpdating || _issue!.status.toLowerCase() == 'resolved' ? null : () => _updateStatus('resolved'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            child: Text('MARK RESOLVED', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                          ),
                        ),
                      ],
                    )
                  ]
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  // --- INTERACTIVE TIMELINE STEP WIDGET ---
  Widget _buildTimelineStep({required int step, required int currentStep, required String title, required String subtitle, required bool isLast, required Color textColor, required Color mutedColor, required Color borderColor}) {
    bool isCompleted = step < currentStep;
    bool isCurrent = step == currentStep;
    
    if (step == 4 && currentStep == 4) {
      isCompleted = true;
      isCurrent = false;
    }

    Color iconBgColor = (isCompleted || isCurrent) ? const Color(0xFF3B82F6) : borderColor;
    
    Widget icon;
    if (isCompleted) {
      icon = const Icon(LucideIcons.check, size: 12, color: Colors.white);
    } else if (isCurrent) {
      icon = const Icon(LucideIcons.arrowRight, size: 12, color: Colors.white);
    } else {
      iconBgColor = borderColor;
      final innerColor = themeNotifier.value == ThemeMode.dark ? const Color(0xFF1E293B) : Colors.white;
      icon = Container(width: 10, height: 10, decoration: BoxDecoration(color: innerColor, shape: BoxShape.circle));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: icon,
            ),
            if (!isLast)
              Container(width: 2, height: 44, color: borderColor),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w900, color: (isCompleted || isCurrent) ? const Color(0xFF3B82F6) : mutedColor)),
              const SizedBox(height: 4),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: mutedColor)),
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}