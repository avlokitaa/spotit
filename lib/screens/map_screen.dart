import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Issue> _issues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    setState(() => _isLoading = true);
    // Fetch ALL issues from the database
    final list = await _firebaseService.getIssues();
    setState(() {
      _issues = list;
      _isLoading = false;
    });
  }

  // --- DYNAMIC STYLING ---
  Map<String, dynamic> _getCategoryStyle(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('waste') || cat.contains('garbage')) return {'emoji': '🗑️', 'color': Colors.amber.shade700};
    if (cat.contains('pothole') || cat.contains('road')) return {'emoji': '🕳️', 'color': const Color(0xFF0F172A)};
    if (cat.contains('tree') || cat.contains('green')) return {'emoji': '🌳', 'color': const Color(0xFF059669)};
    if (cat.contains('water') || cat.contains('leak')) return {'emoji': '💧', 'color': const Color(0xFF3B82F6)};
    if (cat.contains('light')) return {'emoji': '💡', 'color': const Color(0xFFF59E0B)};
    return {'emoji': '📍', 'color': const Color(0xFFF43F5E)};
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return const Color(0xFFF59E0B);
      case 'in-progress': return const Color(0xFF3B82F6);
      case 'resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  // --- BOTTOM SHEET PREVIEW ON PIN TAP ---
  void _showIssuePreview(Issue issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final style = _getCategoryStyle(issue.category);
        final statusColor = _getStatusColor(issue.status);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)),
                      image: issue.imageUrl != null 
                        ? DecorationImage(image: issue.imageUrl!.startsWith('http') ? NetworkImage(issue.imageUrl!) as ImageProvider : FileImage(File(issue.imageUrl!)), fit: BoxFit.cover) 
                        : null
                    ),
                    child: issue.imageUrl == null ? Center(child: Text(style['emoji'], style: const TextStyle(fontSize: 24))) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), height: 1.1)),
                        const SizedBox(height: 4),
                        Text('Reported by ${issue.reporterName}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(issue.address ?? 'Unknown Location', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(100)), child: Text(issue.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5))),
                  
                  // View Full Details Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.pushNamed(context, '/tracking', arguments: issue); // Go to tracking screen
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: Text('VIEW DETAILS', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                  )
                ],
              )
            ],
          ),
        );
      },
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
            // --- THE MAP ---
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(12.9716, 77.5946), // Bangalore Default
                      initialZoom: 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.spotit.app',
                      ),
                      MarkerLayer(
                        markers: _issues.where((i) => i.latitude != null && i.longitude != null).map((issue) {
                          final style = _getCategoryStyle(issue.category);
                          return Marker(
                            point: LatLng(issue.latitude!, issue.longitude!),
                            width: 44, height: 44,
                            child: GestureDetector(
                              onTap: () => _showIssuePreview(issue), // Open preview on tap!
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: style['color'], width: 3),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
                                ),
                                child: Center(child: Text(style['emoji'], style: const TextStyle(fontSize: 18))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

            // --- FLOATING HEADER ---
            Positioned(
              top: 16, left: 24, right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LIVE MAP', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                        Text('Community Reports', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)),
                      child: Text('${_issues.length} ISSUES', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981))),
                    )
                  ],
                ),
              ),
            ),

            // --- BOTTOM NAVIGATION BAR ---
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
                    _buildNavItem(LucideIcons.list, 'FEED', false, () => Navigator.pushReplacementNamed(context, '/my_issues')),
                    _buildNavItem(LucideIcons.map, 'MAP', true, () {}), // MAP is active!
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