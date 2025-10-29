import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerDialog extends StatefulWidget {
  final Function(String) onQRCodeDetected;
  final Function() onClose;

  const QRScannerDialog({
    required this.onQRCodeDetected,
    required this.onClose,
    super.key,
  });

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog> {
  late MobileScannerController cameraController;
  bool _isTorchOn = false;
  String _lastScannedCode = "";

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Scan QR Code",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: widget.onClose,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Scanner Preview
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (BarcodeCapture capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String? code = barcodes.first.rawValue;
                          if (code != null &&
                              code.isNotEmpty &&
                              code != _lastScannedCode) {
                            _lastScannedCode = code;
                            widget.onQRCodeDetected(code);
                          }
                        }
                      },
                    ),

                    // Scanner overlay
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: hijauGojek.withValues(alpha: 0.8),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    // Center guide
                    Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: hijauGojek.withValues(alpha: 0.6),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Instructions
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Arahkan kamera ke QR Code produk",
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Torch toggle
                IconButton.filled(
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                  onPressed: () async {
                    try {
                      await cameraController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    } catch (e) {
                      debugPrint("Error toggling torch: $e");
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: _isTorchOn ? Colors.amber : Colors.grey,
                  ),
                ),

                // Switch camera
                IconButton.filled(
                  icon: const Icon(Icons.cameraswitch),
                  onPressed: () async {
                    try {
                      await cameraController.switchCamera();
                    } catch (e) {
                      debugPrint("Error switching camera: $e");
                    }
                  },
                  style: IconButton.styleFrom(backgroundColor: Colors.blue),
                ),

                // Close button
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Tutup"),
                  onPressed: widget.onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
