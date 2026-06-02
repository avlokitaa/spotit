import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  // 1. Changed to nullable and removed immediate instantiation to prevent the late init crash loop
  MapController? _mapController;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Issue> _issues = [];
  bool _isLoadingMap = true;
  bool _locatingGps = false;
  LatLng _mapCenter = const LatLng(12.9716, 77.5946); // Bangalore center default
  LatLng? _userCurrentLocation;
  String _currentAddress = 'Basavanagudi, Bangalore';
  Issue? _selectedIssue;

  @override
  void initState() {
    super.initState();
    _loadIssues();
    _startDeviceGpsSync();
  }

  // 2. Clear controller reference when screen destroys
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
    setState(() {
      _locatingGps = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );

        final pin = LatLng(position.latitude, position.longitude);

        setState(() {
          _userCurrentLocation = pin;
          _mapCenter = pin;
          _isLoadingMap = false;
        });

        // 3. Added a safety guard: Only pan the camera if the controller is attached to a mounted map layout
        if (_mapController != null) {
          _mapController!.move(pin, 14.0);
        }

        _reverseGeocode(position.latitude, position.longitude);
      } else {
        setState(() {
          _isLoadingMap = false;
          _locatingGps = false;
        });
      }
    } catch (e) {
      print('GPS Pinpoint failed safely handled: $e');
      setState(() {
        _isLoadingMap = false;
        _locatingGps = false;
      });
    }
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    try {
      final res = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addressMap = data['address'] as Map<String, dynamic>?;
        if (addressMap != null) {
          final String localName = addressMap['suburb'] ??
              addressMap['neighbourhood'] ??
              addressMap['road'] ??
              addressMap['city_district'] ??
              addressMap['city'] ??
              '$lat, $lon';
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

  Widget _getMarkerWidget(String category) {
    final cat = category.toLowerCase();
    String emoji = '📍';
    Color circleColor = Colors.red;

    if (cat.contains('waste') || cat.contains('garbage')) {
      emoji = '🗑️';
      circleColor = Colors.amber.shade700;
    } else if (cat.contains('pothole') || cat.contains('road') || cat.contains('street')) {
      emoji = '🚧';
      circleColor = Colors.yellow.shade800;
    } else if (cat.contains('tree') || cat.contains('green') || cat.contains('fallen')) {
      emoji = '🌳';
      circleColor = const Color(0xFF059669);
    } else if (cat.contains('water') || cat.contains('leak') || cat.contains('drain')) {
      emoji = '💧';
      circleColor = Colors.blue.shade600;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: circleColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: circleColor.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoadingMap
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFF43F5E)))
              : FlutterMap(
                  // 4. Leave mapController null here during initial setup build phase
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 14.0,
                    onTap: (_, __) {
                      setState(() {
                        _selectedIssue = null;
                      });
                    },
                    // 5. Secure Initialization: Instantiate and bind controller ONLY when the canvas map reports ready!
                    onMapReady: () {
                      _mapController = MapController();
                      // If GPS located the spot before map loaded, update it instantly now
                      if (_userCurrentLocation != null) {
                        _mapController!.move(_userCurrentLocation!, 14.0);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Cleaned subdomains to fix socket reset crashes
                      userAgentPackageName: 'com.spotit.app',
                    ),
                    
                    if (_userCurrentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userCurrentLocation!,
                            width: 32,
                            height: 32,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),

                    MarkerLayer(
                      markers: _issues
                          .where((issue) => issue.latitude != null && issue.longitude != null)
                          .map(
                            (issue) => Marker(
                              point: LatLng(issue.latitude!, issue.longitude!),
                              width: 36,
                              height: 36,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIssue = issue;
                                  });
                                  // Safe check mapController wrap
                                  if (_mapController != null) {
                                    _mapController!.move(
                                        LatLng(issue.latitude! - 0.0035, issue.longitude!), 14.0);
                                  }
                                },
                                child: _getMarkerWidget(issue.category),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),

          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _locatingGps ? 'SYNCING PHYSICAL GPS POSITION...' : 'CURRENT LOCATION',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFFF43F5E)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _currentAddress,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowRight, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF8FAFC),
                      padding: const EdgeInsets.all(8),
                    ),
                  )
                ],
              ),
            ),
          ),

          Positioned(
            bottom: _selectedIssue != null ? 220 : 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: _startDeviceGpsSync,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                LucideIcons.compass,
                color: _locatingGps ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
              ),
            ),
          ),

          if (_selectedIssue != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedIssue!.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedIssue = null;
                            });
                          },
                          icon: const Icon(LucideIcons.x, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedIssue!.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, size: 14, color: Color(0xFFF43F5E)),
                            const SizedBox(width: 6),
                            Text(
                              '${_selectedIssue!.urgency} Urgency',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            )
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/home'); 
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                          child: Text(
                            'Track Status',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}