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
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  String _selectedCategory = 'Waste';
  String _selectedUrgency = 'Medium';
  double _latitude = 12.9716;
  double _longitude = 77.5946;
  String _detectedAddress = 'Basavanagudi, Bangalore, KA';
  bool _fetchingLocation = false;
  bool _submitting = false;

  final List<String> _categories = ['Waste', 'Pothole', 'Water Leak', 'Fallen Tree', 'Other'];
  final List<String> _abcUrgency = ['Low', 'Medium', 'High'];

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
          _detectedAddress = 'Detected: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)} (GPS Active)';
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

    setState(() => _submitting = true);
    try {
      await FirebaseService().reportNewIssue(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        urgency: _selectedUrgency,
        latitude: _latitude,
        longitude: _longitude,
        address: _detectedAddress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hazard report successfully logged! Community and Firestore synchronized.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission failed. Check network or credentials.'),
            backgroundColor: Colors.redAccent,
          ),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'File Hazard Report',
          style: GoogleFonts.spaceGrotesk(color: const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hazard Details',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Title Text input
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Title of the Issue',
                          labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please offer a brief title' : null,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Detailed Description',
                          labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe the issue' : null,
                      ),
                      const SizedBox(height: 20),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(
                            value: cat,
                            child: Text(cat, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Urgency Selector
                      DropdownButtonFormField<String>(
                        initialValue: _selectedUrgency,
                        decoration: InputDecoration(
                          labelText: 'Report Urgency Level',
                          labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _abcUrgency.map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(u, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUrgency = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Location GPS feedback panel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'GPS Location Coordinates',
                            style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A)),
                          ),
                          if (_fetchingLocation)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF43F5E)))
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _detectedAddress,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _fetchingLocation ? null : _fetchLocationOnce,
                        icon: const Icon(LucideIcons.compass, size: 14),
                        label: Text('Fetch Fresh Coordinates', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800)),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          foregroundColor: const Color(0xFF0F172A),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Action Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Submit Report to Desk', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }
}
