import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';

class FirebaseController {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  bool _isInitialized = false;
  String? token;

  Future<void> initializeFirebaseMessaging() async {
    try {
      _isInitialized = true;
      await _getFirebaseToken();
      _logger.i("Firebase Messaging initialized successfully");
    } catch (e) {
      _logger.e("Error initializing Firebase Messaging: $e");
      _isInitialized = false;
    }
  }

  Future<void> _getFirebaseToken() async {
    if (!_isInitialized) return;
    try {
      token = await _firebaseMessaging.getToken();
      _logger.i("Firebase Token: $token");
    } catch (e) {
      _logger.e("Error getting Firebase token: $e");
    }
  }
}
