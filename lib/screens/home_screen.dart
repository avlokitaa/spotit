import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';
import '../models/issue.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Issue> _issues = [];
  bool _isLoading = true;

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

  Map<String, dynamic> _getCategoryStyle(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('waste') || cat.contains('garbage')) {
      return {'emoji': '🗑️', 'bg': const Color(0xFFFEF3C7), 'color': const Color(0xFFD97706)};
    }
    if (cat.contains('pothole') || cat.contains('road') || cat.contains('street')) {
      return {'emoji': '🚧', 'bg': const Color(0xFFFEF9C3), 'color': const Color(0xFFCA8A04)};
    }
    if (cat.contains('tree') || cat.contains('green') || cat.contains('fallen')) {
      return {'emoji': '🌳', 'bg': const Color(0xFFECFDF5), 'color': const Color(0xFF059669)};
    }
    if (cat.contains('water') || cat.contains('leak') || cat.contains('drain')) {
      return {'emoji': '💧', 'bg': const Color(0xFFEFF6FF), 'color': const Color(0xFF2563EB)};
    }
    return {'emoji': '✨', 'bg': const Color(0xFFEEF2FF), 'color': const Color(0xFF4F46E5)};
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'reported':
        bg = const Color(0xFFFFEDD5);
        text = const Color(0xFFEA580C);
        label = 'Pending';
        break;
      case 'in-progress':
        bg = const Color(0xFFDBEAFE);
        text = const Color(0xFF2563EB);
        label = 'In Progress';
        break;
      case 'resolved':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF059669);
        label = 'Resolved';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: text.withOpacity(0.15)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: text,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          color: const Color(0xFFF43F5E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Custom Header pill-shadow matching web
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LOCATION',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFFF43F5E)),
                              const SizedBox(width: 4),
                              Text(
                                'Bangalore, KA',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      Row(
                        children: [
                          // Bell ring indicator
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(LucideIcons.bell, size: 18, color: Color(0xFF64748B)),
                                Positioned(
                                  top: 10,
                                  right: 12,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF43F5E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar Block
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/profile');
                            },
                            child: user != null
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFF43F5E), width: 2),
                                      image: DecorationImage(
                                        image: NetworkImage(user.photoURL),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF8FAFC),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.user, size: 18),
                                  ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Greeting Hero banner text
                Text(
                  user != null ? 'Hey ${user.displayName}!' : 'Welcome Resident!',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Explore pending hazards and resolutions in your vicinity.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 20),

                // Bento Grid Stats Section
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1,000',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'TOTAL REPORTS',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        height: 110,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '823',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                            Text(
                              'RESOLVED SPOTS',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Explore Local Map Interactive Card CTA matches exactly!
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/map'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFD1FAE5)),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🗺️', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore Local Issue Map',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'See active hazards plotted in your neighborhood using real GPS',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.arrowRight, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Feed Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Hazards reported',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF43F5E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // List Feed
                _isLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFFF43F5E))))
                    : _issues.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No reports listed yet. Be the first one!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _issues.length > 5 ? 5 : _issues.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final issue = _issues[index];
                              final style = _getCategoryStyle(issue.category);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: style['bg'],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        style['emoji'],
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  issue.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w900,
                                                    color: const Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              _buildStatusBadge(issue.status),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            issue.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(LucideIcons.user, size: 12, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'By ${issue.reporterName}',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Icon(LucideIcons.alertTriangle, size: 12, color: Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${issue.urgency} Urgency',
                                                style: GoogleFonts.inter(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      // Floating Report Trigger Matches perfectly!
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/report');
        },
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 16),
        label: Text(
          'Report Incident',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
