import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // <-- Added Map
import 'package:latlong2/latlong.dart'; // <-- Added Coordinates
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  
  String _selectedCategory = 'POTHOLE';
  String _selectedUrgency = 'MEDIUM';
  String _selectedWard = 'J.P. Nagar';
  
  double _latitude = 12.9063;
  double _longitude = 77.5857;
  String _detectedAddress = 'Auto detected using GPS';
  bool _fetchingLocation = false;
  bool _submitting = false;
  
  File? _selectedImage; 

  final List<Map<String, String>> _categories = [
    {'name': 'GARBAGE', 'icon': '🗑️'},
    {'name': 'POTHOLE', 'icon': '🕳️'},
    {'name': 'FALLEN TREE', 'icon': '🌳'},
    {'name': 'WATER LEAK', 'icon': '💧'},
    {'name': 'STREET LIGHT', 'icon': '💡'},
    {'name': 'DRAINAGE', 'icon': '🌀'},
    {'name': 'MISCELLANEOUS', 'icon': '✨'},
  ];

  final List<String> _wards = ['J.P. Nagar', 'Basavanagudi', 'Koramangala', 'Indiranagar', 'Whitefield'];
  final List<String> _urgencies = ['LOW', 'MEDIUM', 'HIGH'];

  final Map<String, Map<String, double>> _wardCenterCoordinates = {
    'J.P. Nagar': {'lat': 12.9063, 'lng': 77.5857},
    'Basavanagudi': {'lat': 12.9408, 'lng': 77.5641},
    'Koramangala': {'lat': 12.9345, 'lng': 77.6214},
    'Indiranagar': {'lat': 12.9783, 'lng': 77.6408},
    'Whitefield': {'lat': 12.9698, 'lng': 77.7500},
  };

  @override
  void initState() {
    super.initState();
    _fetchLocationOnce();
  }

  Future<void> _fetchLocationOnce() async {
    setState(() => _fetchingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          _detectedAddress = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      print('Incident report address failed: $e');
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _generateAIFill() {
    String generatedText = '';
    switch (_selectedCategory) {
      case 'GARBAGE': generatedText = 'There is a large accumulation of uncollected garbage spilling onto the walkway, causing a severe hygiene issue and foul odor. Needs immediate clearing.'; break;
      case 'POTHOLE': generatedText = 'A deep and dangerous pothole has developed in the middle of the road, posing a severe hazard to two-wheelers and damaging vehicles. Requires urgent patching.'; break;
      case 'FALLEN TREE': generatedText = 'A large tree has fallen across the road, completely blocking traffic and pulling down nearby overhead wires. Needs clearing to restore access.'; break;
      case 'WATER LEAK': generatedText = 'A main water pipe has burst, wasting hundreds of liters of clean water and flooding the adjacent street. Please dispatch a repair team.'; break;
      case 'STREET LIGHT': generatedText = 'The streetlights on this stretch have been non-functional for several days, making the area pitch dark and unsafe for pedestrians at night.'; break;
      case 'DRAINAGE': generatedText = 'The open drain is severely clogged with plastic and debris, causing sewage water to overflow onto the main road and creating a health hazard.'; break;
      default: generatedText = 'There is a civic issue at this location that is causing inconvenience to the public. It requires immediate inspection and resolution from the concerned authorities.';
    }

    setState(() => _descController.text = generatedText);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Description Generated!'), backgroundColor: Color(0xFF10B981)));
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a description.'), backgroundColor: Colors.redAccent));
      return;
    }

    final wardCenter = _wardCenterCoordinates[_selectedWard];
    if (wardCenter != null) {
      double distanceInMeters = Geolocator.distanceBetween(_latitude, _longitude, wardCenter['lat']!, wardCenter['lng']!);
      if (distanceInMeters > 2000) {
        _showLocationMismatchDialog(wardCenter['lat']!, wardCenter['lng']!);
        return; 
      }
    }

    _executeSubmission();
  }

  void _showLocationMismatchDialog(double wardLat, double wardLng) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Color(0xFFF59E0B), size: 24), const SizedBox(width: 12),
              Text('Location Mismatch', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 20)),
            ],
          ),
          content: Text('Your active GPS tracking shows you are far from $_selectedWard. Do you want to use the Ward center coordinates, keep your physical GPS location, or drop a pin manually?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.map, size: 14), label: Text('USE WARD CENTER COORDS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  onPressed: () {
                    setState(() { _latitude = wardLat; _longitude = wardLng; _detectedAddress = 'Set to $_selectedWard Center'; });
                    Navigator.pop(ctx);
                    _executeSubmission();
                  },
                ),
                const SizedBox(height: 8),
                // UPDATED: Now triggers the Map Selection Dialog!
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.mapPin, size: 14), label: Text('PIN ON MAP', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFFE2E8F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () { Navigator.pop(ctx); _showMapSelectionDialog(); },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () { Navigator.pop(ctx); _executeSubmission(); },
                  child: Text('FORCE KEEP CURRENT DEVICE GPS', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  // --- NEW INTERACTIVE MAP PIN DIALOG ---
  void _showMapSelectionDialog() {
    LatLng tempLocation = LatLng(_latitude, _longitude);

    showDialog(
      context: context, barrierDismissible: false,
      builder: (BuildContext ctx) {
        // StatefulBuilder is required here so the marker updates instantly when you tap!
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pin Location on Map', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('Tap anywhere on the map to drop the pin.', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: tempLocation,
                      initialZoom: 14.0,
                      onTap: (tapPosition, point) {
                        setStateSB(() => tempLocation = point); // Updates the pin location
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.spotit.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: tempLocation,
                            width: 40, height: 40,
                            child: const Icon(LucideIcons.mapPin, color: Color(0xFFF43F5E), size: 36),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    setState(() { 
                      _latitude = tempLocation.latitude; 
                      _longitude = tempLocation.longitude; 
                      _detectedAddress = 'Manually Pinned on Map'; 
                    });
                    Navigator.pop(ctx);
                    _executeSubmission(); // Proceed with submission!
                  },
                  child: Text('SAVE & SUBMIT', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
                )
              ],
            );
          }
        );
      },
    );
  }

  void _executeSubmission() async {
    setState(() => _submitting = true);
    try {
      await FirebaseService().reportNewIssue(
        title: '$_selectedCategory Reported in $_selectedWard',
        description: _descController.text.trim(),
        category: _selectedCategory,
        urgency: _selectedUrgency,
        latitude: _latitude,
        longitude: _longitude,
        address: _selectedWard,
        imageUrl: _selectedImage?.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report successfully logged!'), backgroundColor: Color(0xFF10B981)));
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission failed.'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
                          style: IconButton.styleFrom(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0)))),
                        ),
                        const SizedBox(width: 16),
                        Text('Report a Civic Issue', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // PERFECTLY CENTERED CATEGORY GRID
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('SELECT CATEGORY', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12, runSpacing: 12,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat['name'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat['name']!),
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 65) / 3,
                                  height: 90, 
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9), width: 2),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(cat['icon']!, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(height: 8),
                                      Text(
                                        cat['name']!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A), height: 1.1),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ward and Severity Row 
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('WARD', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                                const SizedBox(height: 12),
                                Container(
                                  height: 34,
                                  alignment: Alignment.centerLeft,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedWard, isExpanded: true, icon: const Icon(LucideIcons.chevronDown, size: 16),
                                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                      onChanged: (v) => setState(() => _selectedWard = v!),
                                      items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SEVERITY', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: _urgencies.map((u) {
                                      final isSelected = _selectedUrgency == u;
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedUrgency = u),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                              boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(u, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF94A3B8))),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description with functional AI FILL Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('DESCRIPTION', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                              GestureDetector(
                                onTap: _generateAIFill, 
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(100)),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.sparkles, size: 12, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text('AI FILL', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                            child: TextFormField(
                              controller: _descController, maxLines: 4,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Describe the issue...', hintStyle: TextStyle(color: Color(0xFF94A3B8))),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Image Panel
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UPLOAD EVIDENCE', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 16),
                          
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: double.infinity,
                              height: 140, 
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                                image: _selectedImage != null 
                                  ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover) 
                                  : null
                              ),
                              child: _selectedImage == null 
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.camera, size: 28, color: Color(0xFF64748B)),
                                      const SizedBox(height: 12),
                                      Text('Tap to Upload Photo', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                      const SizedBox(height: 4),
                                      Text('Max Size: 5MB', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                                    ],
                                  ) 
                                : Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(4), 
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), 
                                        child: const Icon(LucideIcons.x, color: Colors.white, size: 16)
                                      ),
                                      onPressed: () => setState(() => _selectedImage = null),
                                    ),
                                  ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _handleSubmit,
                        icon: _submitting ? const SizedBox.shrink() : const Icon(LucideIcons.send, size: 18),
                        label: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('SUBMIT REPORT', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Nav 
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Container(
                height: 70,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(35), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(LucideIcons.home, 'HOME', false, () => Navigator.pushReplacementNamed(context, '/home')),
                    _buildNavItem(LucideIcons.plusCircle, 'REPORT', true, () {}),
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