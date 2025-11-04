import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkHelper {
  static final NetworkHelper _instance = NetworkHelper._internal();
  factory NetworkHelper() => _instance;
  NetworkHelper._internal();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogShown = false;

  void startListening() {
    _subscription ??= Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final isOffline = !results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (isOffline && !_isDialogShown) {
        _isDialogShown = true;
        _showOfflineDialog();
      } else if (!isOffline && _isDialogShown) {
        _isDialogShown = false;
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _showOfflineDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.grey[900]!, Colors.grey[800]!],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon dengan animasi
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 40,
                      color: Colors.red[300],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  'Koneksi Terputus',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  'Perangkat Anda tidak terhubung ke internet. '
                  'Silakan periksa koneksi WiFi atau data seluler Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[300],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 25),

                // Loading indicator dengan teks
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[300]!,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Menunggu koneksi...',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tips
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 18,
                        color: Colors.blue[300],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tips: Coba nyalakan mode pesawat lalu matikan kembali',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[200],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
    );
  }
}
