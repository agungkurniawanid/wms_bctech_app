import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerDialog extends StatefulWidget {
  final Function(String) onQRCodeDetected;
  final Function() onClose;
  final VoidCallback openManualInput; // Wajib, tidak nullable

  const QRScannerDialog({
    required this.onQRCodeDetected,
    required this.onClose,
    required this.openManualInput, // Diperlukan
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

  void _handleManualInput() {
    // Tutup dialog scanner terlebih dahulu
    widget.onClose();

    // Tunggu sebentar lalu buka bottom sheet manual
    Future.delayed(const Duration(milliseconds: 300), () {
      widget.openManualInput();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallDevice = size.width < 360;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmallDevice ? 12 : 16,
        vertical: isSmallDevice ? 20 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern Header
            Container(
              padding: EdgeInsets.all(isSmallDevice ? 12 : 16),
              decoration: BoxDecoration(
                color: hijauGojek.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hijauGojek.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: hijauGojek,
                      size: isSmallDevice ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Scan QR Code",
                      style: TextStyle(
                        fontSize: isSmallDevice ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    color: Colors.grey.shade600,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Padding(
                padding: EdgeInsets.all(isSmallDevice ? 12 : 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scanner Preview
                    Flexible(
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: cameraController,
                                onDetect: (BarcodeCapture capture) {
                                  final List<Barcode> barcodes =
                                      capture.barcodes;
                                  if (barcodes.isNotEmpty) {
                                    final String? code =
                                        barcodes.first.rawValue;
                                    if (code != null &&
                                        code.isNotEmpty &&
                                        code != _lastScannedCode) {
                                      _lastScannedCode = code;
                                      widget.onQRCodeDetected(code);
                                    }
                                  }
                                },
                              ),

                              // Scanning Animation Overlay
                              Center(
                                child: Container(
                                  width: isSmallDevice ? 180 : 220,
                                  height: isSmallDevice ? 180 : 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: hijauGojek,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Corner decorations
                                      ...List.generate(4, (index) {
                                        return Positioned(
                                          top: index < 2 ? 0 : null,
                                          bottom: index >= 2 ? 0 : null,
                                          left: index % 2 == 0 ? 0 : null,
                                          right: index % 2 == 1 ? 0 : null,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: index < 2
                                                    ? BorderSide(
                                                        color: hijauGojek,
                                                        width: 5,
                                                      )
                                                    : BorderSide.none,
                                                bottom: index >= 2
                                                    ? BorderSide(
                                                        color: hijauGojek,
                                                        width: 5,
                                                      )
                                                    : BorderSide.none,
                                                left: index % 2 == 0
                                                    ? BorderSide(
                                                        color: hijauGojek,
                                                        width: 5,
                                                      )
                                                    : BorderSide.none,
                                                right: index % 2 == 1
                                                    ? BorderSide(
                                                        color: hijauGojek,
                                                        width: 5,
                                                      )
                                                    : BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: isSmallDevice ? 12 : 16),

                    // Instructions Card
                    Container(
                      padding: EdgeInsets.all(isSmallDevice ? 10 : 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade50,
                            Colors.blue.shade100.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: isSmallDevice ? 18 : 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Arahkan kamera ke QR Code produk",
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: isSmallDevice ? 12 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallDevice ? 12 : 16),

                    // Modern Control Buttons
                    Wrap(
                      spacing: isSmallDevice ? 6 : 8,
                      runSpacing: isSmallDevice ? 6 : 8,
                      alignment: WrapAlignment.center,
                      children: [
                        // Torch toggle
                        _ModernButton(
                          icon: _isTorchOn ? Icons.flash_on : Icons.flash_off,
                          label: isSmallDevice ? null : "Flash",
                          backgroundColor: _isTorchOn
                              ? Colors.amber
                              : Colors.grey.shade200,
                          foregroundColor: _isTorchOn
                              ? Colors.white
                              : Colors.grey.shade700,
                          isSmall: isSmallDevice,
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
                        ),

                        // Switch camera
                        _ModernButton(
                          icon: Icons.flip_camera_ios,
                          label: isSmallDevice ? null : "Balik",
                          backgroundColor: Colors.blue.shade100,
                          foregroundColor: Colors.blue.shade700,
                          isSmall: isSmallDevice,
                          onPressed: () async {
                            try {
                              await cameraController.switchCamera();
                            } catch (e) {
                              debugPrint("Error switching camera: $e");
                            }
                          },
                        ),

                        // Manual button - PERBAIKAN DI SINI
                        _ModernButton(
                          icon: Icons.keyboard,
                          label: "Manual",
                          backgroundColor: hijauGojek.withValues(alpha: 0.1),
                          foregroundColor: hijauGojek,
                          isSmall: isSmallDevice,
                          onPressed: _handleManualInput, // Panggil method baru
                        ),

                        // Close button
                        _ModernButton(
                          icon: Icons.close,
                          label: "Tutup",
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade700,
                          isSmall: isSmallDevice,
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool isSmall;

  const _ModernButton({
    required this.icon,
    this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    if (label == null || isSmall) {
      return Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmall ? 10 : 12),
            child: Icon(icon, color: foregroundColor, size: isSmall ? 20 : 22),
          ),
        ),
      );
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foregroundColor, size: 20),
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
