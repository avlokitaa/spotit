import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';
import '../models/user_profile.dart'; 
import '../main.dart'; // Imports the themeNotifier

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingNeighbors = false;

  String _phoneNumber = '+91 98765 43210';
  String _dateOfBirth = '24 August, 2002';
  
  final List<String> _wards = ['J.P. Nagar', 'Basavanagudi', 'Koramangala', 'Indiranagar', 'Whitefield'];

  void _handleLogout() async {
    await _firebaseService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _showEditDialog(String title, String currentValue, Function(String) onSave, bool isDark) {
    final TextEditingController controller = TextEditingController(text: currentValue);
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit $title', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: textColor)),
        content: TextField(
          controller: controller, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: textColor),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF10B981), width: 2)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
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

  void _showJoinNeighborhoodDialog(bool isDark) {
    String tempWard = _firebaseService.currentUser?.ward ?? 'J.P. Nagar';
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Column(
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.home, color: Color(0xFF10B981), size: 32)),
                  const SizedBox(height: 16),
                  Text('Find Your Neighbors', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Enter your neighborhood below to see who lives near you and view local reports.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF64748B))),
                ]
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SELECT YOUR WARD', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: tempWard,
                        isExpanded: true,
                        dropdownColor: bgColor,
                        icon: const Icon(LucideIcons.chevronDown, size: 16),
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        onChanged: (v) => setStateSB(() => tempWard = v!),
                        items: _wards.map((w) => DropdownMenuItem(value: w, child: Text(w, style: TextStyle(color: textColor)))).toList(),
                      ),
                    ),
                  ),
                ]
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(onPressed: () => Navigator.pop(ctx), child: Text('CANCEL', style: GoogleFonts.spaceGrotesk(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900))),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _viewNeighborReports(tempWard, isDark); 
                        },
                        child: Text('CONNECT', style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    )
                  ],
                )
              ]
            );
          }
        );
      }
    );
  }

  void _viewNeighborReports(String selectedWard, bool isDark) async {
    setState(() => _isLoadingNeighbors = true);
    await _firebaseService.updateUserWard(selectedWard);
    _firebaseService.currentUser?.ward = selectedWard;
    final allIssues = await _firebaseService.getIssues();
    final neighborIssues = allIssues.where((issue) => (issue.address ?? '').toLowerCase().contains(selectedWard.toLowerCase())).toList();
    final neighbors = await _firebaseService.getNeighbors(selectedWard);
    neighbors.removeWhere((n) => n.uid == _firebaseService.currentUser?.uid); 
    setState(() => _isLoadingNeighbors = false);
    if (mounted) _showNeighborhoodSheet(neighborIssues, neighbors, selectedWard, isDark);
  }

  void _showNeighborhoodSheet(List<Issue> issues, List<UserProfile> neighbors, String userWard, bool isDark) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    showModalBottomSheet(
      context: context, backgroundColor: bgColor, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.users, color: Color(0xFF10B981))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Neighborhood Network', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
                            Text('Live reports in $userWard', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (neighbors.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Neighbors', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                        Text('${neighbors.length} ACTIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: neighbors.length,
                        itemBuilder: (context, index) {
                          final neighbor = neighbors[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                  child: CircleAvatar(radius: 24, backgroundImage: NetworkImage(neighbor.photoURL), backgroundColor: cardColor),
                                ),
                                const SizedBox(height: 6),
                                Text(neighbor.displayName.split(' ').first, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: textColor)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: borderColor)),
                  ],

                  Text('Recent Activity', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                  const SizedBox(height: 12),

                  Expanded(
                    child: issues.isEmpty
                      ? Center(child: Text('Your neighborhood is currently clear!', style: GoogleFonts.inter(color: const Color(0xFF94A3B8))))
                      : ListView.separated(
                          controller: scrollController, physics: const BouncingScrollPhysics(),
                          itemCount: issues.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final issue = issues[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(issue.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
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

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 16, top: 8), child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF94A3B8), letterSpacing: 1.5)));
  }

  Widget _buildEditableInfoField(String label, String value, IconData icon, VoidCallback onEditTap, Color cardColor, Color borderColor, Color textColor, bool isDark) {
    return GestureDetector(
      onTap: onEditTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF94A3B8)), const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 2),
                  Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                ],
              ),
            ),
            Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), shape: BoxShape.circle), child: const Icon(LucideIcons.pencil, size: 14, color: Color(0xFF10B981)))
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap, Color cardColor, Color borderColor, Color textColor, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFF4C1D95).withOpacity(0.1) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDestructive ? const Color(0xFFE11D48).withOpacity(0.3) : borderColor),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDestructive ? const Color(0xFFE11D48).withOpacity(0.1) : color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 18, color: isDestructive ? const Color(0xFFE11D48) : color)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: isDestructive ? const Color(0xFFE11D48) : textColor)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: isDestructive ? const Color(0xFFE11D48).withOpacity(0.7) : const Color(0xFF94A3B8))),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: isDestructive ? const Color(0xFFE11D48).withOpacity(0.5) : const Color(0xFFCBD5E1))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        final isDark = currentMode == ThemeMode.dark;

        final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
        final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor, elevation: 0,
            leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: textColor), onPressed: () => Navigator.pop(context)),
            title: Text('Account Profile', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF10B981), width: 3), image: DecorationImage(image: NetworkImage(user?.photoURL ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=guest'), fit: BoxFit.cover)),
                        ),
                        const SizedBox(height: 16),
                        Text(user?.displayName ?? 'Resident', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 4),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFECFDF5).withOpacity(isDark ? 0.1 : 1.0), borderRadius: BorderRadius.circular(100)), child: Text('VERIFIED USER', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF10B981), letterSpacing: 0.5))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  GestureDetector(
                    onTap: () => _showJoinNeighborhoodDialog(isDark),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(100)),
                                  child: Text('COMMUNITY', style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                                ),
                                const SizedBox(height: 12),
                                Text('Find Your Neighbors', style: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
                                const SizedBox(height: 4),
                                Text('Enter your neighborhood to know your neighbors and view local reports.', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 50, height: 50,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: _isLoadingNeighbors 
                              ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Color(0xFF10B981), strokeWidth: 2))
                              : const Icon(LucideIcons.arrowRight, color: Color(0xFF10B981)),
                          )
                        ],
                      ),
                    ),
                  ),

                  _buildSectionTitle('MY INFORMATION'),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.mail, size: 18, color: Color(0xFF94A3B8)), const SizedBox(width: 16),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Email Address (Unchangeable)', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))), const SizedBox(height: 2), Text(user?.email ?? 'No email linked', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: const Color(0xFF64748B)))]),
                      ],
                    ),
                  ),
                  _buildEditableInfoField('Phone Number', _phoneNumber, LucideIcons.phone, () => _showEditDialog('Phone Number', _phoneNumber, (val) => setState(() => _phoneNumber = val), isDark), cardColor, borderColor, textColor, isDark),
                  _buildEditableInfoField('Date of Birth', _dateOfBirth, LucideIcons.calendar, () => _showEditDialog('Date of Birth', _dateOfBirth, (val) => setState(() => _dateOfBirth = val), isDark), cardColor, borderColor, textColor, isDark),
                  const SizedBox(height: 24),

                  _buildSectionTitle('APP PREFERENCES'),
                  
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10), 
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), shape: BoxShape.circle), 
                              child: Icon(isDark ? LucideIcons.moon : LucideIcons.sun, size: 18, color: isDark ? Colors.blueAccent : const Color(0xFFF59E0B))
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Dark Mode', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: textColor)),
                                Text('Switch app appearance', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isDark, 
                          activeColor: const Color(0xFF10B981), 
                          onChanged: (val) {
                            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                          }
                        )
                      ],
                    ),
                  ),

                  _buildSectionTitle('COMMUNITY & ACTIVITY'),
                  _buildActionCard('My Active Reports', 'Track, edit, and view updates on your filed issues', LucideIcons.fileText, const Color(0xFFF59E0B), () => Navigator.pushNamed(context, '/my_issues', arguments: 'MY_REPORTS'), cardColor, borderColor, textColor),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: Icon(LucideIcons.logOut, size: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      label: Text('SIGN OUT', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: 1)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}