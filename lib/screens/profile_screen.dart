import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/sparkle_overlay.dart'; 
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingNeighbors = false;

  // Mutable state variables for editing!
  String _phoneNumber = '+91 98765 43210';
  String _dateOfBirth = '24 August, 2002';
  String _userWard = 'J.P. Nagar'; 

  void _handleLogout() async {
    await _firebaseService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // --- EDIT INFORMATION DIALOG ---
  void _showEditDialog(String title, String currentValue, Function(String) onSave) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        content: TextField(
          controller: controller,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title updated!'), backgroundColor: const Color(0xFF10B981)));
            },
            child: Text('SAVE', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  // --- NEIGHBORHOOD QUERY FUNCTION ---
  void _viewNeighborReports() async {
    setState(() => _isLoadingNeighbors = true);
    
    final allIssues = await _firebaseService.getIssues();
    final neighborIssues = allIssues.where((issue) => 
      (issue.address ?? '').toLowerCase().contains(_userWard.toLowerCase())
    ).toList();

    setState(() => _isLoadingNeighbors = false);

    if (mounted) {
      _showNeighborhoodSheet(neighborIssues);
    }
  }

  void _showNeighborhoodSheet(List<Issue> issues) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF8FAFC),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7, minChildSize: 0.4, maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.users, color: Color(0xFF10B981))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Neighborhood Network', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                            Text('Live reports in $_userWard', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: issues.isEmpty
                      ? Center(child: Text('Your neighborhood is currently clear!', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))))
                      : ListView.separated(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: issues.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final issue = issues[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                        Text('Reported by ${issue.reporterName}', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF10B981), fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  const Icon(LucideIcons.chevronRight, size: 16, color: Color(0xFFCBD5E1))
                                ],
                              ),
                            );
                          },
                        ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SECURITY ACTIONS ---
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Update Password', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        content: TextField(
          obscureText: true,
          decoration: InputDecoration(hintText: 'Enter new password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated securely.'), backgroundColor: Color(0xFF10B981)));
            },
            child: Text('SAVE', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account?', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: const Color(0xFFF43F5E))),
        content: Text('This action will permanently erase your profile and all your reports from SpotIt. This cannot be undone.', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF43F5E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await _firebaseService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: Text('DELETE PERMANENTLY', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
          )
        ],
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
    );
  }

  Widget _buildEditableInfoField(String label, String value, IconData icon, VoidCallback onEditTap) {
    return GestureDetector(
      onTap: onEditTap, // Triggers the edit dialog
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC), shape: BoxShape.circle),
              child: const Icon(LucideIcons.pencil, size: 14, color: Color(0xFF10B981)), // Emphasized pencil icon
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, {bool isDestructive = false, bool isLoading = false}) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDestructive ? const Color(0xFFFECDD3) : const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDestructive ? const Color(0xFFFFE4E6) : color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: isDestructive ? const Color(0xFFE11D48) : const Color(0xFF0F172A))),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: isDestructive ? const Color(0xFFFDA4AF) : const Color(0xFF94A3B8))),
                ],
              ),
            ),
            isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)))
              : Icon(LucideIcons.chevronRight, size: 18, color: isDestructive ? const Color(0xFFFDA4AF) : const Color(0xFFCBD5E1))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC), elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)), onPressed: () => Navigator.pop(context)),
        title: Text('Account Profile', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER (Avatar + Basic Info)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF10B981), width: 3), image: DecorationImage(image: NetworkImage(user?.photoURL ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=guest'), fit: BoxFit.cover)),
                    ),
                    const SizedBox(height: 16),
                    Text(user?.displayName ?? 'Resident', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(100)), child: Text('VERIFIED USER', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 0.5))),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 1. MY INFORMATION (Now Editable!)
              _buildSectionTitle('MY INFORMATION'),
              // Email is read-only since it's the login credential
              Container(
                margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    const Icon(LucideIcons.mail, size: 18, color: Color(0xFF94A3B8)), const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Email Address (Unchangeable)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))), const SizedBox(height: 2), Text(user?.email ?? 'No email linked', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF64748B)))]),
                  ],
                ),
              ),
              _buildEditableInfoField('Phone Number', _phoneNumber, LucideIcons.phone, () => _showEditDialog('Phone Number', _phoneNumber, (val) => setState(() => _phoneNumber = val))),
              _buildEditableInfoField('Date of Birth', _dateOfBirth, LucideIcons.calendar, () => _showEditDialog('Date of Birth', _dateOfBirth, (val) => setState(() => _dateOfBirth = val))),
              _buildEditableInfoField('Home Ward', _userWard, LucideIcons.mapPin, () => _showEditDialog('Home Ward', _userWard, (val) => setState(() => _userWard = val))),
              const SizedBox(height: 24),

              // 2. COMMUNITY & ACTIVITY
              _buildSectionTitle('APP PREFERENCES'),
              ValueListenableBuilder<bool>(
                valueListenable: isSparkleModeEnabled,
                builder: (context, isEnabled, child) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle), child: const Icon(LucideIcons.sparkles, size: 18, color: Color(0xFFF59E0B))),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sparkle Mode', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A))),
                                Text('Fun interactive tap animations', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isEnabled,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) => isSparkleModeEnabled.value = val, // Flips the global switch!
                        )
                      ],
                    ),
                  );
                }
              ),
              
              // NEW: MY REPORTS PORTAL
              _buildActionCard(
                'My Active Reports', 
                'Track, edit, and view updates on your filed issues', 
                LucideIcons.fileText, 
                const Color(0xFFF59E0B), 
                () => Navigator.pushNamed(context, '/my_issues', arguments: 'MY_REPORTS')
              ),

              _buildActionCard(
                'Neighborhood Network', 
                'See what issues your neighbors in $_userWard are reporting', 
                LucideIcons.users, 
                const Color(0xFF10B981), 
                _viewNeighborReports,
                isLoading: _isLoadingNeighbors
              ),
              const SizedBox(height: 24),

              // 3. ACCOUNT SECURITY
              _buildSectionTitle('ACCOUNT SECURITY'),
              _buildActionCard('Change Password', 'Update your secure login credentials', LucideIcons.key, const Color(0xFF3B82F6), _showChangePasswordDialog),
              
              // STRICT CONFIRMATION DELETE
              _buildActionCard('Delete Account', 'Permanently erase profile and report data', LucideIcons.trash2, const Color(0xFFE11D48), _showDeleteAccountDialog, isDestructive: true),
              const SizedBox(height: 32),

              // LOGOUT
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: Text('SIGN OUT', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFFE2E8F0), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}