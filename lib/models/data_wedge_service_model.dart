// // datawedge_service.dart
// import 'package:flutter/services.dart';

// class DataWedgeService {
//   static const MethodChannel _channel = MethodChannel('datawedge_integration');

//   static Future<void> enableBarcodeScanning() async {
//     try {
//       await _channel.invokeMethod('enableBarcodeScanning');
//     } catch (e) {
//       print('Failed to enable barcode scanning: $e');
//     }
//   }

//   static Future<void> startScanning() async {
//     try {
//       await _channel.invokeMethod('startScanning');
//     } catch (e) {
//       print('Failed to start scanning: $e');
//     }
//   }
//   // static const MethodChannel _channel = MethodChannel('datawedge_channel');

//   // Future<void> enableAutomaticBarcodeScanning() async {
//   //   try {
//   //     await _channel.invokeMethod('sendDataWedgeIntentString', {
//   //       'action': 'com.symbol.datawedge.api.ACTION',
//   //       'extra': {
//   //         'com.symbol.datawedge.api.SOFT_SCAN_TRIGGER': 'START_SCANNING',
//   //         'com.symbol.datawedge.api.SCANNER_INPUT_PLUGIN': 'AUTO'
//   //       }
//   //     });
//   //   } on PlatformException catch (e) {
//   //     print('Failed to enable automatic barcode scanning: ${e.message}');
//   //   } catch (e) {
//   //     print(e);
//   //   }
//   // }

//   // Future<void> startBarcodeScan() async {
//   //   try {
//   //     await _channel.invokeMethod('startBarcodeScan');
//   //   } on PlatformException catch (e) {
//   //     print('Failed to start barcode scan: ${e.message}');
//   //   } catch (e) {
//   //     print(e);
//   //   }
//   // }

//   // void listenForBarcodeScans(Function(String) onBarcodeScanned) {
//   //   _channel.setMethodCallHandler((MethodCall call) async {
//   //     if (call.method == 'barcodeScanned') {
//   //       String barcode = call.arguments['data'];
//   //       onBarcodeScanned(barcode);
//   //     }
//   //   });
//   // }

// }
