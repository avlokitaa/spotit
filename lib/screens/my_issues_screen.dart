import '../main.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Issue> _allIssues = [];
  List<Issue> _filteredIssues = [];
  bool _isLoading = true;
  bool _isInit = true; 
  
  // The Master Toggle
  bool _isCommunityView = true; 
  
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['ALL', 'REPORTED', 'IN-PROGRESS', 'RESOLVED', 'URGENT'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final arg = ModalRoute.of(context)?.settings.arguments as String?;
      if (arg == 'MY_REPORTS') {
        _isCommunityView = false;
        _selectedFilter = 'ALL';
      } else if (arg != null && _filters.contains(arg)) {
        _selectedFilter = arg;
        _isCommunityView = true; 
      }
      _isInit = false;
      _loadIssues();
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilters);
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    final list = await _firebaseService.getIssues();
    setState(() {
      _allIssues = list;
      _isLoading = false;
    });
    _applyFilters(); 
  }

  // --- THE SPLIT FILTER LOGIC ---
  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final currentUserId = _firebaseService.currentUser?.uid;

    setState(() {
      _filteredIssues = _allIssues.where((issue) {
        // 1. Split logic: Community vs My Reports
        if (!_isCommunityView && issue.reporterUid != currentUserId) return false;

        // 2. Search Box Logic
        final matchesSearch = issue.title.toLowerCase().contains(query) || (issue.address?.toLowerCase().contains(query) ?? false);
        if (!matchesSearch) return false;

        // 3. Status Pill Logic
        if (_selectedFilter == 'ALL') return true;
        if (_selectedFilter == 'URGENT') return issue.urgency.toLowerCase() == 'high';
        return issue.status.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return const Color(0xFFF59E0B);
      case 'in-progress': return const Color(0xFF3B82F6);
      case 'resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: url.startsWith('http') ? Image.network(url, fit: BoxFit.contain) : Image.file(File(url), fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _handleShare(Issue issue) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing "${issue.title}" to neighborhood group...'),
        backgroundColor: const Color(0xFF3B82F6),
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  // UPDATED: Now accepts theme tokens for dark mode
  Widget _buildToggleBtn(String label, IconData icon, bool isActive, bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () {
        setState(() => _isCommunityView = label == 'COMMUNITY');
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent, 
          borderRadius: BorderRadius.circular(100), 
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? textColor : const Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: isActive ? textColor : const Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  // UPDATED: Now accepts cardColor for dark mode backgrounds
  Widget _buildFilterPill(String label, Color cardColor) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : cardColor, 
          borderRadius: BorderRadius.circular(100), 
          boxShadow: [if (!isActive) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]
        ),
        child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: isActive ? Colors.white : const Color(0xFF94A3B8), letterSpacing: 0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- THIS WRAPS THE ENTIRE SCREEN TO LISTEN TO THE DARK MODE SWITCH ---
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;

        // --- DYNAMIC COLOR TOKENS ---
        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(onPressed: () => Navigator.pushReplacementNamed(context, '/home'), icon: Icon(LucideIcons.arrowLeft, color: textColor)),
                              Text(_isCommunityView ? 'COMMUNITY' : 'MY REPORTS', style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -1)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // THE VIEW TOGGLE
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(100), border: Border.all(color: borderColor)),
                            child: Row(
                              children: [
                                Expanded(child: _buildToggleBtn('COMMUNITY', LucideIcons.globe, _isCommunityView, isDark, textColor)),
                                Expanded(child: _buildToggleBtn('PERSONAL', LucideIcons.user, !_isCommunityView, isDark, textColor)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(100), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                                  child: TextField(
                                    controller: _searchController,
                                    style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(hintText: 'Search reports...', hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)), prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(children: _filters.map((f) => Padding(padding: const EdgeInsets.only(right: 12), child: _buildFilterPill(f, cardColor))).toList()),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                          : _filteredIssues.isEmpty
                              ? Center(child: Text(_isCommunityView ? 'No community reports match.' : 'You have no active reports.', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)))
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _filteredIssues.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                                  itemBuilder: (context, index) {
                                    final issue = _filteredIssues[index];
                                    final accentColor = _getStatusColor(issue.status);

                                    return GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/tracking', arguments: issue),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor),
                                          boxShadow: [BoxShadow(color: accentColor.withOpacity(isDark ? 0.3 : 1.0), offset: const Offset(-4, 6), blurRadius: 0)],
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 70, height: 70,
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor),
                                                image: issue.imageUrl != null 
                                                  ? DecorationImage(image: issue.imageUrl!.startsWith('http') ? NetworkImage(issue.imageUrl!) as ImageProvider : FileImage(File(issue.imageUrl!)), fit: BoxFit.cover) 
                                                  : null
                                              ),
                                              child: issue.imageUrl == null ? const Icon(LucideIcons.mapPin, size: 24, color: Color(0xFFCBD5E1)) : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(issue.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: textColor, height: 1.1)),
                                                  const SizedBox(height: 4),
                                                  
                                                  if (_isCommunityView) ...[
                                                    Text('Reported by ${issue.reporterName}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                                                    const SizedBox(height: 8),
                                                  ],

                                                  Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.mapPin, size: 10, color: Color(0xFF94A3B8))),
                                                      const SizedBox(width: 4),
                                                      Expanded(child: Text((issue.address ?? 'BANGALORE, KA').toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.5))),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  
                                                  if (_isCommunityView && issue.description.isNotEmpty) ...[
                                                    Text('"${issue.description}"', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFF64748B))),
                                                    const SizedBox(height: 12),
                                                  ],

                                                  if (issue.imageUrl != null) ...[
                                                    GestureDetector(
                                                      onTap: () => _showFullImage(issue.imageUrl!),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                        decoration: BoxDecoration(color: const Color(0xFFEFF6FF).withOpacity(isDark ? 0.1 : 1.0), borderRadius: BorderRadius.circular(8)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(LucideIcons.image, size: 12, color: Color(0xFF3B82F6)),
                                                            const SizedBox(width: 6),
                                                            Text('View Photo', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF3B82F6))),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                  ],
                                                  
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(100)), child: Text(issue.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5))),
                                                          const SizedBox(width: 8),
                                                          Text('${issue.urgency.toUpperCase()} PRIORITY', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 0.5)),
                                                        ],
                                                      ),
                                                      
                                                      if (_isCommunityView)
                                                        GestureDetector(
                                                          onTap: () => _handleShare(issue),
                                                          child: Container(
                                                            padding: const EdgeInsets.all(6),
                                                            decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                                                            child: const Icon(LucideIcons.share2, size: 14, color: Color(0xFF64748B)),
                                                          ),
                                                        )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
                
                // BOTTOM NAVIGATION BAR
                Positioned(
                  bottom: 24, left: 24, right: 24,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(35), border: Border.all(color: borderColor), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildNavItem(LucideIcons.home, 'HOME', false, () => Navigator.pushReplacementNamed(context, '/home'), textColor),
                        _buildNavItem(LucideIcons.plusCircle, 'REPORT', false, () => Navigator.pushReplacementNamed(context, '/report'), textColor),
                        _buildNavItem(LucideIcons.list, 'FEED', true, () {}, textColor), 
                        _buildNavItem(LucideIcons.map, 'MAP', false, () => Navigator.pushReplacementNamed(context, '/map'), textColor),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  // UPDATED: Accepts textColor
  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap, Color textColor) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? textColor : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: isActive ? textColor : const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}