import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(); 
  
  bool _isLoginMode = true;
  bool _isLoading = false;

  void _submitForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (!_isLoginMode && name.isEmpty) {
      _showError('Please provide your name to register.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // LOGIN
        final user = await _firebaseService.loginUser(email: email, password: password);
        _routeUser(user.role);
      } else {
        // REGISTER
        final user = await _firebaseService.registerUser(name: name, email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Created Successfully!'), backgroundColor: Color(0xFF10B981)));
        }
        _routeUser(user.role);
      }
    } catch (e) {
      // Strips the word "Exception:" from the error text
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _routeUser(String role) {
    if (mounted) {
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo/Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(LucideIcons.mapPin, size: 40, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _isLoginMode ? 'Welcome Back' : 'Join SpotIt',
                  style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w900, color: const Color(0xFF0F172A), letterSpacing: -1),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginMode ? 'Sign in to track your reports.' : 'Create an account to report civic issues.',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Name Input (Only shown in Sign Up mode)
                if (!_isLoginMode) ...[
                  _buildTextField(_nameController, 'Full Name', LucideIcons.user, false),
                  const SizedBox(height: 16),
                ],

                // Email Input
                _buildTextField(_emailController, 'Email Address', LucideIcons.mail, false),
                const SizedBox(height: 16),
                
                // Password Input
                _buildTextField(_passwordController, 'Password', LucideIcons.lock, true),
                const SizedBox(height: 12),
                
                // The Admin Quick-Fill Button (As Requested)
                if (_isLoginMode)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _emailController.text = 'admin@spotit.com';
                        _passwordController.clear(); // Force them to type the password!
                      });
                    },
                    child: Text(
                      'Admin? Tap to fill Admin Email.',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                const SizedBox(height: 32),

                // Action Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLoginMode ? 'SECURE LOGIN' : 'CREATE ACCOUNT', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 24),

                // Toggle Mode Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isLoginMode ? "Don't have an account? " : "Already have an account? ", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
                    GestureDetector(
                      onTap: () => setState(() => _isLoginMode = !_isLoginMode),
                      child: Text(
                        _isLoginMode ? "Sign Up" : "Login",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isPassword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}