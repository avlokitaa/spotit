import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/issue.dart';

class IssueTrackingScreen extends StatelessWidget {
  const IssueTrackingScreen({super.key});

  Widget _buildTimelineStep(String title, String subtitle, bool isActive, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: isActive 
                  ? const Icon(LucideIcons.arrowRight, size: 12, color: Colors.white)
                  : Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: const Color(0xFFF1F5F9)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Read the issue passed from the home screen
    final issue = ModalRoute.of(context)!.settings.arguments as Issue;
    final dateFormatted = DateFormat('MMM d, yyyy, hh:mm a').format(issue.createdAt).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.arrowLeft),
                        style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0)))),
                      ),
                      const SizedBox(width: 16),
                      Text('My Reports', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ISSUE SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(color: const Color(0xFFFEF9C3), borderRadius: BorderRadius.circular(16)),
                              alignment: Alignment.center,
                              child: const Text('🚧', style: TextStyle(fontSize: 28)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(issue.title, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  Text(issue.address ?? 'Bangalore, KA', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(100)),
                              child: Text('PENDING', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFEA580C))),
                            )
                          ],
                        ),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFFF1F5F9))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('REPORT ID:', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8))),
                                Text('#ISSUE', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FILED ON:', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8))),
                                Text(dateFormatted, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // PROGRESS TIMELINE CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROGRESS TIMELINE', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: 1)),
                        const SizedBox(height: 24),
                        _buildTimelineStep('Report Submitted', 'Filer logged the issue with GPS evidence.', true, false),
                        _buildTimelineStep('Acknowledged by Authority', 'Civic engineer assigned the case.', false, false),
                        _buildTimelineStep('Field Inspector Scheduled', 'Team dispatched to investigate site.', false, false),
                        _buildTimelineStep('Issue Resolved', 'Repair successfully executed and closed.', false, true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // NOTIFICATION BANNER
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                    child: Text('*Upon completion of the task you will be notified on your app.', textAlign: TextAlign.center, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF64748B))),
                  ),
                  const SizedBox(height: 16),

                  // DETAILS CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DETAILS', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(issue.description, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ACTIONS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.messageSquare, size: 16),
                          label: Text('NOTIFY ME', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: const Icon(LucideIcons.share2, size: 20, color: Color(0xFF0F172A)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            
            // BOTTOM NAV
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Container(
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(35),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(LucideIcons.home, 'HOME', false, () => Navigator.pop(context)),
                    _buildNavItem(LucideIcons.plusCircle, 'REPORT', false, () {}),
                    _buildNavItem(LucideIcons.list, 'MY ISSUES', true, () {}), // Active state
                    _buildNavItem(LucideIcons.map, 'MAP', false, () {}),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}