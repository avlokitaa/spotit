import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Issue> _issues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    final list = await _firebaseService.getIssues();
    setState(() {
      _issues = list;
      _isLoading = false;
    });
  }

  // --- DYNAMIC VISUAL HELPERS ---
  Map<String, dynamic> _getCategoryStyle(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('waste') || cat.contains('garbage')) return {'emoji': '🗑️', 'color': Colors.amber.shade700, 'bg': const Color(0xFFFEF9C3)};
    if (cat.contains('pothole') || cat.contains('road')) return {'emoji': '🕳️', 'color': const Color(0xFF0F172A), 'bg': const Color(0xFFF1F5F9)};
    if (cat.contains('tree') || cat.contains('green')) return {'emoji': '🌳', 'color': const Color(0xFF059669), 'bg': const Color(0xFFECFDF5)};
    if (cat.contains('water') || cat.contains('leak')) return {'emoji': '💧', 'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)};
    if (cat.contains('light')) return {'emoji': '💡', 'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFEF3C7)};
    return {'emoji': '📍', 'color': const Color(0xFFF43F5E), 'bg': const Color(0xFFFFE4E6)};
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return const Color(0xFFF59E0B);
      case 'in-progress': return const Color(0xFF3B82F6);
      case 'resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  // Added onTap action parameter
  Widget _buildStatCard(String value, String label, Color valueColor, Widget icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Makes the card clickable!
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: valueColor)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.5)),
                  icon,
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    // --- DYNAMIC DATABASE CALCULATIONS ---
    final int totalCount = _issues.length;
    final int resolvedCount = _issues.where((i) => i.status.toLowerCase() == 'resolved').length;
    final int pendingCount = _issues.where((i) => i.status.toLowerCase() == 'reported' || i.status.toLowerCase() == 'in-progress').length;
    final int urgentCount = _issues.where((i) => i.urgency.toLowerCase() == 'high').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RefreshIndicator(
              onRefresh: _loadFeed,
              color: const Color(0xFFF43F5E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // TOP LOCATION HEADER
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('LOCATION', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                              Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text('BANGALORE, KA', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                ],
                              )
                            ],
                          ),
                          Row(
                            children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF1F5F9))), child: const Icon(LucideIcons.bell, size: 18, color: Color(0xFF64748B))),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/profile'),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, border: Border.all(color: const Color(0xFF10B981), width: 2),
                                    image: DecorationImage(image: NetworkImage(user?.photoURL ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=123'), fit: BoxFit.cover),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2x2 DYNAMIC STATS GRID (Routing with filter arguments!)
                    Row(
                      children: [
                        _buildStatCard(totalCount.toString(), 'TOTAL REPORTS', const Color(0xFF0F172A), const Text('📊', style: TextStyle(fontSize: 16)), () => Navigator.pushNamed(context, '/my_issues', arguments: 'ALL')),
                        const SizedBox(width: 16),
                        _buildStatCard(resolvedCount.toString(), 'RESOLVED', const Color(0xFF10B981), Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.check, size: 12, color: Color(0xFF10B981))), () => Navigator.pushNamed(context, '/my_issues', arguments: 'RESOLVED')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(pendingCount.toString(), 'PENDING', const Color(0xFFF59E0B), const Text('⏳', style: TextStyle(fontSize: 16)), () => Navigator.pushNamed(context, '/my_issues', arguments: 'REPORTED')),
                        const SizedBox(width: 16),
                        _buildStatCard(urgentCount.toString(), 'URGENT', const Color(0xFFF43F5E), const Text('🔥', style: TextStyle(fontSize: 16)), () => Navigator.pushNamed(context, '/my_issues', arguments: 'URGENT')),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // RECENT REPORTS HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Reports', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/my_issues', arguments: 'ALL'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Text('SEE ALL →', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF10B981))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // REPORTS LIST
                    _isLoading
                        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF10B981))))
                        : _issues.isEmpty
                            ? const Padding(padding: EdgeInsets.all(24), child: Text('No reports yet.'))
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _issues.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final issue = _issues[index];
                                  final style = _getCategoryStyle(issue.category); 
                                  final statusColor = _getStatusColor(issue.status); 

                                  return GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, '/tracking', arguments: issue),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 50, height: 50,
                                            decoration: BoxDecoration(color: style['bg'], borderRadius: BorderRadius.circular(16)),
                                            alignment: Alignment.center,
                                            child: Text(style['emoji'], style: const TextStyle(fontSize: 24)),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                                const SizedBox(height: 4),
                                                Text(issue.address ?? 'Bangalore, KA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                                            child: Text(issue.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor)),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),
            
            // BOTTOM NAVIGATION BAR
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Container(
                height: 70,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(LucideIcons.home, 'HOME', true, () {}),
                    _buildNavItem(LucideIcons.plusCircle, 'REPORT', false, () => Navigator.pushReplacementNamed(context, '/report')),
                    _buildNavItem(LucideIcons.list, 'MY ISSUES', false, () => Navigator.pushReplacementNamed(context, '/my_issues')),
                    _buildNavItem(LucideIcons.map, 'MAP', false, () => Navigator.pushReplacementNamed(context, '/map')),
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