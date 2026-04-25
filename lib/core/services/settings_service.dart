import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _documentId = 'store_info'; // Fixed ID for global settings

  // Stream to listen to real-time changes
  Stream<DocumentSnapshot> get settingsStream =>
      _firestore.collection('app_config').doc(_documentId).snapshots();

  // Read values once
  Future<Map<String, dynamic>?> getSettings() async {
    final doc = await _firestore.collection('app_config').doc(_documentId).get();
    return doc.data();
  }

  // Update values
  Future<void> updateSettings({
    required String title,
    required String address,
    required String telNumber,
  }) async {
    await _firestore.collection('app_config').doc(_documentId).set({
      'superMarketTitle': title,
      'billAddress': address,
      'telNumber': telNumber,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}