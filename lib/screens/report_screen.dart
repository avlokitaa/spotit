import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
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
  
  double _latitude = 12.9063; // J.P. Nagar default
  double _longitude = 77.5857;
  String _detectedAddress = 'Auto detected using GPS';
  bool _fetchingLocation = false;
  bool _submitting = false;

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
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a description.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _submitting = true);
    try {
      await FirebaseService().reportNewIssue(
        title: '$_selectedCategory Reported in $_selectedWard',
        description: _descController.text.trim(),
        category: _selectedCategory,
        urgency: _selectedUrgency,
        latitude: _latitude,
        longitude: _longitude,
        address: _selectedWard, // Simplified for UI
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
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand, // Forces stack to fill screen, locking nav bar to bottom
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120), // Bottom padding protects against nav bar overlap
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
                            spacing: 12,
                            runSpacing: 12,
                            children: _categories.map((cat) {
                              final isSelected = _selectedCategory == cat['name'];
                              return GestureDetector(
                                onTap: () => setState(() => _selectedCategory = cat['name']!),
                                child: Container(
                                  width: (MediaQuery.of(context).size.width - 104) / 3, // Fits exactly 3 columns
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
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                                        ),
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
                                    value: _selectedWard,
                                    isExpanded: true,
                                    icon: const Icon(LucideIcons.chevronDown, size: 16),
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
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          u,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                          ),
                                        ),
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
                              controller: _descController,
                              maxLines: 4,
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Describe the issue...',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOCATION', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF10B981)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedWard, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Text(_fetchingLocation ? 'Fetching...' : _detectedAddress, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _fetchLocationOnce,
                                  child: Text('REFRESH', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 1)),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload Image Panel (Using solid border natively instead of requiring dotted_border package)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UPLOAD IMAGE', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1)),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E1), width: 2)),
                            child: Column(
                              children: [
                                Icon(LucideIcons.uploadCloud, size: 28, color: Color(0xFF64748B)),
                                const SizedBox(height: 12),
                                Text('Tap to Upload', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                const SizedBox(height: 4),
                                Text('Max Size: 5MB', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                              ],
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
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(35),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(LucideIcons.home, 'HOME', false, () => Navigator.pushReplacementNamed(context, '/home')),
                    _buildNavItem(LucideIcons.plusCircle, 'REPORT', true, () {}), // Active Tab
                    _buildNavItem(LucideIcons.list, 'MY ISSUES', false, () {}),
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