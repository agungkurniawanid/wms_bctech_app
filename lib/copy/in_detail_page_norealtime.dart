import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/number_helper.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_detail_model.dart';
import 'package:wms_bctech/models/grin/good_receive_serial_number_model.dart';
import 'package:wms_bctech/models/in/in_detail_model.dart';
import 'package:wms_bctech/models/in/in_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/pages/my_dialog_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/widgets/product_detail_bottomsheet_widget.dart';
import 'package:wms_bctech/widgets/scanner_dialog_widget.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

class InDetailPage extends StatefulWidget {
  final int index;
  final String from;
  final InModel? flag;

  const InDetailPage(this.index, this.from, this.flag, {super.key});

  @override
  State<InDetailPage> createState() => _InDetailPageState();
}

class _InDetailPageState extends State<InDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  bool allow = true;
  int idPeriodSelected = 1;
  final List<String> sortList = ['PO Date', 'Vendor'];
  final InVM inVM = Get.find();
  final List<ItemChoice> listchoice = [];
  final List<Category> listcategory = [];
  late final ScrollController scrollController;
  late InModel cloned;
  late InModel forclose;
  bool leading = true;
  bool checkingscan = false;
  final GlobalKey srKey = GlobalKey();
  final GlobalKey<FormState> keypcs = GlobalKey<FormState>();
  final pcsFieldKey = GlobalKey<FormFieldState<String>>();
  TextEditingController pcsinput = TextEditingController();
  TextEditingController ctninput = TextEditingController();
  TextEditingController expiredinput = TextEditingController();
  TextEditingController palletinput = TextEditingController();
  TextEditingController descriptioninput = TextEditingController();
  final TextEditingController containerinput = TextEditingController();
  final descriptioninputkey = GlobalKey<FormFieldState<String>>();
  final formKey = GlobalKey<FormState>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController? _controllerctn;
  TextEditingController? _controllerpcs;
  TextEditingController? _controllerkg;

  int typeIndexctn = 0;
  int typeIndexpcs = 0;
  double typeIndexkg = 0.0;
  String datetime = "";

  final List<TextEditingController> listpcsinput = [];
  final List<TextEditingController> listctninput = [];
  final List<TextEditingController> listpallet = [];
  final List<TextEditingController> listexpired = [];
  final List<TextEditingController> listdesc = [];

  int tabs = 0;
  bool anyum = false;
  final List<InDetail> listindetaillocal = [];
  final InModel listinmodel = InModel();

  final ValueNotifier<String> expireddate = ValueNotifier("");
  final ValueNotifier<int> pcs = ValueNotifier(0);
  final ValueNotifier<int> ctn = ValueNotifier(0);
  final ValueNotifier<double> kg = ValueNotifier(0);

  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();
  TextEditingController _searchQuery = TextEditingController();
  String? searchQuery;

  final NumberFormat currency = NumberFormat("#,###", "en_US");
  final NumberFormat currencydecimal = NumberFormat("#,###.##", "en_US");
  DateTime? date;

  String? ebeln;
  String? barcodeScanRes;

  final RxList<InDetail> detailsList = <InDetail>[].obs;
  final RxBool isDetailsLoading = false.obs;
  final RxString detailsError = ''.obs;

  final Map<int, Widget> myTabs = const {
    0: Text("CTN"),
    1: Text("PCS"),
    2: Text("KG"),
  };

  final Map<int, Widget> myTabs2 = const {0: Text("KG")};
  final GlobalVM globalVM = Get.find();

  String barcodeString = "Barcode will be shown here";
  String barcodeSymbology = "Symbology will be shown here";
  String scanTime = "Scan Time will be shown here";
  bool isScanning = false;
  String qrScanResult = "";
  String scannedSerialNumber = "";
  MobileScannerController? _mobileScannerController;
  final ValueNotifier<bool> _isTorchOn = ValueNotifier<bool>(false);
  final TextEditingController _serialNumberController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _documentNoController = TextEditingController();
  final ValueNotifier<int> _quantity = ValueNotifier<int>(1);

  @override
  void initState() {
    super.initState();
    _searchQuery = TextEditingController();
    containerinput.text = '';
    isScanning = false;
    qrScanResult = "";
    _serialNumberController.addListener(_onSerialNumberChanged);
    _qtyController.text = "1";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWithRealData();
    });

    _loadDetails();
  }

  // Fungsi untuk memuat details berdasarkan documentno dari flag
  Future<void> _loadDetails() async {
    try {
      isDetailsLoading.value = true;
      detailsError.value = '';
      final String documentNo = widget.flag?.documentno ?? '';

      if (documentNo.isEmpty) {
        detailsError.value = 'Document number not found';
        return;
      }

      final List<InDetail> details = await inVM.getDetailsByDocumentNo(
        documentNo,
      );

      detailsList.assignAll(details);

      if (details.isEmpty) {
        detailsError.value = 'No details found for this document';
      }
    } catch (e) {
      detailsError.value = 'Error loading details: $e';
      debugPrint('Error loading details: $e');
    } finally {
      isDetailsLoading.value = false;
    }
  }

  Future<void> _handleRefresh() async {
    try {
      // Tampilkan loading indicator
      setState(() {
        isDetailsLoading.value = true;
      });

      // Reload data details
      await _loadDetails();

      // Juga reload data utama jika diperlukan
      if (widget.from == "sync") {
        // Untuk data sync, reload dari flag
        if (widget.flag != null) {
          setState(() {
            // Refresh data lokal dari flag
            listindetaillocal.clear();
            listindetaillocal.addAll(widget.flag?.details ?? []);
          });
        }
      } else {
        // Untuk data normal, trigger reload di controller
        await inVM.refreshData();
      }

      // Tampilkan feedback sukses
      Logger().i('Data berhasil diperbarui.');
    } catch (e) {
      // Tampilkan feedback error
      Logger().e('Error during refresh: $e');
    } finally {
      if (mounted) {
        setState(() {
          isDetailsLoading.value = false;
        });
      }
    }
  }

  void _initializeWithRealData() {
    if (widget.from == "sync") {
      ebeln = widget.flag?.documentno;
      cloned = InModel.clone(widget.flag!);
      forclose = InModel.clone(widget.flag!);
    } else {
      // Gunakan data dari controller, bukan dummy data
      if (inVM.tolistPO.length > widget.index) {
        final realData = inVM.tolistPO[widget.index];
        ebeln = realData.documentno;
        cloned = InModel.clone(realData);
        forclose = InModel.clone(realData);
      }
    }
  }

  // Future<bool> _ensureCameraPermissionAndStart() async {
  //   final status = await Permission.camera.status;
  //   if (!status.isGranted) {
  //     final result = await Permission.camera.request();
  //     if (!result.isGranted) {
  //       Fluttertoast.showToast(
  //         msg: "Izin kamera diperlukan untuk memindai barcode",
  //         backgroundColor: hijauGojek,
  //         textColor: Colors.white,
  //       );
  //       return false;
  //     }
  //   }
  //   try {
  //     await _mobileScannerController!.start();
  //     return true;
  //   } catch (e) {
  //     debugPrint("Gagal memulai controller: $e");
  //     Fluttertoast.showToast(
  //       msg: "Gagal memulai kamera: $e",
  //       backgroundColor: hijauGojek,
  //       textColor: Colors.white,
  //     );
  //     Logger().e(e);
  //     return false;
  //   }
  // }

  void handleBarcodeScan(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    if (barcodes.isNotEmpty && mounted) {
      final String barcodeString = barcodes.first.rawValue ?? "";

      setState(() {
        if (!checkingscan && barcodeString.isNotEmpty) {
          pcsinput = TextEditingController();
          ctninput = TextEditingController();
          expiredinput = TextEditingController();
          palletinput = TextEditingController();
          descriptioninput = TextEditingController();
          List<InDetail> barcode;
          if (widget.from == "sync") {
            final tData = widget.flag?.details ?? [];
            barcode = tData
                .where(
                  (element) =>
                      (element.mProductId ?? '').contains(barcodeString),
                )
                .toList();
          } else {
            final currentData = _getCurrentInModel();
            final tData = currentData.details ?? [];
            barcode = tData
                .where(
                  (element) =>
                      (element.mProductId ?? '').contains(barcodeString),
                )
                .toList();
          }

          if (barcode.isNotEmpty) {
            pcs.value = barcode[0].qtuom?.toInt() ?? 0;
            ctn.value = barcode[0].qtctn ?? 0;
            kg.value = barcode[0].qtuom ?? 0.0;

            typeIndexctn = ctn.value;
            typeIndexpcs = pcs.value;
            typeIndexkg = kg.value;
            expireddate.value = barcode[0].vfdat ?? "";

            checkingscan = true;

            _mobileScannerController!.stop();
            isScanning = false;
            Navigator.of(context).pop();

            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => PopScope<Object?>(
                canPop: true,
                onPopInvokedWithResult: (bool didPop, Object? result) {
                  if (!mounted) return;
                  setState(() {
                    checkingscan = false;
                  });
                },
                child: modalBottomSheet(barcode[0]),
              ),
            );
          } else {
            Fluttertoast.showToast(
              msg: "Barcode tidak ditemukan dalam data",
              backgroundColor: Colors.orange,
              textColor: Colors.white,
            );
          }
        }
      });
    }
  }

  InModel _getCurrentInModel() {
    if (widget.from == "sync") {
      return widget.flag!;
    } else {
      return inVM.tolistPO[widget.index];
    }
  }

  Future<void> startMobileScan() async {
    if (isScanning) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Metode Scan"),
        content: const Text(
          "Pilih metode yang ingin digunakan untuk memindai barcode",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualBarcodeInput();
            },
            child: const Text("Input Manual"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startCameraScanImproved(); // Panggil method yang diperbaiki
            },
            child: const Text("Kamera HP"),
          ),
        ],
      ),
    );
  }

  // Method baru untuk camera scan yang lebih baik
  Future<void> _startCameraScanImproved() async {
    if (isScanning) return;

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        Fluttertoast.showToast(
          msg: "Izin kamera diperlukan untuk memindai barcode",
          backgroundColor: hijauGojek,
          textColor: Colors.white,
        );
        return;
      }
    }

    setState(() {
      isScanning = true;
    });

    // Gunakan approach yang lebih sederhana dan reliable
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImprovedCameraScannerDialog(
          onBarcodeDetected: (barcode) {
            // Process barcode dan dialog akan otomatis tertutup di _processBarcodeResult
            _processBarcodeResult(barcode);
          },
          onCancel: () {
            setState(() {
              isScanning = false;
            });
          },
        ),
      );
    }

    setState(() {
      isScanning = false;
    });
  }

  void _showManualBarcodeInput() {
    TextEditingController manualController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Input Barcode Manual"),
        content: TextField(
          controller: manualController,
          decoration: const InputDecoration(
            labelText: 'Masukkan kode barcode',
            border: OutlineInputBorder(),
            hintText: 'Contoh: SKU-001, SKU-002, dll.',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop();
              _processBarcodeResult(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              if (manualController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _processBarcodeResult(manualController.text);
              }
            },
            child: const Text("Scan"),
          ),
        ],
      ),
    );
  }

  List<InDetail> _findProductByBarcode(String barcode) {
    // Gunakan detailsList yang sudah di-load dari API
    final allProducts = detailsList;

    if (allProducts.isEmpty) {
      debugPrint('Details list is empty');
      return [];
    }

    debugPrint('Searching for barcode: $barcode');
    debugPrint('Total products in list: ${allProducts.length}');

    final foundProducts = allProducts.where((product) {
      final productId = product.mProductId?.toLowerCase() ?? '';
      final productName = product.maktxUI?.toLowerCase() ?? '';
      final matnr = product.matnr?.toLowerCase() ?? '';
      final searchBarcode = barcode.trim().toLowerCase();

      debugPrint('Checking product: $productId | $productName | $matnr');

      // Prioritaskan pencarian exact match di mProductId
      if (productId == searchBarcode) {
        debugPrint('Exact match found in mProductId: $productId');
        return true;
      }

      // Kemudian partial match
      if (productId.contains(searchBarcode) ||
          productName.contains(searchBarcode) ||
          matnr.contains(searchBarcode)) {
        debugPrint('Partial match found: $productName');
        return true;
      }

      return false;
    }).toList();

    debugPrint('Found ${foundProducts.length} products');
    return foundProducts;
  }

  // Ganti method _processBarcodeResult dengan yang ini
  Future<void> _processBarcodeResult(String barcodeString) async {
    if (!mounted) return;

    setState(() {
      isScanning = false;
    });

    final trimmedBarcode = barcodeString.trim();

    if (trimmedBarcode.isEmpty) {
      Fluttertoast.showToast(
        msg: "Barcode tidak valid",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    debugPrint('Processing barcode: $trimmedBarcode');

    // Pastikan data sudah ter-load
    if (detailsList.isEmpty) {
      debugPrint('Loading details first...');
      await _loadDetails();
    }

    List<InDetail> foundProducts = _findProductByBarcode(trimmedBarcode);

    if (foundProducts.isNotEmpty) {
      InDetail product = foundProducts.first;
      debugPrint('Product found: ${product.maktxUI}');

      if (!mounted) return;
      // TUTUP DIALOG CAMERA SEBELUM menampilkan bottom sheet
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Tutup dialog camera
      }

      // Tunggu sebentar untuk memastikan dialog tertutup
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      setState(() {
        // Reset values terlebih dahulu
        pcs.value = 0;
        ctn.value = 0;
        kg.value = 0.0;
        typeIndexctn = 0;
        typeIndexpcs = 0;
        typeIndexkg = 0.0;
        expireddate.value = "";
        descriptioninput.text = product.descr ?? "";

        // Set values dari product yang ditemukan
        if (product.pounitori == "KG") {
          kg.value = product.qtuom ?? 0.0;
          typeIndexkg = kg.value;
        } else {
          pcs.value = product.qtuom?.toInt() ?? 0;
          ctn.value = product.qtctn ?? 0;
          typeIndexpcs = pcs.value;
          typeIndexctn = ctn.value;
        }

        expireddate.value = product.vfdat ?? "";
        checkingscan = true;
      });

      // Tampilkan bottom sheet
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ProductDetailBottomSheet(
            product: product,
            onSave: _saveProductChanges,
            onCancel: () {
              setState(() {
                checkingscan = false;
              });
            },
          ),
        );
      }
    } else {
      debugPrint('No product found for barcode: $trimmedBarcode');
      Fluttertoast.showToast(
        msg: "Product dengan barcode '$trimmedBarcode' tidak ditemukan",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );

      if (!mounted) return;
      // Tutup dialog camera juga untuk kasus tidak ditemukan
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showProductNotFoundDialog(trimmedBarcode);
    }
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Product Tidak Ditemukan"),
        content: Text(
          "Product dengan barcode '$barcode' tidak ditemukan dalam daftar PO. Apakah Anda ingin menambahkannya secara manual?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addManualProduct(barcode);
            },
            child: const Text("Tambah Manual"),
          ),
        ],
      ),
    );
  }

  void _addManualProduct(String barcode) {
    final newProduct = InDetail(
      mProductId: barcode,
      maktxUI: "Product Manual: $barcode",
      pounitori: "PCS",
      umrez: 1,
      qtctn: 0,
      qtuom: 0.0,
      qtyordered: 0.0,
      vfdat: "",
      descr: "Ditambahkan via scan barcode",
    );

    // Tampilkan ProductDetailBottomSheet untuk product manual
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProductDetailBottomSheet(
          product: newProduct,
          onSave: _saveProductChanges,
          onCancel: () {
            setState(() {
              checkingscan = false;
            });
          },
        ),
      );
    }
  }

  Future<void> scanBarcode() async {
    if (isScanning) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Metode Scan"),
        content: const Text(
          "Pilih metode yang ingin digunakan untuk memindai barcode",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showManualBarcodeInput();
            },
            child: const Text("Input Manual"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startCameraScanImproved(); // Gunakan method yang diperbaiki
            },
            child: const Text("Kamera HP"),
          ),
        ],
      ),
    );
  }

  // Future<void> _startCameraScan() async {
  //   if (isScanning) return;
  //   var status = await Permission.camera.status;
  //   if (!status.isGranted) {
  //     status = await Permission.camera.request();
  //     if (!status.isGranted) {
  //       Fluttertoast.showToast(
  //         msg: "Izin kamera diperlukan untuk memindai barcode",
  //         backgroundColor: hijauGojek,
  //         textColor: Colors.white,
  //       );
  //       return;
  //     }
  //   }

  //   setState(() {
  //     isScanning = true;
  //   });

  //   if (mounted) {
  //     await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => CameraScannerDialog(
  //         onBarcodeDetected: (barcode) {
  //           // Langsung panggil _processBarcodeResult yang sudah menggunakan ProductDetailBottomSheet
  //           _processBarcodeResult(barcode);
  //           Navigator.of(context).pop();
  //         },
  //         onCancel: () {
  //           setState(() {
  //             isScanning = false;
  //           });
  //         },
  //       ),
  //     );
  //   }

  //   setState(() {
  //     isScanning = false;
  //   });
  // }

  void showExternalScannerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scanner Eksternal"),
        content: const Text(
          "Sambungkan scanner eksternal dan tekan tombol scan. Atau masukkan barcode secara manual:",
        ),
        actions: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Kode Barcode',
              border: OutlineInputBorder(),
            ),
            onFieldSubmitted: (value) {
              if (value.isNotEmpty) {
                _simulateBarcodeScan(value);
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () {
                  _simulateExternalScanner();
                },
                child: const Text("Scan"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _simulateBarcodeScan(String barcode) {
    final simulatedDetail = InDetail(
      mProductId: barcode,
      maktxUI: "Product from Scan: $barcode",
      pounitori: "PCS",
      umrez: 10,
      qtctn: 1,
      qtuom: 10.0,
      qtyordered: 100.0,
      vfdat: "20241231",
      descr: "Scanned product",
    );

    // Tampilkan ProductDetailBottomSheet untuk simulated product
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProductDetailBottomSheet(
          product: simulatedDetail,
          onSave: _saveProductChanges,
          onCancel: () {
            setState(() {
              checkingscan = false;
            });
          },
        ),
      );
    }
  }

  void _simulateExternalScanner() {
    final externalBarcodes = ["EXT-001", "EXT-002", "EXT-003"];
    final randomBarcode =
        externalBarcodes[DateTime.now().millisecond % externalBarcodes.length];
    _simulateBarcodeScan(randomBarcode);
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    _mobileScannerController?.dispose();
    _serialNumberController.dispose();
    _qtyController.dispose();
    _productNameController.dispose();
    _documentNoController.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _onSerialNumberChanged() {
    setState(() {
      scannedSerialNumber = _serialNumberController.text;
    });
  }

  // Update method untuk menghitung total dari detailsList
  String _calculateTotalPcs() {
    final total = detailsList.fold<double>(
      0,
      (currentSum, item) => currentSum + (item.qtuom ?? 0),
    );
    return total.toStringAsFixed(2);
  }

  Future<void> _startQRScan(InDetail product) async {
    if (isScanning) return;

    // Request camera permission
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        Fluttertoast.showToast(
          msg: "Izin kamera diperlukan untuk memindai QR Code",
          backgroundColor: hijauGojek,
          textColor: Colors.white,
        );
        return;
      }
    }

    setState(() {
      isScanning = true;
      scannedSerialNumber = "";
    });

    // Reset controllers
    _serialNumberController.clear();
    _qtyController.text = "1";
    _quantity.value = 1;

    // Set product info
    _productNameController.text = product.maktxUI ?? product.mProductId ?? "";
    _documentNoController.text = widget.from == "sync"
        ? widget.flag?.documentno ?? ""
        : _getCurrentInModel().documentno ?? "";

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => QRScannerDialog(
          onQRCodeDetected: (qrCode) {
            // Process QR code and show bottom sheet
            _processQRCodeResult(qrCode, product);
          },
          onClose: () {
            setState(() {
              isScanning = false;
            });
            Navigator.of(context).pop();
          },
        ),
      );
    }

    setState(() {
      isScanning = false;
    });
  }

  Widget _buildScanResultBottomSheet(InDetail product) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hasil Scan QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hijauGojek,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Document No
            _buildReadOnlyField(
              label: "Document No PO",
              value: _documentNoController.text,
              icon: Icons.description,
            ),

            SizedBox(height: 16),

            // Product Name
            _buildReadOnlyField(
              label: "Nama Product",
              value: _productNameController.text,
              icon: Icons.inventory_2,
            ),

            SizedBox(height: 16),

            // Serial Number
            TextFormField(
              controller: _serialNumberController,
              decoration: InputDecoration(
                labelText: "Serial Number",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_2),
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () => _restartScanner(product),
                ),
              ),
              readOnly: true, // Make it read-only since it comes from scanner
            ),

            SizedBox(height: 16),

            // Quantity Section
            Text(
              "Quantity",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            SizedBox(height: 12),

            ValueListenableBuilder<int>(
              valueListenable: _quantity,
              builder: (context, quantity, child) {
                return Row(
                  children: [
                    // Decrement button
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            _quantity.value--;
                            _qtyController.text = _quantity.value.toString();
                          }
                        },
                      ),
                    ),

                    SizedBox(width: 16),

                    // Quantity input
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Jumlah",
                        ),
                        onChanged: (value) {
                          final qty = int.tryParse(value) ?? 1;
                          _quantity.value = qty;
                        },
                      ),
                    ),

                    SizedBox(width: 16),

                    // Increment button
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _quantity.value++;
                          _qtyController.text = _quantity.value.toString();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                // Close button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetForm();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: hijauGojek),
                    ),
                    child: Text('Close', style: TextStyle(color: hijauGojek)),
                  ),
                ),

                SizedBox(width: 12),

                // Save button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveScanResult(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijauGojek,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Save & Scan Lagi',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _restartScanner(InDetail product) {
    // Close current bottom sheet
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Restart scanner
    _startQRScan(product);
  }

  void _saveScanResult(InDetail product) async {
    final serialNumber = _serialNumberController.text.trim();
    final quantity = _quantity.value;

    if (serialNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "Serial number tidak boleh kosong untuk scan QR",
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (quantity <= 0) {
      Fluttertoast.showToast(
        msg: "Quantity harus lebih dari 0",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      // Show loading
      setState(() {
        isScanning = false;
      });

      // Save to Firestore
      await _saveToFirestore(product, serialNumber, quantity);

      // Show success message
      Fluttertoast.showToast(
        msg: "Serial number berhasil disimpan: $serialNumber x$quantity",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Restart scanner for next item
      _restartScanner(product);
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: "Gagal menyimpan: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );

      // Restart scanner anyway
      _restartScanner(product);
    }
  }

  void _resetForm() {
    _serialNumberController.clear();
    _qtyController.text = "1";
    _quantity.value = 1;
    scannedSerialNumber = "";
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _processQRCodeResult(String qrCode, InDetail product) {
    if (!mounted) return;

    setState(() {
      scannedSerialNumber = qrCode;
      _serialNumberController.text = qrCode;
    });

    // Close scanner dialog first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Wait a bit then show bottom sheet
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showScanResultBottomSheet(product);
      }
    });
  }

  void _showScanResultBottomSheet(InDetail product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildScanResultBottomSheet(product),
    ).then((_) {
      // When bottom sheet is closed, restart scanner if needed
      setState(() {
        isScanning = false;
      });
    });
  }

  // Update method search untuk menggunakan detailsList
  void searchWF(String search) async {
    final query = search.toLowerCase();

    if (search.isEmpty) {
      // Reset ke semua data
      _loadDetails();
      return;
    }

    final filteredList = detailsList.where((e) {
      final name = e.maktxUI?.toLowerCase() ?? '';
      final sku = e.mProductId?.toLowerCase() ?? '';
      return name.contains(query) || sku.contains(query);
    }).toList();

    // Untuk sementara, kita assign filtered list ke observable
    // Dalam implementasi real, Anda mungkin ingin membuat list terpisah untuk filtered data
    if (filteredList.isNotEmpty) {
      detailsList.assignAll(filteredList);
    }
  }

  String calculateTotalCtn() {
    final currentModel = _getCurrentInModel();
    final tData = currentModel.details ?? [];

    final total = tData.fold<int>(
      0,
      (currentSum, item) => currentSum + (item.qtctn ?? 0),
    );
    return total.toString();
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery.text.isEmpty) {
              setState(_stopSearching);
            } else {
              _clearSearchQuery();
            }
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        onPressed: scanBarcode,
      ),
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: _startSearch,
      ),
    ];
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchQuery,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: updateSearchQuery,
    );
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      searchWF(newQuery);
    });
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget untuk empty state
  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No Products Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  detailsError.value.isNotEmpty
                      ? detailsError.value
                      : 'No product details available for this purchase order',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
                SizedBox(height: 20),
                if (detailsError.value.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _handleRefresh, // Gunakan method refresh
                    icon: Icon(Icons.refresh),
                    label: Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijauGojek,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startSearch() {
    setState(() {
      listindetaillocal.clear();

      final sourceData = widget.from == "sync"
          ? (widget.flag?.details ?? [])
          : (_getCurrentInModel().details ?? []);

      listindetaillocal.addAll(sourceData);
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();
    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchQuery.clear();
      _isSearching = false;

      final sourceData = listindetaillocal;

      if (widget.from == "sync") {
        widget.flag?.details?.clear();
        widget.flag?.details?.addAll(sourceData);
      } else {
        final currentModel = _getCurrentInModel();
        final tData = currentModel.details ?? [];
        tData.clear();
        tData.addAll(sourceData);
      }
    });
  }

  Widget modalBottomSheet(InDetail indetail) {
    double baseWidth = 360;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        height: MediaQuery.of(context).size.height * 0.85,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16 * fem),
              decoration: BoxDecoration(
                color: hijauGojek.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Product',
                    style: TextStyle(
                      fontSize: 18 * ffem,
                      fontWeight: FontWeight.bold,
                      color: hijauGojek,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.all(16 * fem),
              height: 120 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Center(
                child: Icon(
                  Icons.inventory_2,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16 * fem),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      "Material",
                      indetail.mProductId ?? "-",
                      fem,
                      ffem,
                    ),
                    _buildDetailRow(
                      "Description",
                      indetail.maktxUI ?? "-",
                      fem,
                      ffem,
                    ),

                    SizedBox(height: 16 * fem),
                    Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 16 * ffem,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    SizedBox(height: 12 * fem),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuantitySelector(
                          "CTN",
                          ctn.value.toString(),
                          () {
                            _showQuantityDialog(indetail, "ctn");
                          },
                          fem,
                          ffem,
                        ),
                        _buildQuantitySelector(
                          "PCS",
                          pcs.value.toString(),
                          () {
                            _showQuantityDialog(indetail, "pcs");
                          },
                          fem,
                          ffem,
                        ),
                        _buildQuantitySelector(
                          "KG",
                          kg.value.toStringAsFixed(2),
                          () {
                            _showQuantityDialog(indetail, "kg");
                          },
                          fem,
                          ffem,
                        ),
                      ],
                    ),

                    SizedBox(height: 24 * fem),
                    GestureDetector(
                      onTap: () => _selectExpiryDate(),
                      child: Container(
                        padding: EdgeInsets.all(16 * fem),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expiry Date',
                                  style: TextStyle(
                                    fontSize: 14 * ffem,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 4 * fem),
                                ValueListenableBuilder<String>(
                                  valueListenable: expireddate,
                                  builder: (context, value, child) {
                                    return Text(
                                      value.isEmpty
                                          ? "Select Date"
                                          : DateHelper.formatDate(value),
                                      style: TextStyle(
                                        fontSize: 16 * ffem,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16 * fem),
                    TextFormField(
                      controller: descriptioninput,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.all(16 * fem),
                      ),
                      maxLines: 3,
                    ),

                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16 * fem),
                              side: BorderSide(color: hijauGojek),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: hijauGojek),
                            ),
                          ),
                        ),
                        SizedBox(width: 12 * fem),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _saveProductChanges(indetail),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hijauGojek,
                              padding: EdgeInsets.symmetric(vertical: 16 * fem),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
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

  Widget _buildDetailRow(String label, String value, double fem, double ffem) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * fem),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120 * fem,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14 * ffem,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14 * ffem,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(
    String label,
    String value,
    VoidCallback onTap,
    double fem,
    double ffem,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12 * fem),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18 * ffem,
                fontWeight: FontWeight.bold,
                color: hijauGojek,
              ),
            ),
            SizedBox(height: 4 * fem),
            Text(
              label,
              style: TextStyle(
                fontSize: 12 * ffem,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        expireddate.value = DateFormat('yyyyMMdd').format(picked);
      });
    }
  }

  void _showQuantityDialog(InDetail indetail, String type) {
    _showMyDialog(indetail, type);
  }

  void _saveProductChanges(InDetail indetail) {
    // Cari index product dalam detailsList
    final index = detailsList.indexWhere(
      (item) => item.mProductId == indetail.mProductId,
    );

    if (index != -1) {
      setState(() {
        // Update data di detailsList
        detailsList[index] = indetail;
      });

      // Juga update di data utama jika diperlukan
      final currentModel = _getCurrentInModel();
      if (currentModel.details != null) {
        final detailIndex = currentModel.details!.indexWhere(
          (item) => item.mProductId == indetail.mProductId,
        );
        if (detailIndex != -1) {
          currentModel.details![detailIndex] = indetail;
        }
      }

      Fluttertoast.showToast(
        msg: "Product berhasil diupdate",
        backgroundColor: Colors.green,
      );
    } else {
      Fluttertoast.showToast(
        msg: "Gagal mengupdate product",
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildModernProductCard(InDetail indetail, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hijauGojek.withValues(alpha: 0.3), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: hijauGojek.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.inventory_2,
                          color: hijauGojek,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              indetail.maktxUI ?? "Product Name",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              indetail.mProductId ?? "SKU",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // todo: dont delete this
                        // _buildQuantityChip("CTN", "${indetail.qtctn ?? 0}"),
                        _buildQuantityChip(
                          "UNIT",
                          "${indetail.qtyordered?.toInt() ?? 0}",
                        ),

                        // todo: dont delete this
                        // if (indetail.vfdat?.isNotEmpty ?? false)
                        //   _buildQuantityChip(
                        //     "EXP",
                        //     _formatDate(indetail.vfdat!),
                        //   ),
                      ],
                    ),
                  ),
                  if (indetail.descr?.isNotEmpty ?? false) ...[
                    SizedBox(height: 8),
                    Text(
                      indetail.descr!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.from != "history")
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      colors: [hijauGojek.withValues(alpha: 0.3), hijauGojek],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _startQRScan(indetail),
                      ),
                      IconButton(
                        icon: Icon(Icons.keyboard, color: Colors.white),
                        onPressed: () => _startManualInput(indetail),
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

  void _startManualInput(InDetail product) {
    // Reset controllers untuk input manual
    _serialNumberController.clear();
    _qtyController.text = "1";
    _quantity.value = 1;

    // Set product info
    _productNameController.text = product.maktxUI ?? product.mProductId ?? "";
    _documentNoController.text = widget.from == "sync"
        ? widget.flag?.documentno ?? ""
        : _getCurrentInModel().documentno ?? "";

    // Tampilkan bottom sheet untuk input manual
    _showManualInputBottomSheet(product);
  }

  void _showManualInputBottomSheet(InDetail product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildManualInputBottomSheet(product),
    ).then((_) {
      // Reset state ketika bottom sheet ditutup
      setState(() {
        isScanning = false;
      });
    });
  }

  Widget _buildManualInputBottomSheet(InDetail product) {
    return SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Input Manual Serial Number',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hijauGojek,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Document No
            _buildReadOnlyField(
              label: "Document No PO",
              value: _documentNoController.text,
              icon: Icons.description,
            ),

            SizedBox(height: 16),

            // Product Name
            _buildReadOnlyField(
              label: "Nama Product",
              value: _productNameController.text,
              icon: Icons.inventory_2,
            ),

            SizedBox(height: 16),

            // Serial Number (bisa kosong/null)
            TextFormField(
              controller: _serialNumberController,
              decoration: InputDecoration(
                labelText: "Serial Number (Opsional)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code_2),
                hintText: "Kosongkan jika tidak ada serial number",
              ),
              // Bisa dikosongkan untuk input manual
            ),

            SizedBox(height: 16),

            // Quantity Section
            Text(
              "Quantity",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            SizedBox(height: 12),

            ValueListenableBuilder<int>(
              valueListenable: _quantity,
              builder: (context, quantity, child) {
                return Row(
                  children: [
                    // Decrement button
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            _quantity.value--;
                            _qtyController.text = _quantity.value.toString();
                          }
                        },
                      ),
                    ),

                    SizedBox(width: 16),

                    // Quantity input
                    Expanded(
                      child: TextFormField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Jumlah",
                        ),
                        onChanged: (value) {
                          final qty = int.tryParse(value) ?? 1;
                          _quantity.value = qty;
                        },
                      ),
                    ),

                    SizedBox(width: 16),

                    // Increment button
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          _quantity.value++;
                          _qtyController.text = _quantity.value.toString();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                // Close button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _resetForm();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: hijauGojek),
                    ),
                    child: Text('Close', style: TextStyle(color: hijauGojek)),
                  ),
                ),

                SizedBox(width: 12),

                // Save button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveManualInput(product),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hijauGojek,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveManualInput(InDetail product) async {
    final serialNumber = _serialNumberController.text.trim();
    final quantity = _quantity.value;

    if (quantity <= 0) {
      Fluttertoast.showToast(
        msg: "Quantity harus lebih dari 0",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      // Show loading
      setState(() {
        isScanning = false;
      });

      // Simpan data sebelumnya untuk cek apakah akan update atau create
      final String productId = product.mProductId ?? "";
      final String poNumber = widget.from == "sync"
          ? widget.flag?.documentno ?? ""
          : _getCurrentInModel().documentno ?? "";

      bool isUpdate = false;

      // Cek apakah ini akan update quantity (hanya untuk kasus tanpa SN dan productId sama)
      if ((serialNumber.isEmpty) && poNumber.isNotEmpty) {
        final grQuery = await _firestore
            .collection('gr_in')
            .where('ponumber', isEqualTo: poNumber)
            .limit(1)
            .get();

        if (grQuery.docs.isNotEmpty) {
          final existingGr = GoodReceiveSerialNumberModel.fromFirestore(
            grQuery.docs.first,
            null,
          );
          final existingWithoutSn = existingGr.details.firstWhere(
            (detail) =>
                (detail.sn == null || detail.sn!.isEmpty) &&
                detail.productid == productId,
            orElse: () => GoodReceiveSerialNumberDetailModel(
              sn: null,
              productid: '',
              qty: 0,
            ),
          );

          isUpdate = existingWithoutSn.productid == productId;
        }
      }

      // Save to Firestore (serialNumber bisa empty string, akan dihandle menjadi null)
      await _saveToFirestore(
        product,
        serialNumber.isEmpty ? null : serialNumber,
        quantity,
      );

      // Show appropriate success message
      if (isUpdate) {
        Fluttertoast.showToast(
          msg: "Berhasil update quantity +$quantity untuk product $productId",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg:
              "Data berhasil disimpan: ${serialNumber.isEmpty ? "Tanpa Serial Number" : serialNumber} x$quantity",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }

      // Close bottom sheet
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _resetForm();
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: "Gagal menyimpan: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _saveToFirestore(
    InDetail product,
    String? serialNumber,
    int quantity,
  ) async {
    try {
      final String poNumber = widget.from == "sync"
          ? widget.flag?.documentno ?? ""
          : _getCurrentInModel().documentno ?? "";

      final String productId = product.mProductId ?? "";

      // Tambahkan: Ambil username dari global controller
      final String currentUser = globalVM.username.value;

      if (poNumber.isEmpty) {
        throw Exception("PO Number tidak ditemukan");
      }

      if (productId.isEmpty) {
        throw Exception("Product ID tidak ditemukan");
      }

      // === VALIDASI SERIAL NUMBER UNIK SECARA GLOBAL ===
      if (serialNumber != null && serialNumber.isNotEmpty) {
        // Cek di SEMUA document gr_in, tidak peduli PO mana
        final allGrQuery = await _firestore.collection('gr_in').get();

        for (final doc in allGrQuery.docs) {
          final existingGr = GoodReceiveSerialNumberModel.fromFirestore(
            doc,
            null,
          );
          final existingWithSameSn = existingGr.details.firstWhere(
            (detail) => detail.sn == serialNumber,
            orElse: () => GoodReceiveSerialNumberDetailModel(
              sn: null,
              productid: '',
              qty: 0,
            ),
          );

          if (existingWithSameSn.sn == serialNumber) {
            throw Exception(
              "Serial Number '$serialNumber' sudah digunakan untuk product '${existingWithSameSn.productid}' di PO '${existingGr.poNumber}'",
            );
          }
        }
      }

      // Cek apakah document sudah ada untuk PO ini
      final grQuery = await _firestore
          .collection('gr_in')
          .where('ponumber', isEqualTo: poNumber)
          .limit(1)
          .get();

      String grId;
      GoodReceiveSerialNumberModel? existingGr;

      if (grQuery.docs.isNotEmpty) {
        // Document sudah ada, update yang existing
        final doc = grQuery.docs.first;
        grId = doc.id;
        existingGr = GoodReceiveSerialNumberModel.fromFirestore(doc, null);

        // === LOGIKA UNTUK DATA TANPA SERIAL NUMBER ===
        if (serialNumber == null || serialNumber.isEmpty) {
          // Cari data dengan productId yang sama TANPA serial number dalam PO yang sama
          final existingWithoutSnIndex = existingGr.details.indexWhere(
            (detail) =>
                (detail.sn == null || detail.sn!.isEmpty) &&
                detail.productid == productId,
          );

          if (existingWithoutSnIndex != -1) {
            // Jika ditemukan productId yang sama tanpa SN dalam PO yang sama, UPDATE quantity (jumlahkan)
            final updatedDetails =
                List<GoodReceiveSerialNumberDetailModel>.from(
                  existingGr.details,
                );
            updatedDetails[existingWithoutSnIndex] =
                GoodReceiveSerialNumberDetailModel(
                  sn: null, // Tetap null/kosong
                  productid: productId,
                  qty: updatedDetails[existingWithoutSnIndex].qty + quantity,
                );

            await _firestore.collection('gr_in').doc(grId).update({
              'details': updatedDetails
                  .map((detail) => detail.toMap())
                  .toList(),
            });

            debugPrint(
              'Berhasil UPDATE quantity untuk product $productId tanpa SN di PO $poNumber: +$quantity',
            );
            return; // Keluar dari method setelah update
          }
        }

        // === TAMBAH DATA BARU ===
        // Jika sampai sini, berarti:
        // 1. Ada SN dan SN unik secara global, ATAU
        // 2. Tidak ada SN dan productId berbeda dalam PO yang sama (buat baru)
        final newDetail = GoodReceiveSerialNumberDetailModel(
          sn: serialNumber?.isEmpty ?? true ? null : serialNumber,
          productid: productId,
          qty: quantity,
        );

        final updatedDetails = [...existingGr.details, newDetail];

        await _firestore.collection('gr_in').doc(grId).update({
          'details': updatedDetails.map((detail) => detail.toMap()).toList(),
        });
      } else {
        // === BUAT DOCUMENT BARU ===
        grId = await _generateGrId();

        final newDetail = GoodReceiveSerialNumberDetailModel(
          sn: serialNumber?.isEmpty ?? true ? null : serialNumber,
          productid: productId,
          qty: quantity,
        );

        final newGr = GoodReceiveSerialNumberModel(
          grId: grId,
          poNumber: poNumber,
          createdBy: currentUser,
          createdAt: DateTime.now(),
          details: [newDetail],
        );

        await _firestore.collection('gr_in').doc(grId).set(newGr.toFirestore());
      }

      debugPrint(
        'Berhasil menyimpan ke Firestore: $productId - ${serialNumber ?? "NO_SN"} x$quantity',
      );
      debugPrint('GR ID: $grId | PO: $poNumber');
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      rethrow;
    }
  }

  Future<String> _generateGrId() async {
    final now = DateTime.now();
    final currentYear = now.year.toString();

    try {
      // Cari GR ID terakhir untuk tahun ini
      final lastGrQuery = await _firestore
          .collection('gr_in')
          .where('grid', isGreaterThanOrEqualTo: 'GR$currentYear')
          .where('grid', isLessThan: 'GR${int.parse(currentYear) + 1}')
          .orderBy('grid', descending: true)
          .limit(1)
          .get();

      int nextSequence = 1; // Default mulai dari 1

      if (lastGrQuery.docs.isNotEmpty) {
        final lastGrId = lastGrQuery.docs.first.id;

        // Extract sequence number dari GR ID terakhir
        // Format: GR202400000123 -> sequence = 123
        final sequenceMatch = RegExp(r'GR\d+(\d{7})$').firstMatch(lastGrId);
        if (sequenceMatch != null) {
          final lastSequence = int.tryParse(sequenceMatch.group(1)!) ?? 0;
          nextSequence = lastSequence + 1;
        }
      }

      // Format: GR + tahun + sequence 7 digit
      final sequenceString = nextSequence.toString().padLeft(7, '0');
      return 'GR$currentYear$sequenceString';
    } catch (e) {
      // Fallback jika error
      debugPrint('Error generating GR ID: $e');
      final timestamp = now.millisecondsSinceEpoch;
      return 'GR$currentYear$timestamp.toString().substring(timestamp.toString().length - 7)';
    }
  }

  Widget _buildQuantityChip(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: hijauGojek,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // todo: dont delete this
  // void _onEditPressed(InDetail indetail) {
  //   setState(() {
  //     pcs.value = indetail.qtuom?.toInt() ?? 0;
  //     ctn.value = indetail.qtctn ?? 0;
  //     kg.value = indetail.qtuom ?? 0.0;
  //     expireddate.value = indetail.vfdat ?? "";
  //     descriptioninput.text = indetail.descr ?? "";

  //     showModalBottomSheet(
  //       context: context,
  //       isScrollControlled: true,
  //       builder: (context) => modalBottomSheet(indetail),
  //     );
  //   });
  // }

  void _onDeletePressed(InDetail indetail) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 48,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Delete Product',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),

              const SizedBox(height: 12),
              if (indetail.maktxUI != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: hijauGojek.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hijauGojek.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    indetail.maktxUI ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hijauGojek,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete this product? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Delete Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Hapus dari detailsList observable
                          detailsList.removeWhere(
                            (item) => item.mProductId == indetail.mProductId,
                          );

                          // Hapus dari data utama
                          final currentModel = _getCurrentInModel();
                          currentModel.details?.removeWhere(
                            (item) => item.mProductId == indetail.mProductId,
                          );
                        });

                        Navigator.of(context).pop();

                        Fluttertoast.showToast(
                          msg: "Product deleted successfully",
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.delete_forever, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF00AA13),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: RefreshIndicator(
              backgroundColor: Colors.white,
              color: hijauGojek,
              onRefresh: _handleRefresh,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        colors: [hijauGojek, hijauGojek],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: _handleBackPress,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.from == "sync"
                                          ? "${widget.flag?.documentno}"
                                          : "${_getCurrentInModel().documentno}",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Purchase Order Details",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ..._buildActions(),
                            ],
                          ),
                        ),
                        if (_isSearching)
                          Container(
                            padding: EdgeInsets.all(16),
                            color: hijauGojek.withValues(alpha: 0.8),
                            child: _buildSearchField(),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      // Tampilkan loading shimmer
                      if (isDetailsLoading.value) {
                        return _buildShimmerLoading();
                      }

                      // Tampilkan empty state jika tidak ada data
                      if (detailsList.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Tampilkan data
                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _buildModernHeaderInfo()),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index < detailsList.length) {
                                return _buildModernProductCard(
                                  detailsList[index],
                                  index,
                                );
                              }
                              return SizedBox();
                            }, childCount: detailsList.length),
                          ),
                          SliverToBoxAdapter(child: SizedBox(height: 150)),
                        ],
                      );
                    }),
                  ),
                ],
              ),
            ),
            bottomSheet: _buildModernBottomActionBar(),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeaderInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildInfoItem(
                Icons.calendar_today,
                "PO Date",
                DateHelper.formatDate(widget.flag?.dateordered ?? ""),
              ),
              _buildInfoItem(
                Icons.business,
                "Vendor",
                widget.flag?.cBpartnerId ?? "-",
              ),
            ],
          ),
          SizedBox(height: 16),
          if (widget.from != "history")
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: containerinput,
                      decoration: InputDecoration(
                        hintText: "Enter container number...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomActionBar() {
    return Obx(() {
      final totalItems = detailsList.length;
      final totalQty = _calculateTotalQtyOrdered();

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem("Items", "$totalItems"),
                _buildSummaryItem(
                  "Total QTY",
                  NumberHelper.formatNumber(double.tryParse(totalQty)),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (widget.from != "history")
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleCancelPress,
                      icon: Icon(Icons.cancel, color: hijauGojek),
                      label: Text(
                        "Cancel",
                        style: TextStyle(color: hijauGojek),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: hijauGojek),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: containerinput.text.isEmpty
                          ? null
                          : () => _handleApprovePress(widget.from == "sync"),
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        "Approve",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: containerinput.text.isEmpty
                            ? Colors.grey
                            : hijauGojek,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: hijauGojek,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Future<void> _showMyDialogReject(InModel indetail) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Warning dengan animasi
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade50,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
              ),

              const SizedBox(height: 24),

              // Title
              Text(
                'Discard Changes?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                'Are you sure you want to discard all changes made in this purchase order?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Confirm Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final clonedData = cloned.tData ?? [];
                        final forCloseData = forclose.tData ?? [];

                        if (clonedData.isNotEmpty && widget.from != "sync") {
                          final tDataList =
                              inVM.tolistPO[widget.index].tData ?? [];
                          tDataList
                            ..clear()
                            ..addAll(forCloseData);
                        }

                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.delete_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Discard',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMyDialogApprove(InModel indetail) async {
    double baseWidth = 312;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        content: SizedBox(
          height: MediaQuery.of(context).size.height / 2.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(
                  0 * fem,
                  0 * fem,
                  1 * fem,
                  15.5 * fem,
                ),
                width: 35 * fem,
                height: 35 * fem,
                child: Image.asset(
                  'data/images/mdi-warning-circle-vJo.png',
                  width: 35 * fem,
                  height: 35 * fem,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(
                  0 * fem,
                  0 * fem,
                  0 * fem,
                  48 * fem,
                ),
                constraints: BoxConstraints(maxWidth: 256 * fem),
                child: Text(
                  'Are you sure to save all changes made in this purchase order? ',
                  textAlign: TextAlign.center,
                  style: safeGoogleFont(
                    'MonaSans',
                    fontSize: 16 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: Color(0xff2d2d2d),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 25 * fem,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                          20 * fem,
                          0 * fem,
                          16 * fem,
                          0 * fem,
                        ),
                        padding: EdgeInsets.fromLTRB(
                          24 * fem,
                          5 * fem,
                          25 * fem,
                          5 * fem,
                        ),
                        height: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xfff44236)),
                          color: Color(0xffffffff),
                          borderRadius: BorderRadius.circular(12 * fem),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 30 * fem,
                            height: 30 * fem,
                            child: Image.asset(
                              'data/images/cancel-viF.png',
                              width: 30 * fem,
                              height: 30 * fem,
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        Get.back();
                      },
                    ),
                    GestureDetector(
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          24 * fem,
                          5 * fem,
                          25 * fem,
                          5 * fem,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xff2cab0c),
                          borderRadius: BorderRadius.circular(12 * fem),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x3f000000),
                              offset: Offset(0 * fem, 4 * fem),
                              blurRadius: 2 * fem,
                            ),
                          ],
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 30 * fem,
                            height: 30 * fem,
                            child: Image.asset(
                              'data/images/check-circle-fg7.png',
                              width: 30 * fem,
                              height: 30 * fem,
                            ),
                          ),
                        ),
                      ),
                      onTap: () async {
                        DateTime now = DateTime.now();
                        String formattedDate = DateFormat(
                          'yyyy-MM-dd kk:mm:ss',
                        ).format(now);
                        indetail.approvedate = formattedDate;
                        indetail.truck = containerinput.text;

                        final tDataList = indetail.tData ?? [];

                        for (int i = 0; i < tDataList.length; i++) {
                          tDataList[i].appUser = globalVM.username.value;
                          tDataList[i].appVersion = globalVM.version.value;
                        }

                        indetail.tData = tDataList;

                        List<Map<String, dynamic>> maptdata = tDataList
                            .map((item) => item.toMap())
                            .toList();

                        Get.back();
                        Get.back();

                        indetail.dlvComp = "I";
                        bool sukses = await inVM.approveIn(indetail, maptdata);
                        inVM.isapprove.value = true;

                        if (!sukses) {
                          Get.dialog(MyDialogAnimation("reject"));
                        } else {
                          Get.dialog(MyDialogAnimation("approve"));
                          await inVM.sendHistory(indetail, maptdata);

                          if (widget.from != "sync" && ebeln != null) {
                            inVM.tolistPO.removeWhere((e) => e.ebeln == ebeln);
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showMyDialogAnimation(BuildContext context, String type) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Lottie.asset(
              type == "reject"
                  ? 'assets/lottie/reject_animation.json'
                  : 'assets/lottie/success_animation.json',
              repeat: false,
              onLoaded: (composition) async {
                await Future.delayed(composition.duration);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future _showMyDialog(InDetail indetail, String type) async {
    double baseWidth = 312;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: Text(
                      '${indetail.maktx}',
                      style: TextStyle(
                        fontFamily: 'MonaSans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                    child: CupertinoSlidingSegmentedControl(
                      groupValue: tabs,
                      children: myTabs,
                      onValueChanged: (i) {
                        setState(() {
                          if (type == "kg") {
                          } else {
                            tabs = i as int;
                            tabs == 0
                                ? type = "ctn"
                                : tabs == 1
                                ? type = "pcs"
                                : type = "kg";

                            type == "ctn"
                                ? _controllerctn = TextEditingController(
                                    text: typeIndexctn.toString(),
                                  )
                                : type == "kg"
                                ? _controllerkg = TextEditingController(
                                    text: typeIndexkg.toString(),
                                  )
                                : _controllerpcs = TextEditingController(
                                    text: typeIndexpcs.toString(),
                                  );
                          }
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          child: Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                color: hijauGojek,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (type == "ctn") {
                                if (typeIndexctn == 0) {
                                  _controllerctn = TextEditingController(
                                    text: typeIndexctn.toString(),
                                  );
                                } else {
                                  typeIndexctn--;
                                  _controllerctn = TextEditingController(
                                    text: typeIndexctn.toString(),
                                  );
                                }
                              } else if (type == "pcs") {
                                if (typeIndexpcs == 0) {
                                  _controllerpcs = TextEditingController(
                                    text: typeIndexpcs.toString(),
                                  );
                                } else {
                                  typeIndexpcs--;
                                  _controllerpcs = TextEditingController(
                                    text: typeIndexpcs.toString(),
                                  );
                                }
                              } else {
                                if (typeIndexkg == 0) {
                                  _controllerkg = TextEditingController(
                                    text: typeIndexkg.toString(),
                                  );
                                } else {
                                  typeIndexkg--;

                                  _controllerkg = TextEditingController(
                                    text: typeIndexkg.toString(),
                                  );
                                }
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 50,
                        child: TextField(
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          keyboardType: type == "kg"
                              ? TextInputType.numberWithOptions(decimal: true)
                              : TextInputType.number,
                          inputFormatters: [
                            type == "kg"
                                ? FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  )
                                : FilteringTextInputFormatter.digitsOnly,
                          ],
                          focusNode: _focusNode,
                          controller: type == "ctn"
                              ? _controllerctn
                              : type == "kg"
                              ? _controllerkg
                              : _controllerpcs,
                          onChanged: (i) {
                            try {
                              setState(() {
                                final listPo =
                                    inVM.tolistPO[widget.index].tData ?? [];

                                if (type == "ctn" && tabs == 0) {
                                  final int check = listPo
                                      .where(
                                        (element) =>
                                            element.matnr == indetail.matnr,
                                      )
                                      .length;

                                  if (check > 1) {
                                    final listpo = listPo
                                        .where(
                                          (element) => (element.matnr ?? '')
                                              .contains(indetail.matnr ?? ''),
                                        )
                                        .where(
                                          (element) =>
                                              !(element.cloned?.contains(
                                                    indetail.cloned ?? '',
                                                  ) ??
                                                  false),
                                        )
                                        .toList();

                                    final int hasilctn = listpo.fold<int>(
                                      0,
                                      (prev, e) => prev + (e.qtctn ?? 0),
                                    );
                                    final double hasilpcs = listpo.fold<double>(
                                      0,
                                      (prev, e) => prev + (e.qtuom ?? 0),
                                    );

                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final double hasil =
                                        (indetail.menge?.toDouble() ?? 0) -
                                        ((hasilctn * (indetail.umrez ?? 0)) +
                                            (currentCtn *
                                                (indetail.umrez ?? 0)) +
                                            currentPcs +
                                            hasilpcs);

                                    if (!hasil.isNegative &&
                                        hasil <=
                                            (indetail.menge?.toDouble() ?? 0)) {
                                      typeIndexctn = currentCtn;
                                    } else {
                                      final int hasil2 =
                                          (((indetail.menge?.toDouble() ?? 0) -
                                                      ((hasilctn *
                                                              (indetail.umrez ??
                                                                  0)) +
                                                          currentPcs +
                                                          hasilpcs)) /
                                                  (indetail.umrez == 0
                                                      ? 1
                                                      : (indetail.umrez ?? 1)))
                                              .toInt();

                                      typeIndexctn = hasil2;
                                      _controllerctn?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  } else {
                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final int hasil =
                                        (currentCtn * (indetail.umrez ?? 0)) +
                                        currentPcs;

                                    if (hasil <=
                                            (indetail.menge?.toInt() ?? 0) &&
                                        (indetail.menge?.toInt() ?? 0) >
                                            (indetail.umrez ?? 0)) {
                                      typeIndexctn = currentCtn;
                                    } else {
                                      final int hasil2 =
                                          (((indetail.menge?.toDouble() ?? 0) -
                                                      currentPcs) /
                                                  (indetail.umrez == 0
                                                      ? 1
                                                      : (indetail.umrez ?? 1)))
                                              .toInt();

                                      typeIndexctn = hasil2;
                                      _controllerctn?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  }
                                } else if (type == "pcs" && tabs == 1) {
                                  final int check = listPo
                                      .where(
                                        (element) =>
                                            element.matnr == indetail.matnr,
                                      )
                                      .length;

                                  if (check > 1) {
                                    final listpo = listPo
                                        .where(
                                          (element) =>
                                              element.matnr == indetail.matnr,
                                        )
                                        .where(
                                          (element) =>
                                              element.cloned != indetail.cloned,
                                        )
                                        .toList();

                                    final int hasilctn = listpo.fold<int>(
                                      0,
                                      (prev, e) => prev + (e.qtctn ?? 0),
                                    );
                                    final int hasilpcs = listpo.fold<int>(
                                      0,
                                      (prev, e) =>
                                          prev + (e.qtuom?.toInt() ?? 0),
                                    );

                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final int hasil =
                                        (indetail.menge?.toInt() ?? 0) -
                                        ((hasilctn * (indetail.umrez ?? 0)) +
                                            (currentCtn *
                                                (indetail.umrez ?? 0)) +
                                            currentPcs +
                                            hasilpcs);

                                    if (!hasil.isNegative &&
                                        hasil <=
                                            (indetail.menge?.toInt() ?? 0)) {
                                      typeIndexpcs = currentPcs;
                                    } else {
                                      final int hasil2 =
                                          (indetail.menge?.toInt() ?? 0) -
                                          ((hasilctn * (indetail.umrez ?? 0)) +
                                              (currentCtn *
                                                  (indetail.umrez ?? 0)) +
                                              hasilpcs);
                                      typeIndexpcs = hasil2;
                                      _controllerpcs?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  } else {
                                    final int currentCtn =
                                        int.tryParse(
                                          _controllerctn?.text ?? '0',
                                        ) ??
                                        0;
                                    final int currentPcs =
                                        int.tryParse(
                                          _controllerpcs?.text ?? '0',
                                        ) ??
                                        0;

                                    final int hasil =
                                        (currentCtn * (indetail.umrez ?? 0)) +
                                        currentPcs;

                                    if (hasil <=
                                        (indetail.menge?.toInt() ?? 0)) {
                                      typeIndexpcs = currentPcs;
                                    } else {
                                      final int hasil2 =
                                          (indetail.menge?.toInt() ?? 0) -
                                          (currentCtn * (indetail.umrez ?? 0));
                                      typeIndexpcs = hasil2;
                                      _controllerpcs?.text = hasil2.toString();
                                      _focusNode.unfocus();
                                    }
                                  }
                                } else {
                                  final double currentKg =
                                      double.tryParse(
                                        _controllerkg?.text ?? '0.0',
                                      ) ??
                                      0.0;

                                  typeIndexkg = currentKg;

                                  if ((indetail.menge ?? 0) <= typeIndexkg) {
                                    _controllerkg?.text = (indetail.menge ?? 0)
                                        .toString();
                                    typeIndexkg =
                                        double.tryParse(
                                          _controllerkg?.text ?? '0.0',
                                        ) ??
                                        0.0;
                                    _focusNode.unfocus();
                                  }
                                }
                              });
                            } catch (e, st) {
                              debugPrint('Error onChanged: $e\n$st');
                            }
                          },
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          child: Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                color: hijauGojek,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              final listPo =
                                  inVM.tolistPO[widget.index].tData ?? [];

                              final check = listPo
                                  .where(
                                    (element) =>
                                        element.matnr == indetail.matnr,
                                  )
                                  .length;

                              if (check > 1) {
                                final listpo = listPo
                                    .where(
                                      (element) =>
                                          element.matnr == indetail.matnr,
                                    )
                                    .where(
                                      (element) =>
                                          element.cloned != indetail.cloned,
                                    )
                                    .toList();

                                final int hasilCtn = listpo.fold<int>(
                                  0,
                                  (prev, e) => prev + (e.qtctn ?? 0),
                                );
                                final double hasilPcs = listpo.fold<double>(
                                  0,
                                  (prev, e) => prev + (e.qtuom ?? 0.0),
                                );

                                if (type == "ctn") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((hasilCtn * (indetail.umrez ?? 0)) +
                                          (typeIndexctn *
                                              (indetail.umrez ?? 0)) +
                                          typeIndexpcs +
                                          hasilPcs);

                                  if (hasil >= (indetail.umrez ?? 0)) {
                                    typeIndexctn++;
                                    _controllerctn?.text = typeIndexctn
                                        .toString();
                                  }
                                } else if (type == "pcs") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((hasilCtn * (indetail.umrez ?? 0)) +
                                          (typeIndexctn *
                                              (indetail.umrez ?? 0)) +
                                          hasilPcs);

                                  if (typeIndexpcs < hasil) {
                                    typeIndexpcs++;
                                    _controllerpcs?.text = typeIndexpcs
                                        .toString();
                                  }
                                } else {
                                  final double currentKg =
                                      double.tryParse(
                                        _controllerkg?.text ?? '0',
                                      ) ??
                                      0.0;
                                  typeIndexkg = currentKg;

                                  if ((indetail.menge ?? 0) <= typeIndexkg) {
                                    _controllerkg?.text = (indetail.menge ?? 0)
                                        .toString();
                                    typeIndexkg =
                                        double.tryParse(
                                          _controllerkg?.text ?? '0',
                                        ) ??
                                        0.0;
                                    _focusNode.unfocus();
                                  } else {
                                    typeIndexkg++;
                                    _controllerkg?.text = typeIndexkg
                                        .toStringAsFixed(2);
                                  }
                                }
                              } else {
                                if (type == "ctn") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((typeIndexctn * (indetail.umrez ?? 0)) +
                                          typeIndexpcs);

                                  if (hasil >= (indetail.umrez ?? 0)) {
                                    typeIndexctn++;
                                    _controllerctn?.text = typeIndexctn
                                        .toString();
                                  }
                                } else if (type == "pcs") {
                                  final double hasil =
                                      (indetail.menge?.toDouble() ?? 0) -
                                      ((typeIndexctn * (indetail.umrez ?? 0)));

                                  if (typeIndexpcs < hasil) {
                                    typeIndexpcs++;
                                    _controllerpcs?.text = typeIndexpcs
                                        .toString();
                                  }
                                } else {
                                  final double currentKg =
                                      double.tryParse(
                                        _controllerkg?.text ?? '0',
                                      ) ??
                                      0.0;
                                  typeIndexkg = currentKg;

                                  if ((indetail.menge ?? 0) <= typeIndexkg) {
                                    _controllerkg?.text = (indetail.menge ?? 0)
                                        .toString();
                                    typeIndexkg =
                                        double.tryParse(
                                          _controllerkg?.text ?? '0',
                                        ) ??
                                        0.0;
                                    _focusNode.unfocus();
                                  } else {
                                    typeIndexkg++;
                                    _controllerkg?.text = typeIndexkg
                                        .toStringAsFixed(2);
                                  }
                                }
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 25 * fem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              20 * fem,
                              0 * fem,
                              16 * fem,
                              0 * fem,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xfff44236)),
                              color: Color(0xffffffff),
                              borderRadius: BorderRadius.circular(12 * fem),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/cancel-viF.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            Get.back();
                          },
                        ),
                        GestureDetector(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                              24 * fem,
                              5 * fem,
                              25 * fem,
                              5 * fem,
                            ),
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xff2cab0c),
                              borderRadius: BorderRadius.circular(12 * fem),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3f000000),
                                  offset: Offset(0 * fem, 4 * fem),
                                  blurRadius: 2 * fem,
                                ),
                              ],
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 30 * fem,
                                height: 30 * fem,
                                child: Image.asset(
                                  'data/images/check-circle-fg7.png',
                                  width: 30 * fem,
                                  height: 30 * fem,
                                ),
                              ),
                            ),
                          ),
                          onTap: () {
                            ctn.value = typeIndexctn;
                            pcs.value = typeIndexpcs;
                            kg.value = typeIndexkg;
                            Get.back();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget headerCard2History(InDetail indetail) {
    double baseWidth = 360.0028076172;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 17.88 * fem, 12 * fem),
      margin: EdgeInsets.fromLTRB(5 * fem, 0 * fem, 10 * fem, 10 * fem),
      width: double.infinity,
      height: indetail.updated != "" ? 170 * fem : 100 * fem,
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.circular(8 * fem),
        boxShadow: [
          BoxShadow(
            color: Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 5 * fem,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 17 * fem, 0 * fem),
            height: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    0 * fem,
                    4 * fem,
                  ),
                  constraints: BoxConstraints(maxWidth: 145 * fem),
                  child: Text(
                    '${indetail.maktx}',
                    style: safeGoogleFont(
                      'MonaSans',
                      fontSize: 13 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff2d2d2d),
                    ),
                  ),
                ),
                Text(
                  'SKU: ${indetail.matnr}',
                  style: safeGoogleFont(
                    'MonaSans',
                    fontSize: 13 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: Color(0xff9a9a9a),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'PO QTY : ${currency.format(indetail.poqtyori ?? 0)} ${indetail.pounitori ?? ''}',
                  style: safeGoogleFont(
                    'MonaSans',
                    fontSize: 13 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: const Color(0xff9a9a9a),
                  ),
                ),
                SizedBox(height: 5),
                Visibility(
                  visible: indetail.descr != "",
                  child: Text(
                    'Description : ${indetail.descr}',
                    style: safeGoogleFont(
                      'MonaSans',
                      fontSize: 13 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff9a9a9a),
                    ),
                  ),
                ),

                SizedBox(height: 5),
                Visibility(
                  visible: indetail.updatedByUsername != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      'Update By: ${indetail.updatedByUsername}',
                      style: safeGoogleFont(
                        'MonaSans',
                        fontSize: 13 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Visibility(
                  visible: indetail.updated != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      indetail.updated != ""
                          ? 'Updated: ${globalVM.stringToDateWithTime(indetail.updated ?? '')}'
                          : 'Updated: ${indetail.updated}',
                      style: safeGoogleFont(
                        'MonaSans',
                        fontSize: 13 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Visibility(
                  visible: indetail.vfdat != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      indetail.vfdat != ""
                          ? 'Exp Date: ${globalVM.dateToString(indetail.vfdat ?? '')}'
                          : 'Exp Date: ${indetail.vfdat}',
                      style: safeGoogleFont(
                        'MonaSans',
                        fontSize: 13 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff9a9a9a),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
              ],
            ),
          ),
          Visibility(
            visible: !(indetail.maktx?.contains("Pallet") ?? false),
            child: Container(
              margin: EdgeInsets.fromLTRB(0 * fem, 20 * fem, 12 * fem, 0 * fem),
              width: 56 * fem,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(
                      0 * fem,
                      0 * fem,
                      0 * fem,
                      4 * fem,
                    ),
                    width: double.infinity,
                    height: 28 * fem,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xffa8a8a8)),
                      color: Color(0xffffffff),
                      borderRadius: BorderRadius.circular(8 * fem),
                    ),
                    child: Center(
                      child: Text(
                        '${indetail.qtctn}',
                        textAlign: TextAlign.center,
                        style: safeGoogleFont(
                          'MonaSans',
                          fontSize: 14 * ffem,
                          fontWeight: FontWeight.w600,
                          height: 1.1725 * ffem / fem,
                          color: Color(0xff2d2d2d),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'CTN',
                    textAlign: TextAlign.center,
                    style: safeGoogleFont(
                      'MonaSans',
                      fontSize: 10 * ffem,
                      fontWeight: FontWeight.w600,
                      height: 1.1725 * ffem / fem,
                      color: Color(0xff2d2d2d),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0 * fem, 20 * fem, 16 * fem, 0 * fem),
            width: 56 * fem,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0 * fem,
                    0 * fem,
                    0 * fem,
                    4 * fem,
                  ),
                  width: double.infinity,
                  height: 28 * fem,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xffa8a8a8)),
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.circular(8 * fem),
                  ),
                  child: Center(
                    child: Text(
                      '${indetail.qtuom}',
                      textAlign: TextAlign.center,
                      style: safeGoogleFont(
                        'MonaSans',
                        fontSize: 14 * ffem,
                        fontWeight: FontWeight.w600,
                        height: 1.1725 * ffem / fem,
                        color: Color(0xff2d2d2d),
                      ),
                    ),
                  ),
                ),
                Text(
                  'PCS',
                  textAlign: TextAlign.center,
                  style: safeGoogleFont(
                    'MonaSans',
                    fontSize: 10 * ffem,
                    fontWeight: FontWeight.w600,
                    height: 1.1725 * ffem / fem,
                    color: Color(0xff2d2d2d),
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: widget.from != "history",
            child: SizedBox(
              width: 11.57 * fem,
              height: 17 * fem,
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset(
                  'data/images/vector-1HV.png',
                  width: 11.57 * fem,
                  height: 17 * fem,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget headerCard2(InDetail indetail) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double baseWidth = 360.0;
        final double fem = constraints.maxWidth / baseWidth;
        final double ffem = fem * 0.97;

        return Slidable(
          key: Key(indetail.hashCode.toString()),
          groupTag: 'slidable_group',
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _onAddPressed(indetail),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: Icons.add,
                label: 'Add',
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _onDeletePressed(indetail),
                backgroundColor: hijauGojek,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              8 * fem,
              8 * fem,
              17.88 * fem,
              12 * fem,
            ),
            margin: EdgeInsets.fromLTRB(5 * fem, 0, 10 * fem, 10 * fem),
            width: double.infinity,
            height: (indetail.updated?.isNotEmpty ?? false)
                ? 185 * fem
                : 100 * fem,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8 * fem),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  offset: Offset(0 * fem, 4 * fem),
                  blurRadius: 5 * fem,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildLeftContent(indetail, fem, ffem)),
                _buildQuantitySections(indetail, fem, ffem),
                if (widget.from != "history") ...[
                  SizedBox(width: 8 * fem),
                  _buildTrailingIcon(fem),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftContent(InDetail indetail, double fem, double ffem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 145 * fem),
          child: Text(
            indetail.maktx ?? '',
            style: TextStyle(
              fontFamily: 'MonaSans',
              fontSize: 13 * ffem,
              fontWeight: FontWeight.w600,
              color: const Color(0xff2d2d2d),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SKU: ${indetail.matnr}',
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontSize: 13 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff9a9a9a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PO QTY: ${_formatNumber(indetail.poqtyori)} ${indetail.pounitori}',
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontSize: 13 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff9a9a9a),
          ),
        ),

        if ((indetail.descr?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Description: ${indetail.descr}',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        if ((indetail.updatedByUsername?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Update By: ${indetail.updatedByUsername}',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],

        if ((indetail.updated?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Updated: ${_formatUpdatedDate(indetail.updated ?? '')}',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],

        if ((indetail.vfdat?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Exp Date: ${_formatExpDate(indetail.vfdat ?? '')}',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuantitySections(InDetail indetail, double fem, double ffem) {
    return Row(
      children: [
        if (_shouldShowCtnSection(indetail)) ...[
          _buildQuantityItem(
            value: indetail.qtctn.toString(),
            label: 'CTN',
            fem: fem,
            ffem: ffem,
          ),
          SizedBox(width: 12 * fem),
        ],
        _buildQuantityItem(
          value: indetail.pounitori == "KG"
              ? indetail.qtuom.toString()
              : indetail.qtuom.toString(),
          label: indetail.pounitori == "KG" ? 'KG' : 'PCS',
          fem: fem,
          ffem: ffem,
        ),
      ],
    );
  }

  Widget _buildQuantityItem({
    required String value,
    required String label,
    required double fem,
    required double ffem,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56 * fem,
          height: 28 * fem,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffa8a8a8)),
            color: Colors.white,
            borderRadius: BorderRadius.circular(8 * fem),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff2d2d2d),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontSize: 10 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff2d2d2d),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailingIcon(double fem) {
    return SizedBox(
      width: 11.57 * fem,
      height: 17 * fem,
      child: Icon(Icons.chevron_right, color: Colors.grey, size: 17 * fem),
    );
  }

  bool _shouldShowCtnSection(InDetail indetail) {
    return indetail.pounitori != "KG" &&
        !(indetail.maktx?.contains("Pallet") ?? false);
  }

  String _formatNumber(dynamic number) {
    return number.toString();
  }

  String _formatUpdatedDate(String updated) {
    return updated.isNotEmpty
        ? (globalVM.stringToDateWithTime(updated))
        : updated;
  }

  String _formatExpDate(String vfdat) {
    return vfdat.isNotEmpty ? (globalVM.dateToString(vfdat)) : vfdat;
  }

  void _onAddPressed(InDetail indetail) {
    setState(() {
      if (widget.from == "sync") {
        _addToSyncList(indetail);
      } else {
        _addToInVMList(indetail);
      }
    });
  }

  void _addToSyncList(InDetail indetail) {
    final tData = widget.flag?.tData;
    if (tData == null) return;

    final clone2 = InModel.clone(cloned);
    final clones =
        clone2.tData?.where((e) => e.matnr == indetail.matnr).toList() ?? [];

    for (int i = 0; i < clones.length; i++) {
      final clone = clones[i];
      clone.qtctn = 0;
      clone.qtuom = 0;
      clone.cloned = "cloned $i";
      tData.add(clone);
    }
  }

  void _addToInVMList(InDetail indetail) {
    final listPO = inVM.tolistPO[widget.index];
    final tData = listPO.tData;
    if (tData == null) return;

    final clone2 = InModel.clone(cloned);
    final clones =
        clone2.tData?.where((e) => e.matnr == indetail.matnr).toList() ?? [];

    for (int i = 0; i < clones.length; i++) {
      final clone = clones[i];
      clone.qtctn = 0;
      clone.qtuom = 0;
      clone.cloned = "cloned $i";
      tData.add(clone);
    }
  }

  AppBar buildAppBar(double fem, double ffem) {
    return AppBar(
      actions: widget.from == "history" ? null : _buildActions(),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        iconSize: 20.0,
        onPressed: _handleBackPress,
      ),
      backgroundColor: hijauGojek,
      title: _isSearching ? _buildSearchField() : _buildAppBarTitle(fem, ffem),
    );
  }

  Widget buildBody(double fem, double ffem) {
    return Container(
      height: GlobalVar.height,
      padding: EdgeInsets.only(top: 10),
      width: double.infinity,
      decoration: BoxDecoration(color: Color(0xffffffff)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildHeaderData(fem, ffem),
                _buildDivider(fem),
                _buildProductList(fem, ffem),
              ],
            ),
          ),
          _buildBottomActionBar(fem, ffem),
        ],
      ),
    );
  }

  Widget _buildHeaderData(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(12 * fem, 0 * fem, 12 * fem, 8 * fem),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildDateField(fem, ffem),
          _buildVendorField(fem, ffem),
          _buildContainerField(fem, ffem),
          _buildDocNoSapField(fem, ffem),
        ],
      ),
    );
  }

  Widget _buildDateField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 8 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * fem),
                border: Border.all(color: Color(0xff9c9c9c)),
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
          Positioned(
            left: 11 * fem,
            top: 0 * fem,
            child: Container(
              width: 104 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 11 * fem,
            top: 0 * fem,
            child: Text(
              'Purchase Order Date',
              style: _buildTextStyle(ffem, fontSize: 11),
            ),
          ),
          Positioned(
            left: 12.4677734375 * fem,
            top: 15 * fem,
            child: Text(
              _getDateValue(),
              style: _buildTextStyle(ffem, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * fem),
                border: Border.all(color: Color(0xff9c9c9c)),
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
          Positioned(
            left: 14 * fem,
            top: 0 * fem,
            child: Container(
              width: 39 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 15 * fem,
            top: 0 * fem,
            child: Text('Vendor', style: _buildTextStyle(ffem, fontSize: 11)),
          ),
          Positioned(
            left: 11 * fem,
            top: 15 * fem,
            child: Text(
              _getVendorValue(),
              style: _buildTextStyle(ffem, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainerField(double fem, double ffem) {
    if (widget.from == "history") {
      return _buildHistoryContainerField(fem, ffem);
    } else {
      return _buildEditableContainerField(fem, ffem);
    }
  }

  Widget _buildHistoryContainerField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4 * fem),
                border: Border.all(color: Color(0xff9c9c9c)),
                color: Color(0xffe0e0e0),
              ),
            ),
          ),
          Positioned(
            left: 14 * fem,
            top: 0 * fem,
            child: Container(
              width: 70 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 15 * fem,
            top: 0 * fem,
            child: Text(
              'Container No',
              style: _buildTextStyle(ffem, fontSize: 11),
            ),
          ),
          Positioned(
            left: 11 * fem,
            top: 15 * fem,
            child: Text(
              '${inVM.tolistPO[widget.index].truck}',
              style: _buildTextStyle(ffem, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableContainerField(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
      width: double.infinity,
      height: 45 * fem,
      child: Stack(
        children: [
          Positioned(
            left: 0 * fem,
            top: 5 * fem,
            child: Container(
              width: 336 * fem,
              height: 40 * fem,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: Border.all(color: hijauGojek),
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            left: 14 * fem,
            top: 0 * fem,
            child: Container(
              width: 70 * fem,
              height: 11 * fem,
              color: Color(0xffffffff),
            ),
          ),
          Positioned(
            left: 15 * fem,
            top: 0 * fem,
            child: Text(
              'Container No',
              style: _buildTextStyle(ffem, fontSize: 11),
            ),
          ),
          Positioned(
            left: 11 * fem,
            child: Padding(
              padding: EdgeInsets.only(left: 5, bottom: 10),
              child: SizedBox(
                width: 300 * fem,
                height: 30 * fem,
                child: TextFormField(
                  key: Key('description'),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top: 15, left: 8),
                    isDense: true,
                    labelText: "",
                    fillColor: Colors.white,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  keyboardType: TextInputType.text,
                  controller: containerinput,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocNoSapField(double fem, double ffem) {
    return Visibility(
      visible:
          widget.from == "history" &&
          inVM.tolistPO[widget.index].documentno != null,
      child: Container(
        margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 13 * fem),
        width: double.infinity,
        height: 45 * fem,
        child: Stack(
          children: [
            Positioned(
              left: 0 * fem,
              top: 5 * fem,
              child: Container(
                width: 336 * fem,
                height: 40 * fem,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4 * fem),
                  border: Border.all(color: Color(0xff9c9c9c)),
                  color: Color(0xffe0e0e0),
                ),
              ),
            ),
            Positioned(
              left: 14 * fem,
              top: 0 * fem,
              child: Container(
                width: 50 * fem,
                height: 11 * fem,
                color: Color(0xffffffff),
              ),
            ),
            Positioned(
              left: 15 * fem,
              top: 0 * fem,
              child: Text(
                'Doc No SAP',
                style: _buildTextStyle(ffem, fontSize: 11),
              ),
            ),
            Positioned(
              left: 11 * fem,
              top: 15 * fem,
              child: Text(
                '${inVM.tolistPO[widget.index].documentno}',
                style: _buildTextStyle(ffem, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double fem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 7 * fem),
      width: double.infinity,
      height: 1 * fem,
      decoration: BoxDecoration(color: Color(0xff9c9c9c)),
    );
  }

  String _calculateTotalQtyOrdered() {
    final total = detailsList.fold<double>(
      0,
      (currentSum, item) => currentSum + (item.qtyordered ?? 0),
    );
    return total.toStringAsFixed(2);
  }

  Widget _buildProductList(double fem, double ffem) {
    return Expanded(
      child: SizedBox(
        child: Obx(() {
          final listPO = inVM.tolistPO;
          if (listPO.isNotEmpty) {
            final tData = listPO[widget.index].tData ?? [];
            tData.sort((a, b) => (b.matnr ?? '').compareTo(a.matnr ?? ''));
          }

          return ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            itemCount: _getProductCount(),
            itemBuilder: (BuildContext context, int index) {
              return _buildProductItem(context, index, fem, ffem);
            },
          );
        }),
      ),
    );
  }

  Widget _buildBottomActionBar(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 0 * fem),
      padding: EdgeInsets.fromLTRB(22.5 * fem, 6 * fem, 22.5 * fem, 6 * fem),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xffffffff),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8 * fem),
          topRight: Radius.circular(8 * fem),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 2 * fem,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSummaryInfo(fem, ffem),
          _buildActionButtons(fem, ffem),
        ],
      ),
    );
  }

  Widget _buildSummaryInfo(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 5 * fem),
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSummaryItem('Number of Items:', '${_getItemCount()}'),
          SizedBox(width: 23 * fem),
          _buildSummaryItem('Total GR in CTN:', calculateTotalCtn()),
          SizedBox(width: 23 * fem),
          _buildSummaryItem('Total GR in PCS / KG:', _calculateTotalPcs()),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double fem, double ffem) {
    return Visibility(
      visible: widget.from != "history",
      child: widget.from == "sync"
          ? _buildSyncActionButtons(fem, ffem)
          : _buildNormalActionButtons(fem, ffem),
    );
  }

  Widget _buildSyncActionButtons(double fem, double ffem) {
    return SizedBox(
      width: double.infinity,
      height: 40 * fem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCancelButton(fem, ffem),
          _buildApproveButton(fem, ffem, isSync: true),
        ],
      ),
    );
  }

  Widget buildCameraScannerDialog() {
    return AlertDialog(
      title: const Text("Scan Barcode"),
      content: SizedBox(
        height: 300,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MobileScanner(
            controller: _mobileScannerController,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null && code.isNotEmpty) {
                  _processBarcodeResult(code);
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                }
              }
            },
            fit: BoxFit.cover,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: ValueListenableBuilder<bool>(
            valueListenable: _isTorchOn,
            builder: (context, isOn, child) {
              return Icon(isOn ? Icons.flash_on : Icons.flash_off);
            },
          ),
          onPressed: () {
            _isTorchOn.value = !_isTorchOn.value;
            _mobileScannerController?.toggleTorch();
          },
        ),
        IconButton(
          icon: const Icon(Icons.cameraswitch),
          onPressed: () => _mobileScannerController?.switchCamera(),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            setState(() {
              isScanning = false;
            });
            Navigator.of(context).pop();
          },
          child: const Text("Batal"),
        ),
      ],
    );
  }

  Widget _buildNormalActionButtons(double fem, double ffem) {
    return SizedBox(
      width: double.infinity,
      height: 40 * fem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildCancelButton(fem, ffem),
          _buildApproveButton(fem, ffem, isSync: false),
        ],
      ),
    );
  }

  String _getDateValue() {
    return widget.from == "sync"
        ? '${inVM.dateToString(widget.flag?.aedat, "tes")}'
        : '${inVM.dateToString(inVM.tolistPO[widget.index].aedat, "tes")}';
  }

  String _getVendorValue() {
    return widget.from == "sync"
        ? '${widget.flag?.lifnr}'
        : '${inVM.tolistPO[widget.index].lifnr}';
  }

  int _getProductCount() {
    if (widget.from == "sync") {
      return widget.flag?.tData?.length ?? 0;
    } else {
      return inVM.tolistPO.isNotEmpty
          ? inVM.tolistPO[widget.index].tData?.length ?? 0
          : 0;
    }
  }

  int _getItemCount() {
    return inVM.tolistPO.isNotEmpty
        ? inVM.tolistPO[widget.index].tData?.length ?? 0
        : 0;
  }

  void _handleBackPress() {
    if (widget.from == "history") {
      Get.back(result: true); // Kembali dengan result true
    } else if (widget.from == "sync") {
      if (widget.flag == null) return;
      _showMyDialogReject(widget.flag!);
    } else {
      final model = inVM.tolistPO.isNotEmpty
          ? inVM.tolistPO[widget.index]
          : null;
      if (model == null) return;
      _showMyDialogReject(model);
    }
  }

  Widget _buildAppBarTitle(double fem, double ffem) {
    return Obx(() {
      final titleText = widget.from == "sync"
          ? widget.flag?.documentno ?? ''
          : inVM.tolistPO[widget.index].documentno ?? '';

      return SizedBox(
        child: Text(titleText, style: TextStyle(color: Colors.white)),
      );
    });
  }

  Widget _buildCancelButton(double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 30 * fem, 0 * fem),
      child: TextButton(
        onPressed: _handleCancelPress,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Container(
          padding: EdgeInsets.fromLTRB(52 * fem, 5 * fem, 53 * fem, 5 * fem),
          height: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xfff44236)),
            color: Color(0xffffffff),
            borderRadius: BorderRadius.circular(12 * fem),
            boxShadow: [
              BoxShadow(
                color: Color(0x3f000000),
                offset: Offset(0 * fem, 4 * fem),
                blurRadius: 2 * fem,
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 30 * fem,
              height: 30 * fem,
              child: Image.asset(
                'data/images/cancel-ecb.png',
                width: 30 * fem,
                height: 30 * fem,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApproveButton(double fem, double ffem, {bool isSync = false}) {
    final isDisabled = containerinput.text == "";

    return TextButton(
      onPressed: isDisabled ? null : () => _handleApprovePress(isSync),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: isDisabled ? Colors.grey : Color(0xff2cab0c),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * fem),
        ),
        shadowColor: Color(0x3f000000),
        elevation: 2 * fem,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(52 * fem, 5 * fem, 53 * fem, 5 * fem),
        height: double.infinity,
        child: Center(
          child: SizedBox(
            width: 30 * fem,
            height: 30 * fem,
            child: Image.asset(
              'data/images/check-circle-LCb.png',
              width: 30 * fem,
              height: 30 * fem,
            ),
          ),
        ),
      ),
    );
  }

  void _handleCancelPress() {
    _showMyDialogReject(inVM.tolistPO[widget.index]);
  }

  void _handleApprovePress(bool isSync) {
    final model = isSync
        ? widget.flag
        : inVM.tolistPO.isNotEmpty
        ? inVM.tolistPO[widget.index]
        : null;
    if (model == null) return;

    setState(() {
      _showMyDialogApprove(model);
    });
  }

  TextStyle _buildTextStyle(
    double ffem, {
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return safeGoogleFont(
      'MonaSans',
      fontSize: fontSize * ffem,
      fontWeight: fontWeight,
      height: 1.1725 * ffem / ffem,
      color: Color(0xff000000),
    );
  }

  Widget _buildProductItem(
    BuildContext context,
    int index,
    double fem,
    double ffem,
  ) {
    return Container();
  }
}

class CameraScannerDialog extends StatefulWidget {
  final Function(String) onBarcodeDetected;
  final Function() onCancel;

  const CameraScannerDialog({
    required this.onBarcodeDetected,
    required this.onCancel,
    super.key,
  });

  @override
  State<CameraScannerDialog> createState() => _CameraScannerDialogState();
}

class _CameraScannerDialogState extends State<CameraScannerDialog> {
  late MobileScannerController cameraController;
  bool _isTorchOn = false;
  String _scannedCode = "";

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
          const Text("Scan Barcode"),
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
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (BarcodeCapture capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && _scannedCode.isEmpty) {
                      final String? code = barcodes.first.rawValue;
                      if (code != null && code.isNotEmpty) {
                        setState(() {
                          _scannedCode = code;
                        });
                        Future.delayed(const Duration(milliseconds: 300), () {
                          widget.onBarcodeDetected(code);
                        });
                      }
                    }
                  },
                  errorBuilder: (context, error) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: hijauGojek,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${error.errorDetails?.message ?? 'Unknown error'}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: hijauGojek),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              widget.onCancel();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Tutup'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (_scannedCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Scanned: $_scannedCode",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
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
                      Fluttertoast.showToast(
                        msg: "Gagal menghidupkan flash",
                        backgroundColor: Colors.orange,
                      );
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: _isTorchOn ? Colors.amber : Colors.grey,
                  ),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.cameraswitch),
                  onPressed: () async {
                    try {
                      await cameraController.switchCamera();
                    } catch (e) {
                      debugPrint("Error switching camera: $e");
                      Fluttertoast.showToast(
                        msg: "Gagal mengganti kamera",
                        backgroundColor: Colors.orange,
                      );
                    }
                  },
                  style: IconButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text("Batal"),
                  onPressed: () {
                    widget.onCancel();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hijauGojek,
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
