import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wms_bctech/components/barcode_overlay_painter_widget.dart';

class ImprovedCameraScannerDialogWidget extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final Function() onCancel;

  const ImprovedCameraScannerDialogWidget({
    required this.onBarcodeDetected,
    required this.onCancel,
    super.key,
  });

  @override
  State<ImprovedCameraScannerDialogWidget> createState() =>
      _ImprovedCameraScannerDialogWidgetState();
}

class _ImprovedCameraScannerDialogWidgetState
    extends State<ImprovedCameraScannerDialogWidget> {
  late MobileScannerController cameraController;
  bool _isTorchOn = false;
  bool _isProcessing = false;
  Barcode? _detectedBarcode;

  @override
  void initState() {
    super.initState();

    cameraController = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: true,
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.pdf417,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.aztec,
        BarcodeFormat.itf,
      ],
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final Barcode barcode = barcodes.first;
      final String? code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        setState(() => _detectedBarcode = barcode);

        _isProcessing = true;
        await cameraController.stop();

        await Future.delayed(const Duration(milliseconds: 300));
        widget.onBarcodeDetected(code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.only(
        left: 20,
        right: 8,
        top: 20,
        bottom: 0,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Scan Barcode",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.onCancel();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: MobileScanner(
                controller: cameraController,
                fit: BoxFit.cover,
                onDetect: _handleBarcodeDetected,
                errorBuilder: (context, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${error.errorDetails?.message ?? 'Unknown error'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_detectedBarcode?.corners != null)
              CustomPaint(
                painter: BarcodeOverlayPainterWidget(_detectedBarcode!),
                size: const Size(double.infinity, double.infinity),
              ),
            Positioned(
              bottom: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: () async {
                      try {
                        await cameraController.toggleTorch();
                        setState(() => _isTorchOn = !_isTorchOn);
                      } catch (e) {
                        debugPrint("Torch error: $e");
                      }
                    },
                    icon: Icon(
                      _isTorchOn ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isTorchOn
                          ? Colors.amber
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filled(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: () async {
                      try {
                        await cameraController.switchCamera();
                      } catch (e) {
                        debugPrint("Switch camera error: $e");
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// checked
