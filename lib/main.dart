import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Added Firebase Core import
import 'firebase_options.dart';                  // 2. Fixed import path relative to lib/
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/report_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'widgets/sparkle_overlay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 3. Initialize Firebase using your options file before the app runs
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // TEMPORARY SEED CODE - Delete after running once
  try {
    final firestore = FirebaseFirestore.instance;
    final issuesSnapshot = await firestore.collection('issues').get();
    
    if (issuesSnapshot.docs.isEmpty) {
      await firestore.collection('issues').add({
        'title': 'Blocked Storm Drain',
        'description': 'Heavy rainfall has caused severe clogging in the main community drainage line, resulting in significant water logging on the civilian walkway.',
        'category': 'water', // Triggers the 💧 icon layout
        'urgency': 'High',
        'status': 'pending',
        'latitude': 12.9716, // Centers onto your Bangalore map
        'longitude': 77.5946,
        'reportedAt': DateTime.now().toIso8601String(),
      });
      print("🚀 SUCCESS: Database successfully seeded with perfect model data!");
    }
  } catch (e) {
    print("Seeding error: $e");
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
      },
    );
  }
}