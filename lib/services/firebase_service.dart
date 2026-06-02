import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../models/issue.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stored active user profile in memory
  UserProfile? currentUser;

  // Sample mock fallbacks to matches React application exactly
  static final List<Issue> mockReports = [
    Issue(
      id: 'r1',
      reporterUid: 'mock1',
      reporterName: 'Anil K.',
      title: 'Overflowing Garbage Bin',
      description: 'Waste left unattended near Basavanagudi park causing strong odor and hygiene concerns.',
      category: 'Waste',
      urgency: 'Medium',
      status: 'in-progress',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      latitude: 12.9716,
      longitude: 77.5946,
      address: 'Basavanagudi, Bangalore',
    ),
    Issue(
      id: 'r2',
      reporterUid: 'mock2',
      reporterName: 'Supriya P.',
      title: 'Large Dangerous Pothole',
      description: 'Dangerous deep cavity right in front of the local school crossing. Needs prompt filling.',
      category: 'Pothole',
      urgency: 'High',
      status: 'reported',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      latitude: 12.9725,
      longitude: 77.5932,
      address: 'Basavanagudi, Bangalore',
    ),
    Issue(
      id: 'r3',
      reporterUid: 'mock3',
      reporterName: 'Ramesh H.',
      title: 'Water Main Leak',
      description: 'Underground pipe burst causing clean drinking water to flood the road pavement.',
      category: 'Water Leak',
      urgency: 'High',
      status: 'resolved',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      latitude: 12.9702,
      longitude: 77.5961,
      address: 'Basavanagudi, Bangalore',
    ),
  ];

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
        photoURL: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$uid',
        role: trimmedEmail.toLowerCase().contains('admin') ? 'admin' : 'user',
      );

      // Save user profile to Firestore
      await _firestore.collection('users').doc(uid).set(currentUser!.toMap(), SetOptions(merge: true));
      return currentUser!;
    } catch (e) {
      print('Firebase login failed, continuing with local fallback: $e');
      
      // Local fallback representation
      String fallbackUid = 'local_uid_${trimmedEmail.hashCode}';
      currentUser = UserProfile(
        uid: fallbackUid,
        email: trimmedEmail,
        displayName: capitalizedName,
        photoURL: 'https://api.dicebear.com/7.x/avataaars/svg?seed=$fallbackUid',
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

  // Report a new local hazard/incident
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
      // Create in Firestore
      await _firestore.collection('issues').doc(newId).set(newIssue.toMap());
      // Insert locally in the mock dataset list as active sync support
      mockReports.insert(0, newIssue);
      return newId;
    } catch (e) {
      print('Firestore incident submission failed, fallback locally: $e');
      mockReports.insert(0, newIssue);
      return newId;
    }
  }

  // Query issues
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
      if (snapshot.docs.isEmpty) {
        return _applyLocalFilters(status, category);
      }
      
      return snapshot.docs.map((doc) => Issue.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    } catch (e) {
      print('Firestore retrieve issues failed, reading local dataset: $e');
      return _applyLocalFilters(status, category);
    }
  }

  // Helper filter support for offline dataset
  List<Issue> _applyLocalFilters(String? status, String? category) {
    List<Issue> list = List.from(mockReports);
    if (status != null && status.isNotEmpty) {
      list = list.where((item) => item.status == status).toList();
    }
    if (category != null && category.isNotEmpty) {
      list = list.where((item) => item.category == category).toList();
    }
    return list;
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

    // Update locally as well
    int index = mockReports.indexWhere((item) => item.id == id);
    if (index != -1) {
      final current = mockReports[index];
      mockReports[index] = Issue(
        id: current.id,
        reporterUid: current.reporterUid,
        reporterName: current.reporterName,
        title: current.title,
        description: current.description,
        category: current.category,
        urgency: current.urgency,
        latitude: current.latitude,
        longitude: current.longitude,
        address: current.address,
        imageUrl: current.imageUrl,
        status: newStatus,
        assignedTo: assignedAdmin ?? current.assignedTo,
        createdAt: current.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }
}
