import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Issue> _issues = [];
  bool _isLoadingMap = true;
  bool _locatingGps = false;
  LatLng _mapCenter = const LatLng(12.9063, 77.5857); // Default
  LatLng? _userCurrentLocation;
  String _currentAddress = 'Auto detected using GPS';
  Issue? _selectedIssue;

  @override
  void initState() {
    super.initState();
    _loadIssues();
    _startDeviceGpsSync();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadIssues() async {
    final data = await _firebaseService.getIssues();
    setState(() {
      _issues = data;
    });
  }

  Future<void> _startDeviceGpsSync() async {
    setState(() => _locatingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final pin = LatLng(position.latitude, position.longitude);

        setState(() {
          _userCurrentLocation = pin;
          _mapCenter = pin;
          _isLoadingMap = false;
        });

        if (_mapController != null) {
          _mapController!.move(pin, 15.0);
        }

        _reverseGeocode(position.latitude, position.longitude);
      } else {
        setState(() { _isLoadingMap = false; _locatingGps = false; });
      }
    } catch (e) {
      print('GPS Pinpoint failed: $e');
      setState(() { _isLoadingMap = false; _locatingGps = false; });
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final res = await http.get(Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addressMap = data['address'] as Map<String, dynamic>?;
        if (addressMap != null) {
          final String localName = addressMap['suburb'] ?? addressMap['neighbourhood'] ?? addressMap['road'] ?? addressMap['city_district'] ?? addressMap['city'] ?? '$lat, $lon';
          setState(() {
            _currentAddress = localName;
            _locatingGps = false;
          });
          return;
        }
      }
    } catch (e) {
      print('OSM Nominatim Reverse geocoding failed: $e');
    }
    setState(() {
      _currentAddress = '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
      _locatingGps = false;
    });
  }

  // Visual Helper Methods
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

  int _getProgressStep(String status) {
    switch (status.toLowerCase()) {
      case 'reported': return 1;
      case 'assigned': return 2;
      case 'in-progress': return 3;
      case 'resolved': return 4;
      default: return 1;
    }
  }

  Widget _getMarkerWidget(String category) {
    final style = _getCategoryStyle(category);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, shape: BoxShape.circle,
        border: Border.all(color: style['color'], width: 2),
        boxShadow: [BoxShadow(color: style['color'].withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(4),
      child: Text(style['emoji'], style: const TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    final bottomPadding = _selectedIssue != null ? 360.0 : 120.0; // Dynamic padding for floating elements

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. THE MAP LAYER
            _isLoadingMap
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _mapCenter,
                      initialZoom: 15.0,
                      onTap: (_, __) => setState(() => _selectedIssue = null),
                      onMapReady: () {
                        _mapController = MapController();
                        if (_userCurrentLocation != null) _mapController!.move(_userCurrentLocation!, 15.0);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.spotit.app',
                      ),
                      if (_userCurrentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _userCurrentLocation!,
                              width: 32, height: 32,
                              child: Container(
                                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), shape: BoxShape.circle),
                                child: Center(child: Container(width: 14, height: 14, decoration: BoxDecoration(color: const Color(0xFF3B82F6), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                              ),
                            )
                          ],
                        ),
                      MarkerLayer(
                        markers: _issues.where((i) => i.latitude != null && i.longitude != null).map((issue) {
                          return Marker(
                            point: LatLng(issue.latitude!, issue.longitude!),
                            width: 36, height: 36,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedIssue = issue);
                                if (_mapController != null) {
                                  _mapController!.move(LatLng(issue.latitude! - 0.002, issue.longitude!), 16.0); // Offset down slightly to fit card
                                }
                              },
                              child: _getMarkerWidget(issue.category),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

            // 2. TOP LOCATION HEADER
            Positioned(
              top: 16, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOCATION', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(_currentAddress.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF1F5F9))), child: const Icon(LucideIcons.bell, size: 18, color: Color(0xFF64748B))),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF10B981), width: 2), image: DecorationImage(image: NetworkImage(user?.photoURL ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=123'), fit: BoxFit.cover)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),

            // 3. MAP LEGEND PILL
            Positioned(
              bottom: bottomPadding, left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Row(
                  children: [
                    _buildLegendItem(Colors.redAccent, 'WATER'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.blue, 'TREE'),
                    const SizedBox(width: 12),
                    _buildLegendItem(Colors.amber, 'GARBAGE'),
                  ],
                ),
              ),
            ),

            // 4. GPS RECENTER BUTTON
            Positioned(
              bottom: bottomPadding, right: 20,
              child: FloatingActionButton(
                onPressed: _startDeviceGpsSync,
                backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F172A),
                elevation: 4, shape: const CircleBorder(),
                child: Icon(LucideIcons.compass, color: _locatingGps ? const Color(0xFFF43F5E) : const Color(0xFF10B981)),
              ),
            ),

            // 5. SELECTED ISSUE BOTTOM SHEET (From image_39b5dd.png)
            if (_selectedIssue != null)
              Positioned(
                bottom: 104, left: 20, right: 20, // Sits exactly above the nav bar
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                      Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(color: _getCategoryStyle(_selectedIssue!.category)['bg'], borderRadius: BorderRadius.circular(16)),
                            alignment: Alignment.center,
                            child: Text(_getCategoryStyle(_selectedIssue!.category)['emoji'], style: const TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedIssue!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text('Report ID: #${_selectedIssue!.id.substring(0, 6).toUpperCase()}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: _getStatusColor(_selectedIssue!.status).withOpacity(0.1), borderRadius: BorderRadius.circular(100)),
                            child: Text(_selectedIssue!.status.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: _getStatusColor(_selectedIssue!.status))),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _selectedIssue = null),
                            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFF1F5F9))), child: const Icon(LucideIcons.x, size: 14)),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Info Pills
                      Row(
                        children: [
                          _buildInfoPill(_selectedIssue!.category.toUpperCase()),
                          const SizedBox(width: 8),
                          _buildInfoPill('FILED ${DateFormat('MMM d').format(_selectedIssue!.createdAt).toUpperCase()}', icon: LucideIcons.calendar),
                          const SizedBox(width: 8),
                          _buildInfoPill('${_selectedIssue!.urgency.toUpperCase()} URGENCY', bgColor: const Color(0xFFFEF3C7), textColor: const Color(0xFFD97706)),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: Color(0xFFF1F5F9), height: 1)),
                      
                      // Progress Bar Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PROGRESS', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                          Text('STEP ${_getProgressStep(_selectedIssue!.status)} OF 4', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildHorizontalProgress(_getProgressStep(_selectedIssue!.status)),
                      const SizedBox(height: 24),

                      // Action Button
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/tracking', arguments: _selectedIssue),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                          child: Text('VIEW FULL DETAILS →', style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            // 6. FLOATING BOTTOM NAVIGATION BAR
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
                    _buildNavItem(LucideIcons.home, 'HOME', false, () => Navigator.pushReplacementNamed(context, '/home')),
                    _buildNavItem(LucideIcons.plusCircle, 'REPORT', false, () => Navigator.pushReplacementNamed(context, '/report')),
                    _buildNavItem(LucideIcons.list, 'MY ISSUES', false, () => Navigator.pushReplacementNamed(context, '/my_issues')),
                    _buildNavItem(LucideIcons.map, 'MAP', true, () {}), // ACTIVE
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Small UI Builder Helpers
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildInfoPill(String text, {IconData? icon, Color bgColor = Colors.white, Color textColor = const Color(0xFF64748B)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(100), border: bgColor == Colors.white ? Border.all(color: const Color(0xFFF1F5F9)) : null),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: textColor), const SizedBox(width: 4)],
          Text(text, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildHorizontalProgress(int activeStep) {
    return Row(
      children: [
        _buildProgressNode('SUBMITTED', 1, activeStep),
        _buildProgressLine(2, activeStep),
        _buildProgressNode('ACKNOWLEDGED', 2, activeStep),
        _buildProgressLine(3, activeStep),
        _buildProgressNode('INSPECTOR', 3, activeStep),
        _buildProgressLine(4, activeStep),
        _buildProgressNode('RESOLVED', 4, activeStep),
      ],
    );
  }

  Widget _buildProgressNode(String label, int step, int activeStep) {
    bool isActive = step <= activeStep;
    return Column(
      children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: isActive ? Colors.white : const Color(0xFFF1F5F9), shape: BoxShape.circle, border: Border.all(color: isActive ? const Color(0xFF10B981) : const Color(0xFFE2E8F0), width: 4)),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 7, fontWeight: FontWeight.w900, color: isActive ? const Color(0xFF0F172A) : const Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildProgressLine(int step, int activeStep) {
    bool isActive = step <= activeStep;
    return Expanded(
      child: Container(
        height: 4, margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(2)),
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