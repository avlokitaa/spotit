import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Added Firebase Core import
import 'firebase_options.dart';                  // 2. Fixed import path relative to lib/
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/issue_tracking_screen.dart'; 
import 'screens/admin_screen.dart';
import 'screens/my_issues_screen.dart';
import 'widgets/sparkle_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Initialize Firebase using your options file before the app runs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('issues').get();
    
    // Only seed if the database has less than 3 items
    if (snapshot.docs.length < 3) {
      print("Seeding sample Bangalore issues...");
      final issuesToAdd = [
        {
          'title': 'Deep Pothole on Main Road',
          'description': 'Large pothole expanding rapidly near the J.P. Nagar 3rd Phase junction. Dangerous for two-wheelers at night.',
          'category': 'POTHOLE',
          'urgency': 'HIGH',
          'status': 'reported',
          'latitude': 12.9063,
          'longitude': 77.5857,
          'address': 'J.P. Nagar',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'title': 'Fallen Gulmohar Tree',
          'description': 'Heavy rains caused a tree to fall, completely blocking the residential crossroad.',
          'category': 'FALLEN TREE',
          'urgency': 'HIGH',
          'status': 'in-progress',
          'latitude': 12.9408,
          'longitude': 77.5641,
          'address': 'Basavanagudi',
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 10)).toIso8601String(),
        },
        {
          'title': 'Overflowing Dumpster',
          'description': 'Garbage bin has not been cleared for 4 days. Waste is spilling onto the pavement creating a severe hygiene hazard.',
          'category': 'GARBAGE',
          'urgency': 'MEDIUM',
          'status': 'reported',
          'latitude': 12.9345,
          'longitude': 77.6214,
          'address': 'Koramangala',
          'createdAt': DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
        },
        {
          'title': 'Broken Streetlight',
          'description': 'Streetlight has been flickering and is now completely dead. Area is pitch black after 7 PM.',
          'category': 'STREET LIGHT',
          'urgency': 'LOW',
          'status': 'resolved',
          'latitude': 12.9783,
          'longitude': 77.6408,
          'address': 'Indiranagar',
          'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        }
      ];

      for (var data in issuesToAdd) {
        await firestore.collection('issues').add(data);
      }
      print("🚀 SUCCESS: 4 Sample issues added to Firestore!");
    }
  } catch (e) {
    print("Seed error: $e");
  }

  runApp(const SpotItApp());
}

class SpotItApp extends StatelessWidget {
  const SpotItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpotIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF43F5E), // neon pink primary accent
          background: const Color(0xFFF8FAFC), // slate-50 canvas
        ),
      ),
      // Integrates your global SparkleOverlay seamlessly
      builder: (context, child) {
        return SparkleOverlay(child: child!);
      },
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/report': (context) => const ReportScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminScreen(),
        '/tracking': (context) => const IssueTrackingScreen(),
        '/my_issues': (context) => const MyIssuesScreen(),
      },
    );
  }
}