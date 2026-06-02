import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/issue.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stored active user profile in memory
  UserProfile? currentUser;

  // Singleton pattern for simple global access across screens
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool get isAuthenticated => _auth.currentUser != null || currentUser != null;

  // Sign In flow matching React anonymous flow with customizable Email representation
  Future<UserProfile> loginWithEmail(String email) async {
    final trimmedEmail = email.trim();
    final defaultName = trimmedEmail.split('@')[0];
    final capitalizedName = defaultName.isNotEmpty 
        ? defaultName[0].toUpperCase() + defaultName.substring(1) 
        : 'Resident';

    try {
      // Connect to real Firebase Auth anonymously
      UserCredential credential = await _auth.signInAnonymously();
      String uid = credential.user?.uid ?? 'local_uid_${DateTime.now().millisecondsSinceEpoch}';

      currentUser = UserProfile(
        uid: uid,
        email: trimmedEmail,
        displayName: capitalizedName,
        photoURL: 'https://api.dicebear.com/7.x/avataaars/png?seed=$uid', // Fixed to PNG for Android!
        role: trimmedEmail.toLowerCase().contains('admin') ? 'admin' : 'user',
      );

      // Save user profile to Firestore
      await _firestore.collection('users').doc(uid).set(currentUser!.toMap(), SetOptions(merge: true));
      return currentUser!;
    } catch (e) {
      print('Firebase login failed: $e');
      
      // Local fallback representation just in case auth servers drop
      String fallbackUid = 'local_uid_${trimmedEmail.hashCode}';
      currentUser = UserProfile(
        uid: fallbackUid,
        email: trimmedEmail,
        displayName: capitalizedName,
        photoURL: 'https://api.dicebear.com/7.x/avataaars/png?seed=$fallbackUid', // Fixed to PNG
        role: trimmedEmail.toLowerCase().contains('admin') ? 'admin' : 'user',
      );
      return currentUser!;
    }
  }

  // Logout representation
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Firebase signout failed: $e');
    }
    currentUser = null;
  }

  // Report a new local hazard/incident LIVE to Firestore
  Future<String> reportNewIssue({
    required String title,
    required String description,
    required String category,
    required String urgency,
    required double latitude,
    required double longitude,
    required String address,
    String? imageUrl,
  }) async {
    final newId = 'issue_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final newIssue = Issue(
      id: newId,
      reporterUid: currentUser?.uid ?? 'guest_uid',
      reporterName: currentUser?.displayName ?? 'Anonymous Resident',
      title: title,
      description: description,
      category: category,
      urgency: urgency,
      latitude: latitude,
      longitude: longitude,
      address: address,
      imageUrl: imageUrl,
      status: 'reported',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _firestore.collection('issues').doc(newId).set(newIssue.toMap());
      return newId;
    } catch (e) {
      print('Firestore incident submission failed: $e');
      throw Exception("Failed to submit to cloud.");
    }
  }

  // Query issues LIVE from Firestore ONLY
  Future<List<Issue>> getIssues({String? status, String? category}) async {
    try {
      Query query = _firestore.collection('issues');
      
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      // Order by descending report date
      query = query.orderBy('createdAt', descending: true);
      
      QuerySnapshot snapshot = await query.get();
      
      // Force map the live cloud documents!
      return snapshot.docs.map((doc) => Issue.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Firestore retrieve issues failed: $e');
      return []; // Return completely empty list on failure so the UI shows the empty state correctly
    }
  }

  // Update status (e.g. from reported -> in-progress -> resolved)
  Future<void> updateIssueStatus(String id, String newStatus, {String? assignedAdmin}) async {
    try {
      await _firestore.collection('issues').doc(id).update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
        if (assignedAdmin != null) 'assignedTo': assignedAdmin,
      });
    } catch (e) {
      print('Firestore status update failure: $e');
    }
  }
}