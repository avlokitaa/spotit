import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  bool _isMapView = false; 

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

  // --- FULL SCREEN IMAGE VIEWER ---
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

  // --- CONFIRMATION DIALOG ---
  void _confirmStatusChange(Issue issue, String newStatus, String label, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Update', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
        content: Text('Are you sure you want to change the status of this issue to $label?', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              setState(() => _isLoading = true);
              await _firebaseService.updateIssueStatus(issue.id, newStatus);
              _loadFeed();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $label'), backgroundColor: color));
            },
            child: Text('CONFIRM', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  // --- DELETE CONFIRMATION ---
  void _confirmDelete(Issue issue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Report?', style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF43F5E), fontWeight: FontWeight.w900)),
        content: Text('This action is permanent and cannot be undone.', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              setState(() => _isLoading = true);
              await _firebaseService.deleteIssue(issue.id);
              _loadFeed();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted.'), backgroundColor: Color(0xFFF43F5E)));
            },
            child: Text('DELETE', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  // --- UNIVERSAL ACTION SHEET ---
  void _showAdminActionSheet(Issue issue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)), side: BorderSide(color: Color(0xFF1E293B), width: 2)),
      builder: (context) {
        // Allows scrolling if the content (like a large image) gets too tall
        return DraggableScrollableSheet(
          initialChildSize: 0.85, 
          minChildSize: 0.5, 
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2)))),
                  
                  // NEW: PHOTOGRAPHIC EVIDENCE PREVIEW
                  if (issue.imageUrl != null) ...[
                    Text('EVIDENCE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF64748B), letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _showFullImage(issue.imageUrl!),
                      child: Container(
                        width: double.infinity,
                        height: 180, // Large, clear preview
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1E293B), width: 2),
                          image: DecorationImage(
                            image: issue.imageUrl!.startsWith('http') 
                                ? NetworkImage(issue.imageUrl!) as ImageProvider
                                : FileImage(File(issue.imageUrl!)),
                            fit: BoxFit.cover,
                          )
                        ),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.maximize2, size: 12, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text('Tap to expand', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Issue Details Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.title, style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Filer: ${issue.reporterName}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))), 
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _getStatusColor(issue.status).withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                        child: Text(issue.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: _getStatusColor(issue.status))),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Description
                  if (issue.description != null && issue.description!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        '"${issue.description!}"',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text('UPDATE STATUS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF64748B), letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  // Status Options
                  _buildStatusOption(issue, 'reported', 'Pending', const Color(0xFFF59E0B), LucideIcons.clock),
                  _buildStatusOption(issue, 'in-progress', 'In Progress', const Color(0xFF3B82F6), LucideIcons.hammer),
                  _buildStatusOption(issue, 'resolved', 'Resolved', const Color(0xFF10B981), LucideIcons.checkCircle),
                  
                  const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Color(0xFF1E293B))),
                  
                  // Danger Zone
                  Text('DANGER ZONE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFF43F5E), letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(LucideIcons.trash2, color: Color(0xFFF43F5E)),
                    title: Text('Delete Report', style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFFF43F5E))),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: const Color(0xFFF43F5E).withOpacity(0.1),
                    onTap: () => _confirmDelete(issue),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusOption(Issue issue, String statusValue, String label, Color color, IconData icon) {
    final isCurrent = issue.status == statusValue;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      trailing: isCurrent ? Icon(LucideIcons.check, color: color) : null,
      onTap: isCurrent ? null : () => _confirmStatusChange(issue, statusValue, label, color),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return const Color(0xFFF59E0B);
      case 'in-progress': return const Color(0xFF3B82F6);
      case 'resolved': return const Color(0xFF10B981);
      default: return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // FIXED ADMIN HEADER WITH TOGGLE
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF0F172A), border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 2))),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('COMMAND CENTER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF64748B), letterSpacing: 2)),
                          Text('Admin Dashboard', style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () async {
                          await _firebaseService.logout();
                          if (mounted) Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(100)),
                          child: Text('LOGOUT', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFF43F5E))),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  // List / Map Toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(100)),
                    child: Row(
                      children: [
                        Expanded(child: _buildToggleBtn('LIST VIEW', LucideIcons.list, !_isMapView)),
                        Expanded(child: _buildToggleBtn('MAP VIEW', LucideIcons.map, _isMapView)),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // DYNAMIC BODY (List or Map)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : _isMapView
                      ? _buildAdminMap()
                      : _buildAdminList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _isMapView = label == 'MAP VIEW'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isActive ? const Color(0xFF334155) : Colors.transparent, borderRadius: BorderRadius.circular(100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isActive ? Colors.white : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: isActive ? Colors.white : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  // --- LIST VIEW UI ---
  Widget _buildAdminList() {
    if (_issues.isEmpty) return const Center(child: Text('No reports in system.', style: TextStyle(color: Colors.white)));
    
    return RefreshIndicator(
      onRefresh: _loadFeed,
      color: const Color(0xFF10B981),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _issues.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final issue = _issues[index];
          final sColor = _getStatusColor(issue.status);

          return GestureDetector(
            onTap: () => _showAdminActionSheet(issue),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF334155))),
              child: Row(
                children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('Filer: ${issue.reporterName}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                            if (issue.imageUrl != null) ...[
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.image, size: 12, color: Color(0xFF64748B)),
                            ]
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.settings, size: 18, color: Color(0xFF64748B)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- MAP VIEW UI ---
  Widget _buildAdminMap() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(12.9716, 77.5946), // Bangalore Default
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', 
          userAgentPackageName: 'com.spotit.app',
        ),
        MarkerLayer(
          markers: _issues.where((i) => i.latitude != null && i.longitude != null).map((issue) {
            final sColor = _getStatusColor(issue.status);
            return Marker(
              point: LatLng(issue.latitude!, issue.longitude!),
              width: 40, height: 40,
              child: GestureDetector(
                onTap: () => _showAdminActionSheet(issue),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A), shape: BoxShape.circle,
                    border: Border.all(color: sColor, width: 3),
                    boxShadow: [BoxShadow(color: sColor.withOpacity(0.5), blurRadius: 10)],
                  ),
                  child: const Icon(LucideIcons.alertCircle, color: Colors.white, size: 20),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}