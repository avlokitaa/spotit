// lib/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Get an instance of the Firestore database
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Call this function to save a report to the cloud without breaking your UI
  Future<void> submitReport({
    required String title,
    required String description,
    required String category,
  }) async {
    try {
      // This automatically creates a "reports" collection if it doesn't exist yet
      await _db.collection('reports').add({
        'title': title,
        'description': description,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(), // Keeps track of exactly when it was submitted
      });
      print("Report uploaded to Firebase successfully!");
    } catch (e) {
      print("Error uploading report: $e");
    }
  }
}