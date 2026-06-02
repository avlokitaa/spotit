import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  void _handleLogout() async {
    await _firebaseService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Resident Profile',
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF0F172A), 
            fontWeight: FontWeight.w900, 
            fontSize: 16
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? Center(
                child: InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                  child: Text(
                    'Guest Resident: Click to Login', 
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        children: [
                          // Fixed Profile Image / Fallback Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF43F5E), width: 3),
                              color: const Color(0xFFFFE4E6), 
                            ),
                            child: ClipOval(
                              child: (!user.photoURL.contains('.svg'))
                                  ? Image.network(
                                      user.photoURL,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        LucideIcons.user,
                                        color: Color(0xFFF43F5E),
                                        size: 40,
                                      ),
                                    )
                                  : const Icon(
                                      LucideIcons.user,
                                      color: Color(0xFFF43F5E),
                                      size: 40,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.displayName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: user.role == 'admin' 
                                  ? const Color(0xFFEEF2FF) 
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: user.role == 'admin' 
                                    ? const Color(0xFFCABFFD) 
                                    : const Color(0xFFE2E8F0)
                              ),
                            ),
                            child: Text(
                              user.role == 'admin' ? 'ADMINISTRATOR' : 'LOCAL CITIZEN',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: user.role == 'admin' 
                                    ? const Color(0xFF4F46E5) 
                                    : const Color(0xFF64748B),
                                letterSpacing: 1.2,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Admin Dashboard Router
                    if (user.role == 'admin') ...[
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(context, '/admin');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.shield, color: Colors.amber, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin Console Action',
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Review & mutate reported resident issues',
                                      style: GoogleFonts.inter(
                                        color: Colors.blueGrey.shade400,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Sign Out Button Card
                    InkWell(
                      onTap: _handleLogout,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 14),
                            Text(
                              'Sign Out from Desk',
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}