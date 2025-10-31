import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/in/in_detail_model.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProductDetailBottomSheet extends StatefulWidget {
  final InDetail product;
  final Function(InDetail) onSave;
  final Function() onCancel;

  const ProductDetailBottomSheet({
    required this.product,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  State<ProductDetailBottomSheet> createState() =>
      _ProductDetailBottomSheetState();
}

class _ProductDetailBottomSheetState extends State<ProductDetailBottomSheet> {
  late InDetail _editedProduct;
  final TextEditingController _ctnController = TextEditingController();
  final TextEditingController _pcsController = TextEditingController();
  final TextEditingController _kgController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ValueNotifier<String> _expiredDate = ValueNotifier("");
  final FocusNode _ctnFocus = FocusNode();
  final FocusNode _pcsFocus = FocusNode();
  final FocusNode _kgFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _editedProduct = InDetail.clone(widget.product);
    _initializeValues();
  }

  void _initializeValues() {
    _ctnController.text = (_editedProduct.qtctn ?? 0).toString();
    _pcsController.text = (_editedProduct.qtuom?.toInt() ?? 0).toString();
    _kgController.text = (_editedProduct.qtuom?.toStringAsFixed(2) ?? "0.00");
    _descriptionController.text = _editedProduct.descr ?? "";
    _expiredDate.value = _editedProduct.vfdat ?? "";
  }

  void _updateQuantity(String type, String value) {
    final numValue = num.tryParse(value) ?? 0;

    setState(() {
      switch (type) {
        case "ctn":
          _editedProduct.qtctn = numValue.toInt();
          break;
        case "pcs":
          _editedProduct.qtuom = numValue.toDouble();
          break;
        case "kg":
          _editedProduct.qtuom = numValue.toDouble();
          break;
      }
    });
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _expiredDate.value = DateFormat('yyyyMMdd').format(picked);
      _editedProduct.vfdat = _expiredDate.value;
    }
  }

  void _saveChanges() {
    // Validasi
    if (_expiredDate.value.isEmpty) {
      Fluttertoast.showToast(
        msg: "Harap pilih tanggal kedaluwarsa",
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Update product dengan nilai terbaru
    _editedProduct.qtctn = int.tryParse(_ctnController.text) ?? 0;

    if (_editedProduct.pounitori == "KG") {
      _editedProduct.qtuom = double.tryParse(_kgController.text) ?? 0.0;
    } else {
      _editedProduct.qtuom = double.tryParse(_pcsController.text) ?? 0.0;
    }

    _editedProduct.vfdat = _expiredDate.value;
    _editedProduct.descr = _descriptionController.text;
    _editedProduct.updated = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.now());
    _editedProduct.updatedByUsername = "Current User";

    widget.onSave(_editedProduct);
    Navigator.of(context).pop();
  }

  String _formatDate(String date) {
    try {
      if (date.length == 8) {
        // Format: yyyyMMdd
        final year = date.substring(0, 4);
        final month = date.substring(4, 6);
        final day = date.substring(6, 8);
        return '$day-$month-$year';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isImportant = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isImportant ? FontWeight.w600 : FontWeight.w400,
                color: isImportant ? hijauGojek : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField({
    required String label,
    required String unit,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String) onChanged,
    bool isKg = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.numberWithOptions(decimal: isKg),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: '0${isKg ? '.00' : ''}',
                  ),
                  onChanged: onChanged,
                ),
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: hijauGojek.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(8),
                  ),
                ),
                child: Center(
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hijauGojek,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: screenHeight * 0.9, // 90% tinggi layar
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max, // Ubah ke max agar full height
        children: [
          // HEADER - FIXED
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: hijauGojek,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit Product",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Update quantity dan informasi product",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onCancel();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // CONTENT - SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          "Product ID",
                          _editedProduct.mProductId ?? "-",
                          isImportant: true,
                        ),
                        _buildInfoRow(
                          "Nama Product",
                          _editedProduct.maktxUI ?? "-",
                          isImportant: true,
                        ),
                        _buildInfoRow("Unit", _editedProduct.pounitori ?? "-"),
                        if (_editedProduct.poqtyori != null)
                          _buildInfoRow(
                            "Qty PO",
                            "${_editedProduct.poqtyori} ${_editedProduct.pounitori}",
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quantity Section
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_editedProduct.pounitori == "KG")
                    _buildQuantityField(
                      label: "Quantity (KG)",
                      unit: "KG",
                      controller: _kgController,
                      focusNode: _kgFocus,
                      onChanged: (value) => _updateQuantity("kg", value),
                      isKg: true,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuantityField(
                            label: "CTN",
                            unit: "CTN",
                            controller: _ctnController,
                            focusNode: _ctnFocus,
                            onChanged: (value) => _updateQuantity("ctn", value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuantityField(
                            label: "PCS",
                            unit: "PCS",
                            controller: _pcsController,
                            focusNode: _pcsFocus,
                            onChanged: (value) => _updateQuantity("pcs", value),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Expiry Date
                  GestureDetector(
                    onTap: _selectExpiryDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Kedaluwarsa',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<String>(
                                valueListenable: _expiredDate,
                                builder: (context, value, child) {
                                  return Text(
                                    value.isEmpty
                                        ? "Pilih Tanggal"
                                        : _formatDate(value),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: value.isEmpty
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Icon(Icons.calendar_today, color: hijauGojek),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Catatan Tambahan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      _editedProduct.descr = value;
                    },
                  ),

                  const SizedBox(height: 100), // Extra space untuk button
                ],
              ),
            ),
          ),

          // ACTION BUTTONS - FIXED
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onCancel();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: hijauGojek),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Batal', style: TextStyle(color: hijauGojek)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijauGojek,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ctnController.dispose();
    _pcsController.dispose();
    _kgController.dispose();
    _descriptionController.dispose();
    _ctnFocus.dispose();
    _pcsFocus.dispose();
    _kgFocus.dispose();
    super.dispose();
  }
}

class ImprovedCameraScannerDialog extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final Function() onCancel;

  const ImprovedCameraScannerDialog({
    required this.onBarcodeDetected,
    required this.onCancel,
    super.key,
  });

  @override
  State<ImprovedCameraScannerDialog> createState() =>
      _ImprovedCameraScannerDialogState();
}

class _ImprovedCameraScannerDialogState
    extends State<ImprovedCameraScannerDialog> {
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
            // CAMERA VIEW
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

            // DYNAMIC GREEN FRAME (AUTO ADAPT)
            if (_detectedBarcode?.corners != null)
              CustomPaint(
                painter: BarcodeOverlayPainter(_detectedBarcode!),
                size: const Size(double.infinity, double.infinity),
              ),

            // TORCH BUTTON
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

class BarcodeOverlayPainter extends CustomPainter {
  final Barcode barcode;

  BarcodeOverlayPainter(this.barcode);

  @override
  void paint(Canvas canvas, Size size) {
    final corners = barcode.corners;
    if (corners.isEmpty || corners.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(corners.first.dx, corners.first.dy);
    for (final point in corners.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Add glowing edges
    final glow = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.4)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
