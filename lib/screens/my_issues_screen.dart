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
  bool _isInit = true; // Protects the route listener
  
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();

  // Added URGENT to the pills
  final List<String> _filters = ['ALL', 'REPORTED', 'IN-PROGRESS', 'RESOLVED', 'URGENT'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Catch the filter command from the Home Screen stat cards!
    if (_isInit) {
      final arg = ModalRoute.of(context)?.settings.arguments as String?;
      if (arg != null && _filters.contains(arg)) {
        _selectedFilter = arg;
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
    _applyFilters(); // Apply immediately after fetching
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredIssues = _allIssues.where((issue) {
        final matchesSearch = issue.title.toLowerCase().contains(query) || (issue.address?.toLowerCase().contains(query) ?? false);
        
        bool matchesFilter;
        if (_selectedFilter == 'ALL') {
          matchesFilter = true;
        } else if (_selectedFilter == 'URGENT') {
          matchesFilter = issue.urgency.toLowerCase() == 'high';
        } else {
          matchesFilter = issue.status.toLowerCase() == _selectedFilter.toLowerCase();
        }
        
        return matchesSearch && matchesFilter;
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
          child: url.startsWith('http') 
              ? Image.network(url, fit: BoxFit.contain)
              : Image.file(File(url), fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    final isActive = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [if (!isActive) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w900, color: isActive ? Colors.white : const Color(0xFF94A3B8), letterSpacing: 0.5)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.arrowLeft)),
                          Text('MY REPORTS', style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -1)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(hintText: 'Search reports...', hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)), prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF94A3B8)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(children: _filters.map((f) => Padding(padding: const EdgeInsets.only(right: 12), child: _buildFilterPill(f))).toList()),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                      : _filteredIssues.isEmpty
                          ? Center(child: Text('No reports match your filters.', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w500)))
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
                                      color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)),
                                      boxShadow: [BoxShadow(color: accentColor, offset: const Offset(-4, 6), blurRadius: 0)],
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 70, height: 70,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                            image: issue.imageUrl != null 
                                              ? DecorationImage(
                                                  image: issue.imageUrl!.startsWith('http') 
                                                    ? NetworkImage(issue.imageUrl!) as ImageProvider
                                                    : FileImage(File(issue.imageUrl!)),
                                                  fit: BoxFit.cover,
                                                ) 
                                              : null
                                          ),
                                          child: issue.imageUrl == null ? const Icon(LucideIcons.mapPin, size: 24, color: Color(0xFFCBD5E1)) : null,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(issue.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), height: 1.1)),
                                              const SizedBox(height: 8),
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Padding(padding: EdgeInsets.only(top: 2), child: Icon(LucideIcons.mapPin, size: 10, color: Color(0xFF94A3B8))),
                                                  const SizedBox(width: 4),
                                                  Expanded(child: Text((issue.address ?? 'BANGALORE, KA').toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF94A3B8), letterSpacing: 0.5))),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              if (issue.imageUrl != null) ...[
                                                GestureDetector(
                                                  onTap: () => _showFullImage(issue.imageUrl!),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
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
                                                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(100)), child: Text(issue.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5))),
                                                  Text('${issue.urgency.toUpperCase()} PRIORITY', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 0.5))
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
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Container(
                height: 70,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(LucideIcons.home, 'HOME', false, () => Navigator.pushReplacementNamed(context, '/home')),
                    _buildNavItem(LucideIcons.plusCircle, 'REPORT', false, () => Navigator.pushReplacementNamed(context, '/report')),
                    _buildNavItem(LucideIcons.list, 'MY ISSUES', true, () {}),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}