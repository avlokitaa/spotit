import 'dart:io';
import 'package:flutter/material.dart';
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
  
  File? _selectedImage; // Holds the chosen image!
  // Hardcoded central coordinates for your ward selections
  final Map<String, Map<String, double>> _wardCenterCoordinates = {
    'J.P. Nagar': {'lat': 12.9063, 'lng': 77.5857},
    'Basavanagudi': {'lat': 12.9408, 'lng': 77.5641},
    'Koramangala': {'lat': 12.9345, 'lng': 77.6214},
    'Indiranagar': {'lat': 12.9783, 'lng': 77.6408},
    'Whitefield': {'lat': 12.9698, 'lng': 77.7500},
  };

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

  // --- IMAGE PICKER LOGIC ---
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a description.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Check distance between current GPS position and selected Ward Center
    final wardCenter = _wardCenterCoordinates[_selectedWard];
    if (wardCenter != null) {
      double distanceInMeters = Geolocator.distanceBetween(
        _latitude,
        _longitude,
        wardCenter['lat']!,
        wardCenter['lng']!,
      );

      // If mismatch is greater than 2000 meters (2 KM), trigger the warning gate
      if (distanceInMeters > 2000) {
        _showLocationMismatchDialog(wardCenter['lat']!, wardCenter['lng']!);
        return; // Intercepts and pauses submission sequence
      }
    }

    // If coordinates match closely, proceed directly to cloud sync
    _executeSubmission();
  }

  // --- THE MISMATCH INTERCEPTION DIALOG ---
  void _showLocationMismatchDialog(double wardLat, double wardLng) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 12),
              Text(
                'Location Mismatch',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), fontSize: 20),
              ),
            ],
          ),
          content: Text(
            'Your active GPS tracking shows you are far from $_selectedWard. Do you want to use the Ward center coordinates, keep your physical GPS location, or input the position coordinates manually?',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B), height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Option 1: Snap directly to the Ward Center
                ElevatedButton.icon(
                  icon: const Icon(LucideIcons.map, size: 14),
                  label: Text('USE WARD CENTER COORDS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  onPressed: () {
                    setState(() {
                      _latitude = wardLat;
                      _longitude = wardLng;
                      _detectedAddress = 'Set to $_selectedWard Center';
                    });
                    Navigator.pop(ctx);
                    _executeSubmission();
                  },
                ),
                const SizedBox(height: 8),
                // Option 2: Force Manual Coordinate entry field
                OutlinedButton.icon(
                  icon: const Icon(LucideIcons.edit2, size: 14),
                  label: Text('ENTER MANUALLY', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFFE2E8F0)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showManualLocationDialog();
                  },
                ),
                const SizedBox(height: 8),
                // Option 3: Force original device coordinates anyway
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _executeSubmission();
                  },
                  child: Text(
                    'FORCE KEEP CURRENT DEVICE GPS',
                    style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  // --- SUB-DIALOG FOR MANUAL ENTRY ---
  void _showManualLocationDialog() {
    final TextEditingController latController = TextEditingController(text: _latitude.toStringAsFixed(4));
    final TextEditingController lngController = TextEditingController(text: _longitude.toStringAsFixed(4));

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Manual Coordinates',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: latController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lngController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                decoration: InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                double? parsedLat = double.tryParse(latController.text);
                double? parsedLng = double.tryParse(lngController.text);
                if (parsedLat != null && parsedLng != null) {
                  setState(() {
                    _latitude = parsedLat;
                    _longitude = parsedLng;
                    _detectedAddress = 'Manually Entered Position';
                  });
                  Navigator.pop(ctx);
                  _executeSubmission();
                }
              },
              child: Text('SAVE & SUBMIT', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
            )
          ],
        );
      },
    );
  }

  // --- ACTUAL FIRESTORE WRITE ACTIONS ---
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report successfully logged!'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed.'), backgroundColor: Colors.redAccent),
        );
      }
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

                    // Category Grid Panel
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SELECT CATEGORY', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12, runSpacing: 12,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat['name'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat['name']!),
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 104) / 3,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF1F5F9), width: 2),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(cat['icon']!, style: const TextStyle(fontSize: 24)),
                                      const SizedBox(height: 8),
                                      Text(
                                        cat['name']!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A)),
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
                                const SizedBox(height: 8),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedWard, isExpanded: true, icon: const Icon(LucideIcons.chevronDown, size: 16),
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                                    onChanged: (v) => setState(() => _selectedWard = v!),
                                    items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: _urgencies.map((u) {
                                    final isSelected = _selectedUrgency == u;
                                    return GestureDetector(
                                      onTap: () => setState(() => _selectedUrgency = u),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: isSelected ? const Color(0xFF10B981) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                                        child: Text(u, style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : const Color(0xFF94A3B8))),
                                      ),
                                    );
                                  }).toList(),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('DESCRIPTION', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                              Row(
                                children: [
                                  const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  Text('AI FILL', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1)),
                                ],
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

                    // Upload Image Panel (UPDATED WITH PREVIEW)
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
                              height: 140, // Fixed height for nice visual box
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                                // Display image if it exists!
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
                                      onPressed: () => setState(() => _selectedImage = null), // Remove image
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