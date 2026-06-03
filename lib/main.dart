import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- SCREEN IMPORTS ---
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/report_screen.dart';
import 'screens/my_issues_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/map_screen.dart';
import 'screens/issue_tracking_screen.dart';

// --- GLOBAL DARK MODE TOGGLE ---
// This acts as a global switch that any screen can listen to and change!
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  // Ensure Flutter bindings are initialized before calling Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase backend
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const SpotItApp());
}

class SpotItApp extends StatelessWidget {
  const SpotItApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The ValueListenableBuilder wraps the MaterialApp so it rebuilds the UI
    // whenever the themeNotifier variable changes (like when you flip the switch in Profile)
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'SpotIt',
          debugShowCheckedModeBanner: false,
          
          // Apply the current theme mode dynamically
          themeMode: currentMode,
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),

          // Routing Engine
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
            '/report': (context) => const ReportScreen(),
            '/my_issues': (context) => const MyIssuesScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/admin': (context) => const AdminScreen(),
            '/map': (context) => const MapScreen(),
            '/tracking': (context) => const IssueTrackingScreen(), 
          },
        );
      },
    );
  }
}