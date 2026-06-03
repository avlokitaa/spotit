import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/issue.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stored active user profile in memory
  UserProfile? currentUser;

  // Singleton pattern for simple global access across screens
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool get isAuthenticated => currentUser != null;

  // 1. REGISTRATION ENGINE
  Future<UserProfile> registerUser({required String name, required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();

    // Prevent users from registering as the admin
    if (cleanEmail == 'admin@spotit.com') {
      throw Exception("Cannot register as the system administrator.");
    }

    // Check if user already exists
    final existingUser = await _firestore.collection('users').where('email', isEqualTo: cleanEmail).get();
    if (existingUser.docs.isNotEmpty) {
      throw Exception("An account with this email already exists.");
    }

    // Create the new user
    final String uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    currentUser = UserProfile(
      uid: uid,
      email: cleanEmail,
      displayName: name.trim(),
      photoURL: 'https://api.dicebear.com/7.x/avataaars/png?seed=$uid',
      role: 'user',
    );

    // Save to Firestore Database (Saving password plain text ONLY for this prototype demo!)
    await _firestore.collection('users').doc(uid).set({
      ...currentUser!.toMap(),
      'password': password, 
    });

    return currentUser!;
  }

  // 2. LOGIN ENGINE (Strict Check)
  Future<UserProfile> loginUser({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();

    // --- HARDLOCKED ADMIN BYPASS ---
    if (cleanEmail == 'admin@spotit.com') {
      if (password == 'Admin123!') { // YOUR STRICT ADMIN PASSWORD
        currentUser = UserProfile(
          uid: 'admin_master', email: 'admin@spotit.com',
          displayName: 'System Admin', photoURL: 'https://api.dicebear.com/7.x/avataaars/png?seed=admin',
          role: 'admin',
        );
        return currentUser!;
      } else {
        throw Exception("Incorrect Admin Password.");
      }
    }

    // --- STANDARD USER CHECK ---
    final query = await _firestore.collection('users')
        .where('email', isEqualTo: cleanEmail)
        .where('password', isEqualTo: password)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Invalid email or password. User not found in database.");
    }

    // Success! Load user data
    final userData = query.docs.first.data();
    currentUser = UserProfile(
      uid: userData['uid'],
      email: userData['email'],
      displayName: userData['displayName'],
      photoURL: userData['photoURL'],
      role: userData['role'] ?? 'user',
    );

    return currentUser!;
  }

  // Logout
  Future<void> logout() async {
    currentUser = null;
  }
  //--- Delete---//
  Future<void> deleteIssue(String id) async {
    try {
      await _firestore.collection('issues').doc(id).delete();
    } catch (e) {
      print('Firestore delete issue failure: $e');
    }
  }
  // --- EXISTING ISSUE METHODS REMAIN UNCHANGED ---
  Future<String> reportNewIssue({
    required String title, required String description, required String category, required String urgency,
    required double latitude, required double longitude, required String address, String? imageUrl,
  }) async {
    final newId = 'issue_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final newIssue = Issue(
      id: newId, reporterUid: currentUser?.uid ?? 'guest_uid', reporterName: currentUser?.displayName ?? 'Resident',
      title: title, description: description, category: category, urgency: urgency,
      latitude: latitude, longitude: longitude, address: address, imageUrl: imageUrl,
      status: 'reported', createdAt: now, updatedAt: now,
    );

    try {
      await _firestore.collection('issues').doc(newId).set(newIssue.toMap());
      return newId;
    } catch (e) {
      throw Exception("Failed to submit to cloud: $e");
    }
  }

  Future<List<Issue>> getIssues({String? status, String? category}) async {
    try {
      Query query = _firestore.collection('issues');
      if (status != null && status.isNotEmpty) query = query.where('status', isEqualTo: status);
      if (category != null && category.isNotEmpty) query = query.where('category', isEqualTo: category);
      query = query.orderBy('createdAt', descending: true).limit(20);
      
      QuerySnapshot snapshot = await query.get();
      return snapshot.docs.map((doc) => Issue.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Firestore retrieve issues failed: $e');
      return []; 
    }
  }

  Future<void> updateIssueStatus(String id, String newStatus, {String? assignedAdmin}) async {
    try {
      await _firestore.collection('issues').doc(id).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Firestore status update failure: $e');
    }
  }
}