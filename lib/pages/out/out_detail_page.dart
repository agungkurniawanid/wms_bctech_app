import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:flutter/cupertino.dart';
import 'package:wms_bctech/components/improved_camera_scanner_dialog_widget.dart';
import 'package:wms_bctech/components/out/out_product_detail_bottomsheet_widget.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/delivery_order/delivery_order_constant.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/constants/utils_constant.dart';
import 'package:wms_bctech/controllers/delivery_order/delivery_order_controller.dart';
import 'package:wms_bctech/controllers/out/out_controller.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/number_helper.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/delivery_order/delivery_order_detail_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/models/out/out_detail_model.dart';
import 'package:wms_bctech/models/out/out_model.dart';
import 'package:wms_bctech/pages/delivery_order/delivery_order_page.dart';
import 'package:wms_bctech/pages/my_dialog_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/components/scanner_dialog_widget.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';

class OutDetailPage extends StatefulWidget {
  final int index;
  final String from;
  final OutModel? flag;
  final String? doId;
  final bool isReadOnlyMode;

  const OutDetailPage(
    this.index,
    this.from,
    this.flag,
    this.doId, {

    super.key,
    this.isReadOnlyMode = false,
  });

  @override
  State<OutDetailPage> createState() => _OutDetailPageState();
}

class _OutDetailPageState extends State<OutDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController controller;
  bool allow = true;
  int idPeriodSelected = 1;
  final List<String> sortList = ['SO Date', 'Customer'];
  final OutController _outController = Get.find<OutController>();
  final List<ItemChoice> listchoice = [];
  final List<Category> listcategory = [];
  late final ScrollController scrollController;
  late OutModel cloned;
  late OutModel forclose;
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
  final RxBool _isSendingToKafka = false.obs;

  TextEditingController? _controllerctn;
  TextEditingController? _controllerpcs;
  TextEditingController? _controllerkg;
  final bool _isDisposed = false;
  late bool isReadOnlyMode;

  // ✅ VARIABLE PENAMPUNG GR ID DAN STATUS
  String? _currentdoId; // Menyimpan doId yang pertama kali digenerate
  bool _isdoIdSavedToFirestore =
      false; // Status apakah doId sudah disimpan ke Firestore
  final List<DeliveryOrderDetailModel> _pendingGrDetails =
      []; // Menampung detail sementara

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
  final List<OutDetailModel> listOutDetailModellocal = [];
  final OutModel listOutModel = OutModel();

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

  final RxList<OutDetailModel> detailsList = <OutDetailModel>[].obs;
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

  StreamSubscription<List<OutDetailModel>>? _detailsStreamSubscription;
  StreamSubscription<OutModel?>? _poDataStreamSubscription;
  // Observable untuk data realtime
  final RxList<OutDetailModel> _realtimeDetailsList = <OutDetailModel>[].obs;
  final Rx<OutModel?> _realtimeOutModel = Rx<OutModel?>(null);

  final _logger = Logger();

  // Tambahkan di bagian variabel
  final FocusNode _searchFocusNode = FocusNode();
  final RxBool _isSearchActive = false.obs;
  final RxList<OutDetailModel> _filteredDetailsList = <OutDetailModel>[].obs;

  // ✅ VARIABEL PAGINATION
  final ScrollController _scrollController = ScrollController();
  final RxInt _currentPage = 0.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasMoreData = true.obs;
  final int _itemsPerPage = 20;
  final RxList<OutDetailModel> _paginatedDetailsList = <OutDetailModel>[].obs;

  @override
  void initState() {
    super.initState();
    _searchQuery = TextEditingController();
    containerinput.text = '';
    isScanning = false;
    qrScanResult = "";
    _serialNumberController.addListener(_onSerialNumberChanged);
    _qtyController.text = "1";

    _currentdoId = widget.doId;
    _isdoIdSavedToFirestore = widget.doId != null;

    isReadOnlyMode = widget.isReadOnlyMode;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _initializeWithRealData();

      // ✅ PERBAIKAN 1: Panggil _startRealtimeListeners() DULUAN.
      // Ini akan memasang listener di background. Listener mungkin
      // akan mengirim list kosong, tapi tidak apa-apa.
      _startRealtimeListeners();

      // ✅ PERBAIKAN 2: SEKARANG, panggil dan TUNGGU _loadDetails().
      // Ini akan mengambil data secara manual (one-time fetch)
      // dan MENGGANTI list kosong dari stream dengan data yang valid.
      await _loadDetails();

      // ✅ PERBAIKAN 3: Urutan ini sudah benar dari saran saya sebelumnya.
      // Set filtered list dari data yang baru saja kita dapatkan.
      final initialData = _realtimeDetailsList.isNotEmpty
          ? _realtimeDetailsList
          : detailsList;
      _filteredDetailsList.assignAll(initialData);

      // ✅ PERBAIKAN 4: Panggil _loadInitialData() SETELAH
      // _filteredDetailsList dijamin berisi data.
      _loadInitialData();
    });

    // _loadDetails();
  }

  // ✅ METHOD UNTUK LOAD DATA AWAL
  void _loadInitialData() {
    // ✅ FIX: Tentukan sourceList berdasarkan status pencarian
    final sourceList = _isSearchActive.value
        ? _filteredDetailsList
        : (_realtimeDetailsList.isNotEmpty
              ? _realtimeDetailsList
              : detailsList);

    _paginatedDetailsList.clear();

    if (sourceList.isNotEmpty) {
      final endIndex = _itemsPerPage > sourceList.length
          ? sourceList.length
          : _itemsPerPage;
      _paginatedDetailsList.addAll(sourceList.sublist(0, endIndex));
      _currentPage.value = 1;
      _hasMoreData.value = sourceList.length > _itemsPerPage;
    } else {
      // ✅ Pastikan list paginasi kosong jika source (hasil search) juga kosong
      _currentPage.value = 0;
      _hasMoreData.value = false;
    }
  }

  // ✅ SCROLL LISTENER UNTUK PAGINATION
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore.value && _hasMoreData.value) {
        _loadMoreData();
      }
    }
  }

  // ✅ METHOD UNTUK LOAD MORE DATA
  void _loadMoreData() {
    if (_isLoadingMore.value || !_hasMoreData.value) return;

    _isLoadingMore.value = true;

    // Simulasi loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final sourceList = _isSearchActive.value
          ? _filteredDetailsList
          : (_realtimeDetailsList.isNotEmpty
                ? _realtimeDetailsList
                : detailsList);

      final startIndex = _currentPage.value * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;

      if (startIndex < sourceList.length) {
        final newItems = sourceList.sublist(
          startIndex,
          endIndex > sourceList.length ? sourceList.length : endIndex,
        );

        _paginatedDetailsList.addAll(newItems);
        _currentPage.value++;
        _hasMoreData.value = endIndex < sourceList.length;
      } else {
        _hasMoreData.value = false;
      }

      _isLoadingMore.value = false;
    });
  }

  // ✅ METHOD UNTUK RESET PAGINATION
  void _resetPagination() {
    _currentPage.value = 0;
    _hasMoreData.value = true;
    _paginatedDetailsList.clear();
    _loadInitialData();
  }

  // Method untuk memulai realtime listeners
  void _startRealtimeListeners() {
    final String documentNo =
        widget.flag?.documentno ??
        (widget.from == "sync"
            ? widget.flag?.documentno ?? ""
            : (getCurrentOutModel()?.documentno ?? ""));

    if (documentNo.isEmpty) {
      debugPrint('Document number tidak ditemukan untuk realtime listener');
      return;
    }

    _detailsStreamSubscription?.cancel();
    _poDataStreamSubscription?.cancel();

    try {
      _detailsStreamSubscription = _outController
          .getDetailsByDocumentNoWithFilter(documentNo)
          .listen(
            (List<OutDetailModel> details) {
              if (mounted) {
                setState(() {
                  _realtimeDetailsList.assignAll(details);
                  detailsList.assignAll(details);
                  _resetPagination();

                  if (!_isSearchActive.value || _searchQuery.text.isEmpty) {
                    _filteredDetailsList.assignAll(details);
                  }
                });
              }
            },
            onError: (error) {
              debugPrint('Error dalam details stream: $error');
              if (mounted) {
                setState(() {
                  detailsError.value = 'Error realtime: $error';
                });
              }
            },
            cancelOnError: false,
          );

      // Start PO data stream dengan safe check
      _poDataStreamSubscription = _outController
          .getPODataStream(documentNo)
          .listen(
            (OutModel? updatedModel) {
              if (mounted && updatedModel != null) {
                // Validasi data sebelum update
                if (_isValidOutModel(updatedModel)) {
                  setState(() {
                    _realtimeOutModel.value = updatedModel;

                    // Update widget.flag jika dari sync
                    if (widget.from == "sync" && widget.flag != null) {
                      _updateFlagWithNewData(updatedModel);
                    }
                  });
                }
              }
            },
            onError: (error) {
              debugPrint('Error dalam PO data stream: $error');
            },
            cancelOnError: false,
          );
    } catch (e) {
      debugPrint('Error starting realtime listeners: $e');
    }
  }

  bool _isValidOutModel(OutModel model) {
    return model.documentno != null && model.documentno!.isNotEmpty;
  }

  // Update flag dengan data baru dari realtime
  void _updateFlagWithNewData(OutModel updatedModel) {
    // Update properti yang diperlukan
    widget.flag?.details = updatedModel.details;
    widget.flag?.dateordered = updatedModel.dateordered;
    widget.flag?.cBpartnerId = updatedModel.cBpartnerId;
    widget.flag?.docstatus = updatedModel.docstatus;
    // Tambahkan properti lain yang perlu diupdate
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

      // Untuk initial load, gunakan method biasa
      final List<OutDetailModel> details = await _outController
          .getDetailsByDocumentNo(documentNo);

      detailsList.assignAll(details);
      _realtimeDetailsList.assignAll(details);

      if (details.isEmpty) {
        detailsError.value =
            'No pending items found (all items are fully delivered)';
      }
    } catch (e) {
      detailsError.value = 'Error loading details: $e';
      debugPrint('Error loading details: $e');
    } finally {
      isDetailsLoading.value = false;
    }
  }

  // ✅ UPDATE METHOD _handleRefresh
  Future<void> _handleRefresh() async {
    try {
      setState(() {
        isDetailsLoading.value = true;
        if (_isSearchActive.value) {
          _stopSearching();
        }
      });

      // Restart realtime listeners
      _startRealtimeListeners();
      await _loadDetails();

      // ✅ RESET PAGINATION SETELAH REFRESH
      _resetPagination();

      Logger().i('Data berhasil diperbarui dengan realtime listeners.');
    } catch (e) {
      Logger().e('Error during refresh: $e');
    } finally {
      if (mounted) {
        setState(() {
          isDetailsLoading.value = false;
        });
      }
    }
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 5, // Tampilkan 5 shimmer cards
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hijauGojek.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Container
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Quantity Chips Container
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(
                        3,
                        (index) => Column(
                          children: [
                            Container(
                              width: 60,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              width: 40,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Button Shimmer
                  Container(
                    width: double.infinity,
                    height: 36,
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

  // ✅ LOADING MORE INDICATOR
  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(hijauGojek),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Memuat lebih banyak...',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NO MORE DATA INDICATOR
  Widget _buildNoMoreDataIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle_outline, color: hijauGojek, size: 32),
            SizedBox(height: 8),
            Text(
              'Semua data telah dimuat',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initializeWithRealData() {
    if (widget.from == "sync") {
      ebeln = widget.flag?.documentno;
      cloned = OutModel.clone(widget.flag!);
      forclose = OutModel.clone(widget.flag!);
    } else {
      // Gunakan data dari controller, bukan dummy data
      if (_outController.tolistSalesOrder.length > widget.index) {
        final realData = _outController.tolistSalesOrder[widget.index];
        ebeln = realData.documentno;
        cloned = OutModel.clone(realData);
        forclose = OutModel.clone(realData);
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
          List<OutDetailModel> barcode;
          if (widget.from == "sync") {
            final tData = widget.flag?.details ?? [];
            barcode = tData
                .where(
                  (element) =>
                      (element.mProductId ?? '').contains(barcodeString),
                )
                .toList();
          } else {
            final currentData = _getCurrentOutModel();
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

  OutModel _getCurrentOutModel() {
    // Prioritaskan data realtime jika ada dan valid
    if (_realtimeOutModel.value != null &&
        _isValidOutModel(_realtimeOutModel.value!)) {
      return _realtimeOutModel.value!;
    }

    if (widget.from == "sync") {
      return widget.flag!;
    } else {
      // Safe access dengan fallback
      final currentModel = getCurrentOutModel();
      if (currentModel != null) {
        return currentModel;
      } else {
        // Fallback ke data awal atau buat default
        debugPrint('Fallback to initial data');
        return OutModel(); // atau return default empty model
      }
    }
  }

  OutModel? getCurrentOutModel() {
    if (widget.from == "sync") {
      return widget.flag;
    } else {
      // Safe check untuk index
      if (_outController.tolistSalesOrder.length <= widget.index) {
        debugPrint(
          'Index out of bounds: ${widget.index}, list length: ${_outController.tolistSalesOrder.length}',
        );
        return null;
      }
      return _outController.tolistSalesOrder[widget.index];
    }
  }

  Future<void> startMobileScan() async {
    if (isScanning) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Metode Pencarian Scan"),
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
              _startCameraScanImproved();
            },
            child: const Text("Scan Camera"),
          ),
        ],
      ),
    );
  }

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
        builder: (context) => ImprovedCameraScannerDialogWidget(
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
    final FocusNode focusNode = FocusNode();

    // Request focus setelah dialog muncul
    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade200,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.keyboard_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Input Barcode Manual',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Ketik kode barcode produk yang ingin Anda cari',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200, width: 2),
                ),
                child: TextField(
                  controller: manualController,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kode Barcode',
                    labelStyle: TextStyle(
                      color: Colors.purple.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: 'Contoh: SKU-001, SKU-002',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.barcode_reader,
                      color: Colors.purple.shade600,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      Navigator.of(context).pop();
                      // Tambahkan delay untuk memastikan dialog tertutup
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _processBarcodeResult(value);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        foregroundColor: Colors.grey.shade700,
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (manualController.text.isNotEmpty) {
                          Navigator.of(context).pop();
                          // Tambahkan delay untuk memastikan dialog tertutup
                          Future.delayed(const Duration(milliseconds: 100), () {
                            _processBarcodeResult(manualController.text);
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Scan',
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
    ).then((_) {
      // Cleanup focus node saat dialog ditutup
      focusNode.dispose();
      manualController.dispose();
    });
  }

  List<OutDetailModel> _findProductByBarcode(String barcode) {
    // Gunakan realtime details list
    final allProducts = _realtimeDetailsList;

    if (allProducts.isEmpty) {
      debugPrint('Realtime details list is empty');
      return [];
    }

    debugPrint('Searching for barcode: $barcode');
    debugPrint('Total products in realtime list: ${allProducts.length}');

    final foundProducts = allProducts.where((product) {
      final productId = product.mProductId?.toLowerCase() ?? '';
      final productName = product.mProductName?.toLowerCase() ?? '';
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

    List<OutDetailModel> foundProducts = _findProductByBarcode(trimmedBarcode);

    if (foundProducts.isNotEmpty) {
      OutDetailModel product = foundProducts.first;
      debugPrint('Product found: ${product.maktxUI}');

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

      // Tunggu sebentar untuk memastikan state sudah di-update
      await Future.delayed(const Duration(milliseconds: 200));

      // Tampilkan bottom sheet TANPA menutup dialog apapun\
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: true,
          builder: (context) =>
              OutProductDetailBottomsheetWidget(product: product),
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

      // Tunggu toast muncul dulu
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      _showProductNotFoundDialog(trimmedBarcode);
    }
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Product Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Barcode Info
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      barcode,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Product dengan barcode di atas tidak ditemukan dalam daftar PO.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pastikan barcode sudah sesuai dengan daftar PO',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> scanBarcode() async {
    if (isScanning) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Pilih Metode Scan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Pilih metode yang ingin digunakan untuk memindai barcode',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Options
              _buildScanOption(
                icon: Icons.keyboard_rounded,
                title: 'Input Manual',
                description: 'Ketik barcode secara manual',
                gradient: [Colors.purple.shade400, Colors.purple.shade600],
                onTap: () {
                  Navigator.of(context).pop();
                  _showManualBarcodeInput();
                },
              ),
              const SizedBox(height: 12),
              _buildScanOption(
                icon: Icons.camera_alt_rounded,
                title: 'Kamera HP',
                description: 'Scan menggunakan kamera',
                gradient: [Colors.green.shade400, Colors.green.shade600],
                onTap: () {
                  Navigator.of(context).pop();
                  _startCameraScanImproved();
                },
              ),
              const SizedBox(height: 20),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: gradient[0].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
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
  //           // Langsung panggil _processBarcodeResult yang sudah menggunakan OutProductDetailBottomsheetWidget
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
    final simulatedDetail = OutDetailModel(
      mProductId: barcode,
      maktxUI: "Product from Scan: $barcode",
      pounitori: "PCS",
      umrez: 10,
      qtctn: 1,
      qtuom: 10.0,
      qtydelivered: 100.0,
      vfdat: "20241231",
      descr: "Scanned product",
    );

    // Tampilkan OutProductDetailBottomsheetWidget untuk simulated product
    if (mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            OutProductDetailBottomsheetWidget(product: simulatedDetail),
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _detailsStreamSubscription?.cancel();
    _poDataStreamSubscription?.cancel();
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
    final displayList = _realtimeDetailsList.isNotEmpty
        ? _realtimeDetailsList
        : detailsList;

    final total = displayList.fold<double>(
      0,
      (currentSum, item) => currentSum + (item.qtuom ?? 0),
    );
    return total.toStringAsFixed(2);
  }

  Future<void> _startQRScan(OutDetailModel product) async {
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

    // Reset controllers untuk SCAN MODE
    _serialNumberController.clear();
    _resetQuantityForMode(true); // Set quantity fixed untuk scan

    // Set product info
    _productNameController.text = product.maktxUI ?? product.mProductId ?? "";
    _documentNoController.text = widget.from == "sync"
        ? widget.flag?.documentno ?? ""
        : _getCurrentOutModel().documentno ?? "";

    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => QRScannerDialog(
          onQRCodeDetected: (qrCode) {
            _processQRCodeResult(qrCode, product);
          },
          onClose: () {
            setState(() {
              isScanning = false;
            });
            Navigator.of(context).pop();
          },
          // Di dalam QRScannerDialog atau method yang memanggil manual input dari QR
          openManualInput: () {
            Future.delayed(const Duration(milliseconds: 300), () {
              _startManualInput(product, fromQR: true);
            });
          },
        ),
      );
    }

    setState(() {
      isScanning = false;
    });
  }

  Widget _buildScanResultBottomSheet(OutDetailModel product) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan drag indicator
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header dengan close button
                    Container(
                      padding: EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 0,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hasil Scan QR Code',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: hijauGojek,
                              fontFamily: 'MonaSans',
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Informasi Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                color: hijauGojek,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Scan QR Code Berhasil',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: hijauGojek,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Quantity otomatis 1 per serial number untuk scan QR code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Document No
                    _buildModernInfoField(
                      label: "Document No PO",
                      value: _documentNoController.text,
                      icon: Icons.description_outlined,
                    ),

                    SizedBox(height: 16),

                    // Product Name
                    _buildModernInfoField(
                      label: "Nama Product",
                      value: _productNameController.text,
                      icon: Icons.inventory_2_outlined,
                    ),

                    SizedBox(height: 16),

                    // Serial Number Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Serial Number",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFamily: 'MonaSans',
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  child: Text(
                                    _serialNumberController.text.isEmpty
                                        ? 'Tidak ada serial number'
                                        : _serialNumberController.text,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color:
                                          _serialNumberController.text.isEmpty
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey.shade300,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.camera_alt_rounded,
                                  color: hijauGojek,
                                  size: 20,
                                ),
                                onPressed: () => _restartScanner(product),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Quantity Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Quantity",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Scan QR Code",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
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
                            child: Row(
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  color: hijauGojek,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "1",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: hijauGojek,
                                    fontSize: 16,
                                    fontFamily: 'MonaSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacer untuk memberikan ruang di atas button
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Action Buttons
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Close button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetForm();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Tutup',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Save & Scan Again button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () => _saveScanResult(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijauGojek,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Simpan & Scan Lagi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'MonaSans',
                            ),
                          ),
                        ],
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

  Widget _buildModernInfoField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
            fontFamily: 'MonaSans',
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  value.isEmpty ? 'Tidak tersedia' : value,
                  style: TextStyle(
                    fontSize: 15,
                    color: value.isEmpty
                        ? Colors.grey.shade500
                        : Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _restartScanner(OutDetailModel product) {
    // Close current bottom sheet
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Restart scanner
    _startQRScan(product);
  }

  void _saveScanResult(OutDetailModel product) async {
    final serialNumber = _serialNumberController.text.trim();

    // ✅ UNTUK SCAN QR: QUANTITY SELALU 1
    final quantity = 1; // Fixed quantity untuk scan QR

    // Validasi input
    if (serialNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "Serial number tidak boleh kosong untuk scan QR",
        backgroundColor: Colors.orange,
      );
      return;
    }

    // Validasi format serial number
    if (serialNumber.length < 2) {
      Fluttertoast.showToast(
        msg: "Serial number terlalu pendek. Minimal 2 karakter.",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      setState(() {
        isScanning = false;
      });

      // ✅ VALIDASI SERIAL NUMBER UNIK SECARA GLOBAL
      _logger.d('🔍 Memvalidasi serial number: $serialNumber');
      final isSerialNumberUnique = await _validateSerialNumberBeforeSave(
        serialNumber,
      );

      if (!isSerialNumberUnique) {
        return; // Stop execution if validation fails
      }

      _logger.d('✅ Serial number valid, menampilkan konfirmasi...');

      // ✅ TAMPILKAN DIALOG KONFIRMASI SEBELUM MENYIMPAN
      _showSaveConfirmationDialog(
        product,
        serialNumber,
        quantity,
        fromQR: true,
        shouldCloseBottomSheet: true, // ✅ TUTUP BOTTOM SHEET SETELAH SIMPAN
        shouldNavigate: false, // ✅ JANGAN NAVIGASI
        onAfterSave: () {
          // ✅ CALLBACK SETELAH SIMPAN BERHASIL - TAMPILKAN KEMBALI CAMERA SCANNING
          _logger.d('🔄 Menampilkan kembali camera scanning setelah simpan...');

          // Tunggu sebentar untuk memastikan bottom sheet tertutup
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _startQRScan(product);
            }
          });
        },
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Gagal memvalidasi: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // void _restartQRScanner(OutDetailModel product) async {
  //   _logger.d('🔄 Restart QR Scanner...');

  //   // Reset form terlebih dahulu
  //   _resetForm();

  //   // Set state untuk scanning
  //   setState(() {
  //     isScanning = true;
  //     scannedSerialNumber = "";
  //   });

  //   // Tunggu sebentar sebelum memulai scanner
  //   await Future.delayed(const Duration(milliseconds: 300));

  //   if (mounted) {
  //     _logger.d('📷 Memulai ulang QR Scanner...');
  //     await _startQRScan(product);
  //   }
  // }

  void _resetQuantityForMode(bool isScanMode) {
    if (isScanMode) {
      // Untuk scan mode, set quantity ke 1 dan disable controls
      _quantity.value = 1;
      _qtyController.text = "1";
    } else {
      // Untuk manual mode, set quantity ke 1 tapi biarkan editable
      _quantity.value = 1;
      _qtyController.text = "1";
    }
  }

  void _resetForm() {
    _serialNumberController.clear();
    _qtyController.text = "1";
    _quantity.value = 1;
    scannedSerialNumber = "";
  }

  void _processQRCodeResult(String qrCode, OutDetailModel product) {
    if (!mounted) return;

    setState(() {
      scannedSerialNumber = qrCode;
      _serialNumberController.text = qrCode;
    });

    // Close scanner dialog first
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      _logger.d('📱 Dialog scanner ditutup sebelum menampilkan bottom sheet');
    }

    // Wait a bit then show bottom sheet
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _showScanResultBottomSheet(product);
      }
    });
  }

  void _showScanResultBottomSheet(OutDetailModel product) {
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

    if (query.isEmpty) {
      // Tampilkan data realtime atau semua data
      detailsList.assignAll(
        _realtimeDetailsList.isNotEmpty ? _realtimeDetailsList : detailsList,
      );
      return;
    }

    final sourceList = _realtimeDetailsList.isNotEmpty
        ? _realtimeDetailsList
        : detailsList;

    final filtered = sourceList.where((e) {
      final name = e.maktxUI?.toLowerCase() ?? '';
      final sku = e.mProductId?.toLowerCase() ?? '';
      return name.contains(query) || sku.contains(query);
    }).toList();

    detailsList.assignAll(filtered);
  }

  String calculateTotalCtn() {
    final currentModel = _getCurrentOutModel();
    final tData = currentModel.details ?? [];

    final total = tData.fold<int>(
      0,
      (currentSum, item) => currentSum + (item.qtctn ?? 0),
    );
    return total.toString();
  }

  // Perbaiki method _buildActions untuk search
  List<Widget> _buildActions() {
    if (_isSearching) {
      return [
        SizedBox(width: 8), // Memberikan sedikit ruang
      ];
    }

    return [
      if (!isReadOnlyMode) ...[
        IconButton(
          icon: Icon(Icons.qr_code_scanner, color: Colors.white),
          onPressed: scanBarcode,
        ),
        IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: _startSearch,
        ),
      ],
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
    _performLiveSearch(newQuery);
  }

  // Widget untuk search field yang lebih baik
  Widget _buildEnhancedSearchField() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          SizedBox(width: 12),
          Icon(Icons.search, color: hijauGojek),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchQuery,
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white70),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(color: Colors.black87, fontSize: 16.0),
              onChanged: _performLiveSearch,
              onSubmitted: (_) {
                // Optional: handle submit jika diperlukan
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.clear, color: hijauGojek),
            onPressed: _stopSearching,
          ),
        ],
      ),
    );
  }

  // Widget untuk empty search state
  Widget _buildSearchEmptyState() {
    return SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Produk tidak ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Coba dengan kata kunci lain atau periksa ejaan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _stopSearching,
            style: ElevatedButton.styleFrom(
              backgroundColor: hijauGojek,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text('Tampilkan Semua Produk'),
          ),
        ],
      ),
    );
  }

  // Widget untuk empty state
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[400],
              ),
              SizedBox(height: 16),
              Text(
                'All Items Fully Delivered',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              SizedBox(height: 8),
              Text(
                detailsError.value.isNotEmpty
                    ? detailsError.value
                    : 'All purchase order items have been completely delivered',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              SizedBox(height: 20),
              if (detailsError.value.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _handleRefresh,
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
    );
  }

  // Method untuk memulai pencarian
  void _startSearch() {
    setState(() {
      _isSearchActive.value = true;
      _isSearching = true;
    });

    // Fokuskan ke search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  // Method untuk menghentikan pencarian
  void _stopSearching() {
    setState(() {
      _isSearchActive.value = false;
      _isSearching = false;
      _searchQuery.clear();
      searchQuery = '';

      // ✅ RESET KE DATA REAL-TIME
      _filteredDetailsList.clear();
      _filteredDetailsList.addAll(_realtimeDetailsList);
      _resetPagination();
    });
  }

  // Method untuk live search
  // ✅ PERBAIKAN: Gunakan _realtimeDetailsList sebagai sumber utama
  void _performLiveSearch(String query) {
    setState(() {
      searchQuery = query;

      if (query.isEmpty) {
        _filteredDetailsList.clear();
        // ✅ GUNAKAN _realtimeDetailsList sebagai sumber data
        _filteredDetailsList.addAll(_realtimeDetailsList);
        _resetPagination();
        return;
      }

      final searchTerm = query.toLowerCase().trim();

      // ✅ SELALU gunakan _realtimeDetailsList sebagai sumber
      final filtered = _realtimeDetailsList.where((product) {
        final productId = product.mProductId?.toLowerCase() ?? '';
        final productName = product.mProductName?.toLowerCase() ?? '';
        final matnr = product.matnr?.toLowerCase() ?? '';
        final maktxUI = product.maktxUI?.toLowerCase() ?? '';

        return productId.contains(searchTerm) ||
            productName.contains(searchTerm) ||
            matnr.contains(searchTerm) ||
            maktxUI.contains(searchTerm);
      }).toList();

      _filteredDetailsList.assignAll(filtered);
      _resetPagination();
    });
  }

  // void _clearSearchQuery() {
  //   setState(() {
  //     _searchQuery.clear();
  //     _isSearching = false;

  //     final sourceData = listOutDetailModellocal;

  //     if (widget.from == "sync") {
  //       widget.flag?.details?.clear();
  //       widget.flag?.details?.addAll(sourceData);
  //     } else {
  //       final currentModel = _getCurrentOutModel();
  //       final tData = currentModel.details ?? [];
  //       tData.clear();
  //       tData.addAll(sourceData);
  //     }
  //   });
  // }

  Widget modalBottomSheet(OutDetailModel outDetailModel) {
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
                      outDetailModel.mProductId ?? "-",
                      fem,
                      ffem,
                    ),
                    _buildDetailRow(
                      "Description",
                      outDetailModel.maktxUI ?? "-",
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
                            _showQuantityDialog(outDetailModel, "ctn");
                          },
                          fem,
                          ffem,
                        ),
                        _buildQuantitySelector(
                          "PCS",
                          pcs.value.toString(),
                          () {
                            _showQuantityDialog(outDetailModel, "pcs");
                          },
                          fem,
                          ffem,
                        ),
                        _buildQuantitySelector(
                          "KG",
                          kg.value.toStringAsFixed(2),
                          () {
                            _showQuantityDialog(outDetailModel, "kg");
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
                            onPressed: () =>
                                _saveProductChanges(outDetailModel),
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

  void _showQuantityDialog(OutDetailModel outDetailModel, String type) {
    _showMyDialog(outDetailModel, type);
  }

  void _saveProductChanges(OutDetailModel outDetailModel) {
    // Cari index product dalam detailsList
    final index = detailsList.indexWhere(
      (item) => item.mProductId == outDetailModel.mProductId,
    );

    if (index != -1) {
      setState(() {
        // Update data di detailsList
        detailsList[index] = outDetailModel;
      });

      // Juga update di data utama jika diperlukan
      final currentModel = _getCurrentOutModel();
      if (currentModel.details != null) {
        final detailIndex = currentModel.details!.indexWhere(
          (item) => item.mProductId == outDetailModel.mProductId,
        );
        if (detailIndex != -1) {
          currentModel.details![detailIndex] = outDetailModel;
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

  Widget _buildModernProductCard(OutDetailModel outDetailModel, int index) {
    final qtyOrdered = outDetailModel.qtyordered?.toInt() ?? 0;
    final qtydelivered = outDetailModel.qtydelivered?.toInt() ?? 0;
    final remainingQty = qtyOrdered - qtydelivered;
    final progress = qtyOrdered > 0 ? (qtydelivered / qtyOrdered) : 0.0;

    final isSNInput = outDetailModel.isSN;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hijauGojek.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        splashColor: DeliveryOrderConstant.primaryColor.withValues(alpha: 0.1),
        highlightColor: DeliveryOrderConstant.primaryColor.withValues(
          alpha: 0.05,
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) =>
              OutProductDetailBottomsheetWidget(product: outDetailModel),
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
                padding: EdgeInsets.only(
                  left: 16,
                  right: isReadOnlyMode ? 16 : 60,
                  top: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Icon dengan status realtime
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: hijauGojek.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  color: hijauGojek,
                                  size: 24,
                                ),
                              ),
                              // Indicator realtime
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Name
                              Text(
                                outDetailModel.mProductName ?? "Product Name",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              // SKU
                              Text(
                                outDetailModel.mProductId ?? "SKU",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 12),

                              // STATUS BADGE realtime
                              if (progress > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      progress,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        progress,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getStatusIcon(progress),
                                        size: 12,
                                        color: _getStatusColor(progress),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        _getStatusText(progress),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(progress),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // QUANTITY CHIPS SECTION realtime
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuantityChipWithLabel(
                            "Total Pesanan",
                            "$qtyOrdered",
                            Icons.shopping_cart,
                          ),
                          _buildQuantityChipWithLabel(
                            "Sudah Dikirim",
                            "$qtydelivered",
                            Icons.check_circle,
                          ),
                          _buildQuantityChipWithLabel(
                            "Belum Kirim",
                            "$remainingQty",
                            Icons.pending_actions,
                          ),
                        ],
                      ),
                    ),

                    // DESCRIPTION realtime
                    if (outDetailModel.descr?.isNotEmpty ?? false) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.note,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                outDetailModel.descr!,
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 11,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // VIEW DETAILS BUTTON - TAMBAHAN BARU
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              OutProductDetailBottomsheetWidget(
                                product: outDetailModel,
                              ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hijauGojek,
                          side: BorderSide(
                            color: hijauGojek.withValues(alpha: 0.5),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        icon: Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: hijauGojek,
                        ),
                        label: Text(
                          "View Details",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hijauGojek,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ACTION BUTTONS
              if (widget.from != "history" && !isReadOnlyMode)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      gradient: LinearGradient(
                        colors: [hijauGojek.withValues(alpha: 0.3), hijauGojek],
                      ),
                    ),
                    child: qtydelivered != qtyOrdered
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isSNInput == "Y"
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.qr_code_scanner_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () =>
                                          _startQRScan(outDetailModel),
                                      tooltip: "Scan QR Code",
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        Icons.keyboard,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () =>
                                          _startManualInput(outDetailModel),
                                      tooltip: "Input Manual",
                                    ),
                            ],
                          )
                        : SizedBox.shrink(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Progress Bar menggunakan progress_bar_chart
  // Widget _buildProgressBarChart(
  //   int qtyOrdered,
  //   int qtydelivered,
  //   int progressPercentage,
  // ) {
  //   final remainingQty = qtydelivered - qtyOrdered;
  //   final remainingPercentage = 100 - progressPercentage;

  //   final List<StatisticsItem> progressStats = [
  //     StatisticsItem(
  //       hijauGojek,
  //       progressPercentage.toDouble(),
  //       title: 'Terkirim',
  //     ),

  //     if (remainingPercentage > 0)
  //       StatisticsItem(
  //         Colors.grey.shade400,
  //         remainingPercentage.toDouble(),
  //         title: 'Sisa',
  //       ),
  //   ];

  //   return Column(
  //     children: [
  //       ProgressBarChart(
  //         values: progressStats,
  //         height: 25,
  //         borderRadius: 12,
  //         totalPercentage: 100.0,
  //         unitLabel: '%',
  //       ),

  //       SizedBox(height: 6),

  //       // Legend untuk progress information
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           // Completed - HIJAU
  //           Row(
  //             children: [
  //               Container(
  //                 width: 12,
  //                 height: 12,
  //                 decoration: BoxDecoration(
  //                   color: hijauGojek,
  //                   shape: BoxShape.circle,
  //                 ),
  //               ),
  //               SizedBox(width: 4),
  //               Text(
  //                 'Selesai: $progressPercentage% ($qtyOrdered)',
  //                 style: TextStyle(
  //                   fontSize: 11,
  //                   color: Colors.green.shade700,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ],
  //           ),

  //           // Remaining - ABU-ABU
  //           if (remainingQty > 0)
  //             Row(
  //               children: [
  //                 Container(
  //                   width: 12,
  //                   height: 12,
  //                   decoration: BoxDecoration(
  //                     color: Colors.grey.shade400,
  //                     shape: BoxShape.circle,
  //                   ),
  //                 ),
  //                 SizedBox(width: 4),
  //                 Text(
  //                   'Sisa: $remainingPercentage% ($remainingQty)',
  //                   style: TextStyle(
  //                     fontSize: 11,
  //                     color: Colors.grey.shade600,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ],
  //             ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Color _getStatusColor(double progress) {
    if (progress >= 1.0) return Colors.green;
    if (progress >= 0.7) return Colors.blue;
    if (progress >= 0.3) return Colors.orange;
    return Colors.grey; // Default color untuk progress 0%
  }

  IconData _getStatusIcon(double progress) {
    if (progress >= 1.0) return Icons.check_circle;
    if (progress >= 0.7) return Icons.download_done;
    if (progress >= 0.3) return Icons.pending;
    return Icons.inventory_2; // Default icon untuk progress 0%
  }

  String _getStatusText(double progress) {
    if (progress >= 1.0) return "Selesai 100%";
    if (progress >= 0.7) return "Progress Baik";
    if (progress >= 0.3) return "Dalam Proses";
    return "Menunggu"; // Default text untuk progress 0%
  }

  // Updated Quantity Chip dengan Label
  Widget _buildQuantityChipWithLabel(
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, size: 16, color: hijauGojek),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: hijauGojek,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _startManualInput(OutDetailModel product, {bool fromQR = false}) {
    // Reset controllers untuk MANUAL MODE
    _serialNumberController.clear();

    if (fromQR) {
      _resetQuantityForMode(true); // Quantity fixed = 1 untuk scan QR
    } else {
      _resetQuantityForMode(false); // Quantity editable untuk manual biasa
    }

    // Set product info
    _productNameController.text = product.maktxUI ?? product.mProductId ?? "";
    _documentNoController.text = widget.from == "sync"
        ? widget.flag?.documentno ?? ""
        : _getCurrentOutModel().documentno ?? "";

    // Tampilkan bottom sheet untuk input manual
    _showManualInputBottomSheet(product, fromQR: fromQR);
  }

  void _showManualInputBottomSheet(
    OutDetailModel product, {
    bool fromQR = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _buildManualInputBottomSheet(product, fromQR: fromQR),
    ).then((_) {
      // Reset state ketika bottom sheet ditutup
      setState(() {
        isScanning = false;
      });
    });
  }

  Widget _buildManualInputBottomSheet(
    OutDetailModel product, {
    bool fromQR = false,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan drag indicator
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header dengan close button
                    Container(
                      padding: EdgeInsets.only(top: 8, bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 0,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fromQR ? 'Input Manual SN' : 'Input Tanpa SN',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: hijauGojek,
                              fontFamily: 'MonaSans',
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Informasi Card untuk Input Manual
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: Colors.orange.shade700,
                            size: 18,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fromQR
                                      ? 'Manual dari QR Scan'
                                      : 'Input Manual',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: fromQR
                                        ? Colors.orange.shade700
                                        : Colors.blue.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  fromQR
                                      ? 'Quantity otomatis 1 per serial number untuk scan QR code'
                                      : 'Quantity dapat disesuaikan, serial number opsional',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: fromQR
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade800,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Document No
                    _buildModernInfoField(
                      label: "Document No PO",
                      value: _documentNoController.text,
                      icon: Icons.description_outlined,
                    ),

                    SizedBox(height: 16),

                    // Product Name
                    _buildModernInfoField(
                      label: "Nama Product",
                      value: _productNameController.text,
                      icon: Icons.inventory_2_outlined,
                    ),

                    SizedBox(height: 20),

                    // Serial Number Section (Editable)
                    // Serial Number Section (Editable)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Serial Number",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                fontFamily: 'MonaSans',
                              ),
                            ),
                            SizedBox(width: 6),
                            // ✅ TAMPILKAN "WAJIB DIISI" JIKA fromQR = true
                            if (fromQR)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Text(
                                  "Wajib diisi",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Opsional",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _serialNumberController,
                          enabled: fromQR,
                          decoration: InputDecoration(
                            hintText: fromQR
                                ? "Masukkan serial number (wajib diisi)"
                                : "Tidak Perlu diisi",
                            hintStyle: TextStyle(
                              color: fromQR
                                  ? Colors.red.shade400
                                  : Colors.grey.shade500,
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: fromQR
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: fromQR ? Colors.red : hijauGojek,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: fromQR
                                    ? Colors.red.shade300
                                    : Colors.grey.shade300,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.qr_code_2_outlined,
                              color: fromQR
                                  ? Colors.red.shade400
                                  : Colors.grey.shade600,
                              size: 20,
                            ),
                            // ✅ TAMBAHKAN VALIDATION ERROR JIKA fromQR
                            errorText:
                                fromQR && _serialNumberController.text.isEmpty
                                ? "Serial number wajib diisi untuk input manual QR"
                                : null,
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          // ✅ AUTOVALIDATE MODE UNTUK fromQR
                          autovalidateMode: fromQR
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          validator: fromQR
                              ? (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Serial number wajib diisi";
                                  }
                                  if (value.trim().length < 2) {
                                    return "Serial number terlalu pendek";
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Quantity Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quantity",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontFamily: 'MonaSans',
                          ),
                        ),
                        SizedBox(height: 12),
                        ValueListenableBuilder<int>(
                          valueListenable: _quantity,
                          builder: (context, quantity, child) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Decrement Button
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: quantity > 1
                                          ? Colors.grey.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.remove_rounded,
                                        color: quantity > 1
                                            ? hijauGojek
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      onPressed: quantity > 1
                                          ? () {
                                              _quantity.value--;
                                              _qtyController.text = _quantity
                                                  .value
                                                  .toString();
                                            }
                                          : null,
                                    ),
                                  ),

                                  // Quantity Input
                                  Expanded(
                                    child: Container(
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.symmetric(
                                          vertical: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      child: TextFormField(
                                        controller: _qtyController,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: hijauGojek,
                                          fontFamily: 'MonaSans',
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: "0",
                                          hintStyle: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        readOnly: fromQR,
                                        onChanged: fromQR
                                            ? null // Tidak bisa diubah jika fromQR
                                            : (value) {
                                                final qty =
                                                    int.tryParse(value) ?? 1;
                                                _quantity.value = qty.clamp(
                                                  1,
                                                  999999,
                                                );
                                              },
                                      ),
                                    ),
                                  ),

                                  // Increment Button
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.add_rounded,
                                        color: !fromQR
                                            ? hijauGojek
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      onPressed: !fromQR
                                          ? () {
                                              _quantity.value++;
                                              _qtyController.text = _quantity
                                                  .value
                                                  .toString();
                                            }
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tekan + / - atau ketik langsung jumlah quantity",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),

                    // Spacer untuk memberikan ruang di atas button
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Action Buttons
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Close button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetForm();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 12),

                  // Save button
                  // Save button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        // ✅ VALIDASI FORM JIKA fromQR = true
                        if (fromQR) {
                          final serialNumber = _serialNumberController.text
                              .trim();
                          if (serialNumber.isEmpty) {
                            Fluttertoast.showToast(
                              msg:
                                  "Serial number wajib diisi untuk input manual QR",
                              backgroundColor: Colors.orange,
                            );
                            return;
                          }
                          if (serialNumber.length < 2) {
                            Fluttertoast.showToast(
                              msg:
                                  "Serial number terlalu pendek. Minimal 2 karakter.",
                              backgroundColor: Colors.orange,
                            );
                            return;
                          }
                        }
                        _saveManualInput(product, fromQR: fromQR);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hijauGojek,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Simpan Data',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'MonaSans',
                            ),
                          ),
                        ],
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

  void _saveManualInput(OutDetailModel product, {bool fromQR = false}) async {
    final serialNumber = _serialNumberController.text.trim();
    final quantity = _quantity.value;

    // ✅ VALIDASI KHUSUS UNTUK MANUAL INPUT DARI QR (fromQR = true)
    if (fromQR && serialNumber.isEmpty) {
      Fluttertoast.showToast(
        msg: "Serial number harus diisi untuk input manual dari QR",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
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

    final bool hasSerialNumber = serialNumber.isNotEmpty;

    // Jika ada serial number, validasi format
    if (hasSerialNumber && serialNumber.length < 2) {
      Fluttertoast.showToast(
        msg: "Serial number terlalu pendek. Minimal 2 karakter.",
        backgroundColor: Colors.orange,
      );
      return;
    }

    try {
      // Show loading
      setState(() {
        isScanning = false;
      });

      // ✅ VALIDASI SERIAL NUMBER UNIK JIKA ADA
      if (hasSerialNumber) {
        debugPrint('🔍 Validasi serial number manual: $serialNumber');
        final isSerialNumberUnique = await _checkSerialNumberUniqueOptimized(
          serialNumber,
        );

        if (!isSerialNumberUnique) {
          Fluttertoast.showToast(
            msg:
                "Serial number '$serialNumber' sudah digunakan di sistem. Harus unik secara global!",
            backgroundColor: Colors.orange,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );
          return;
        }
        debugPrint('✅ Serial number manual valid: $serialNumber');
      }

      // ✅ TAMPILKAN DIALOG KONFIRMASI SEBELUM MENYIMPAN
      _showSaveConfirmationDialog(
        product,
        hasSerialNumber ? serialNumber : null,
        quantity,
        fromQR: fromQR,
        shouldCloseBottomSheet: true, // ✅ TUTUP BOTTOM SHEET SETELAH SIMPAN
        shouldNavigate: false, // ✅ JANGAN NAVIGASI
        onAfterSave: () {
          // ✅ CALLBACK SETELAH SIMPAN BERHASIL - TUTUP BOTTOM SHEET
          _logger.d('✅ Data manual berhasil disimpan, menutup bottom sheet...');

          // Reset form
          _resetForm();

          // Tampilkan toast sukses
          Fluttertoast.showToast(
            msg: "Data berhasil disimpan",
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        },
      );
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: "Gagal memvalidasi: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<String?> _generateAndStoredoId() async {
    // ✅ JIKA SUDAH ADA GR ID DARI PARAMETER, GUNAKAN ITU
    if (_currentdoId != null && _currentdoId!.isNotEmpty) {
      debugPrint('✅ Menggunakan GR ID dari parameter: $_currentdoId');
      return _currentdoId;
    }

    // ✅ JIKA SUDAH ADA GR ID YANG SUDAH DIGENERATE SEBELUMNYA
    if (_currentdoId != null && _isdoIdSavedToFirestore) {
      return _currentdoId;
    }

    try {
      final String soNumber = widget.from == "sync"
          ? widget.flag?.documentno ?? ""
          : _getCurrentOutModel().documentno ?? "";

      final String currentUser = globalVM.username.value;

      if (soNumber.isEmpty) {
        throw Exception("PO Number tidak ditemukan");
      }

      final deliveryOrderController = Get.find<DeliveryOrderController>();

      final result = await deliveryOrderController.saveGrWithGeneratedId(
        soNumber: soNumber,
        details: [],
        currentUser: currentUser,
      );

      if (result['success'] == true && result['doId'] != null) {
        final newdoId = result['doId'] as String;

        _safeSetState(() {
          _currentdoId = newdoId;
          _isdoIdSavedToFirestore = true;
        });

        debugPrint('✅ GR ID baru dibuat dan disimpan: $newdoId');
        return newdoId;
      } else {
        throw Exception(result['error'] ?? 'Gagal generate GR ID');
      }
    } catch (e) {
      debugPrint('❌ Error generating DO ID: $e');
      _showErrorDialog('Gagal generate DO ID: $e');
      return null;
    }
  }

  bool _isSameProductWithoutSerial(
    DeliveryOrderDetailModel existingDetail,
    DeliveryOrderDetailModel newDetail,
  ) {
    // Product ID harus sama
    if (existingDetail.productid != newDetail.productid) {
      return false;
    }

    // Keduanya harus tanpa serial number (null atau empty)
    final existingHasNoSerial =
        existingDetail.sn == null || existingDetail.sn!.isEmpty;
    final newHasNoSerial = newDetail.sn == null || newDetail.sn!.isEmpty;

    return existingHasNoSerial && newHasNoSerial;
  }

  // ✅ METHOD UNTUK MENJUMLAHKAN QUANTITY PADA DETAIL YANG SAMA
  List<DeliveryOrderDetailModel> _mergeDuplicateDetails(
    List<DeliveryOrderDetailModel> existingDetails,
    DeliveryOrderDetailModel newDetail,
  ) {
    final mergedDetails = List<DeliveryOrderDetailModel>.from(existingDetails);
    bool isMerged = false;

    for (int i = 0; i < mergedDetails.length; i++) {
      final existingDetail = mergedDetails[i];

      // Cek apakah detail sama (product id sama & tanpa serial number)
      if (_isSameProductWithoutSerial(existingDetail, newDetail)) {
        // Jumlahkan quantity
        mergedDetails[i] = DeliveryOrderDetailModel(
          sn: null, // Tetap tanpa serial number
          productid: existingDetail.productid,
          qty: existingDetail.qty + newDetail.qty,
        );
        isMerged = true;
        debugPrint(
          '✅ Quantity digabungkan: ${existingDetail.productid} (${existingDetail.qty} + ${newDetail.qty} = ${existingDetail.qty + newDetail.qty})',
        );
        break;
      }
    }

    // Jika tidak ada yang bisa digabungkan, tambahkan sebagai detail baru
    if (!isMerged) {
      mergedDetails.add(newDetail);
      debugPrint(
        '✅ Detail baru ditambahkan: ${newDetail.productid} (qty: ${newDetail.qty})',
      );
    }

    return mergedDetails;
  }

  // ✅ METHOD OPTIMIZED UNTUK VALIDASI SERIAL NUMBER DENGAN FIRESTORE QUERY
  Future<bool> _checkSerialNumberUniqueOptimized(String serialNumber) async {
    try {
      final trimmedSerial = serialNumber.trim();

      if (trimmedSerial.isEmpty) {
        return true; // No serial number means no uniqueness check needed
      }

      if (trimmedSerial.length < 2) {
        debugPrint('❌ Serial number terlalu pendek: $trimmedSerial');
        return false;
      }

      // --- START FIX: USE deliveryOrderCONTROLLER'S GLOBAL CHECK ---
      final deliveryOrderController = Get.find<DeliveryOrderController>();
      final isUnique = await deliveryOrderController.isSerialNumberUnique(
        trimmedSerial,
      );

      if (!isUnique) {
        debugPrint('❌ SERIAL NUMBER DUPLIKAT DITEMUKAN: $trimmedSerial');
      } else {
        debugPrint('✅ Serial number unik secara global: $trimmedSerial');
      }

      return isUnique;
      // --- END FIX ---
    } catch (e) {
      debugPrint('❌ Error during serial number check: $e');
      // Jika ada error, anggap tidak unik untuk mencegah duplikasi
      return false;
    }
  }

  // ✅ METHOD UNTUK CEK APAKAH ADA DATA YANG SUDAH DIINPUT
  bool _hasAnyDataInput() {
    return _pendingGrDetails.isNotEmpty;
  }

  // ✅ METHOD UNTUK CEK APAKAH ADA DATA DENGAN SERIAL NUMBER
  bool _hasSerialNumberData() {
    return _pendingGrDetails.any(
      (detail) => detail.sn != null && detail.sn!.isNotEmpty,
    );
  }

  // ✅ METHOD UNTUK CEK APAKAH ADA DATA TANPA SERIAL NUMBER
  bool _hasNonSerialNumberData() {
    return _pendingGrDetails.any(
      (detail) => detail.sn == null || detail.sn!.isEmpty,
    );
  }

  Future<void> _updateSOQTYDelivered(
    String productId,
    int addedQuantity,
  ) async {
    // 1. Dapatkan nomor dokumen PO
    final String documentNo = widget.flag?.documentno ?? "";
    if (documentNo.isEmpty) return;

    final docRef = FirebaseFirestore.instance.collection('out').doc(documentNo);
    _logger.i(
      "Akan meng-update qtydelivered di PO: $documentNo untuk Produk: $productId",
    );

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);
        if (!docSnapshot.exists) {
          throw "Dokumen PO $documentNo tidak ditemukan!";
        }

        // Ambil 'details' sebagai List<dynamic>
        List<dynamic> detailsDynamic = docSnapshot.data()?['details'] ?? [];

        // Konversi ke List<Map<String, dynamic>>
        List<Map<String, dynamic>> details = List<Map<String, dynamic>>.from(
          detailsDynamic,
        );

        bool productFound = false;
        for (int i = 0; i < details.length; i++) {
          // 2. Cari produk yang sesuai di dalam array 'details'
          //    (Ganti 'm_product_id' jika key di Firestore Anda berbeda)
          if (details[i]['m_product_id'] == productId) {
            // 3. Ambil nilai 'qtydelivered' saat ini
            //    (Ganti 'qtydelivered' jika key di Firestore Anda berbeda)
            double currentQty =
                (details[i]['qtydelivered'] as num?)?.toDouble() ?? 0.0;

            // 4. Tambahkan kuantitas baru dan update map
            details[i]['qtydelivered'] = currentQty + addedQuantity;

            productFound = true;
            _logger.i(
              "Produk $productId ditemukan. Qty baru: ${details[i]['qtydelivered']}",
            );
            break;
          }
        }

        if (productFound) {
          // 5. Tulis kembali seluruh array 'details' yang sudah diperbarui
          transaction.update(docRef, {'details': details});
        } else {
          _logger.w(
            "Produk $productId tidak ditemukan di PO $documentNo untuk di-update qtydelivered-nya",
          );
        }
      });

      _logger.i("Berhasil update qtydelivered di PO untuk $productId");
    } catch (e) {
      _logger.e("Gagal update qtydelivered di PO: $e");
      Fluttertoast.showToast(msg: "Gagal update data PO: $e");
    }
  }

  Future<void> _saveToFirestore(
    OutDetailModel product,
    String? serialNumber,
    int quantity, {
    bool shouldCloseBottomSheet = true,
    bool shouldNavigate = true, // ✅ PARAMETER BARU UNTUK KONTROL NAVIGASI
  }) async {
    try {
      final String productId = product.mProductId ?? "";

      // ✅ VALIDASI DASAR
      if (productId.isEmpty) throw Exception("Product ID tidak ditemukan");
      if (quantity <= 0) throw Exception("Quantity harus lebih dari 0");

      final String? trimmedSerial = serialNumber?.trim();
      final bool hasSerialNumber =
          trimmedSerial != null && trimmedSerial.isNotEmpty;

      // ✅ VALIDASI SERIAL NUMBER UNIK GLOBALLY (jika ada serial number)
      if (hasSerialNumber) {
        _logger.d('🔍 Memulai validasi serial number: $trimmedSerial');

        if (trimmedSerial.length < 2) {
          throw Exception("Serial number terlalu pendek. Minimal 2 karakter.");
        }

        // Validasi unik secara global
        final isSerialNumberUnique = await _validateSerialNumberBeforeSave(
          trimmedSerial,
        );

        if (!isSerialNumberUnique) {
          return; // Stop execution if validation fails
        }
        _logger.d('✅ : $trimmedSerial');
      }

      final deliveryOrderController = Get.find<DeliveryOrderController>();

      // ✅ BUAT DETAIL DATA
      final newDetail = DeliveryOrderDetailModel(
        sn: hasSerialNumber ? trimmedSerial : null,
        productid: productId,
        qty: quantity,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(
                hasSerialNumber
                    ? "Validasi & menyimpan serial number..."
                    : "Menyimpan data...",
              ),
            ],
          ),
        ),
      );

      String? doIdToUse = _currentdoId;
      if (doIdToUse == null) {
        doIdToUse = await _generateAndStoredoId();
        if (doIdToUse == null) {
          throw Exception('Gagal generate GR ID');
        }
      }

      final existingGr = await deliveryOrderController.getDeliveryOrderById(
        doIdToUse,
      );
      if (existingGr != null) {
        if (hasSerialNumber) {
          final isDuplicateInSameGr = existingGr.details.any(
            (detail) =>
                detail.sn != null &&
                detail.sn!.trim().toLowerCase() == trimmedSerial.toLowerCase(),
          );

          if (isDuplicateInSameGr) {
            throw Exception(
              "Serial number '$trimmedSerial' sudah digunakan dalam GR ini ($doIdToUse). "
              "Serial number harus unik.",
            );
          }
        }

        // Gunakan logika merge untuk menggabungkan quantity jika product sama tanpa serial
        final updatedDetails = _mergeDuplicateDetails(
          existingGr.details,
          newDetail,
        );

        // Update GR dengan detail yang baru (setelah merge) menggunakan method dengan validasi
        final updateResult = await deliveryOrderController
            .updateGrDetailsWithValidation(
              doId: doIdToUse,
              newDetails: updatedDetails,
            );

        if (mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        if (updateResult['success'] == true) {
          // ✅ UPDATE PENAMPUNG SEMENTARA DENGAN DATA TERBARU
          await _updateSOQTYDelivered(productId, quantity);
          _safeSetState(() {
            _pendingGrDetails.clear();
            _pendingGrDetails.addAll(updatedDetails);
            _isdoIdSavedToFirestore = true;
          });

          _logger.d('✅ Detail berhasil diproses ke GR: $doIdToUse');
          if (hasSerialNumber) {
            _logger.d('✅ Serial number berhasil disimpan: $trimmedSerial');
          }

          if (hasSerialNumber) {
            await deliveryOrderController.saveSerialNumberGlobal(
              serialNumber: trimmedSerial,
              doId: doIdToUse,
              productId: productId,
            );
          }

          if (shouldCloseBottomSheet &&
              mounted &&
              Navigator.of(context).canPop()) {
            _closeBottomSheet();
          }

          // ✅ MODIFIKASI: KONTROL NAVIGASI BERDASARKAN PARAMETER
          if (shouldNavigate) {
            _showSuccessDialog(
              doIdToUse,
              _pendingGrDetails.length,
              hasSerialNumber ? trimmedSerial : null,
            );
          } else {
            // ✅ JIKA TIDAK PERLU NAVIGASI, HANYA TAMPILKAN TOAST SUKSES
            Fluttertoast.showToast(
              msg: hasSerialNumber
                  ? "Serial number berhasil disimpan: $trimmedSerial"
                  : "Data berhasil disimpan ke GR",
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          }
        } else {
          throw Exception(updateResult['error'] ?? 'Gagal menambah detail');
        }
      } else {
        throw Exception('GR tidak ditemukan di Firestore');
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }

      _logger.e('❌ Error saving to Firestore: $e');

      if (shouldCloseBottomSheet && mounted && Navigator.of(context).canPop()) {
        _closeBottomSheet();
      }

      _showErrorDialog('Gagal menyimpan: $e');
    }
  }

  void _closeBottomSheet() {
    if (!mounted) return;

    _logger.d('🚪 Menutup bottom sheet...');

    // Cek apakah masih ada bottom sheet yang terbuka
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      _logger.d('✅ Bottom sheet berhasil ditutup');
    } else {
      _logger.d('ℹ️ Tidak ada bottom sheet yang terbuka');
    }

    // Reset state
    setState(() {
      checkingscan = false;
      isScanning = false;
    });

    _resetForm();

    // ✅ TIDAK ADA NAVIGASI DI SINI - TETAP DI HALAMAN IN_DETAIL_PAGE
  }

  // ✅ DIALOG SUKSES DENGAN GR ID
  // ✅ DIALOG SUKSES DENGAN INFORMASI SERIAL NUMBER
  void _showSuccessDialog(String doId, int totalItems, String? serialNumber) {
    // Hitung total quantity untuk ditampilkan
    final totalQuantity = _pendingGrDetails.fold<int>(
      0,
      (currentSum, detail) => currentSum + detail.qty,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Berhasil Disimpan"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Data berhasil disimpan dengan:"),
            SizedBox(height: 8),
            // GR ID Info
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.confirmation_number, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "DO ID: $doId",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),

            // Serial Number Info (jika ada)
            if (serialNumber != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Serial Number:",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          Text(
                            serialNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
            ],

            // Summary Info
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total item: $totalItems",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Total quantity: $totalQuantity",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  if (serialNumber != null) ...[
                    SizedBox(height: 4),
                    Text(
                      "Serial number: $serialNumber",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          // ✅ OPSI UTAMA: TETAP DI HALAMAN INI UNTUK INPUT LEBIH LANJUT
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Tetap di halaman ini untuk input lebih lanjut
              _safeSetState(() {
                checkingscan = false;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: hijauGojek),
            child: Text("Tambah Lagi"),
          ),

          // OPSI SEKUNDER: LIHAT DeliveryOrder (HANYA JIKA DIPERLUKAN)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToDeliveryOrderPage();
            },
            child: Text("Lihat DeliveryOrder"),
          ),
        ],
      ),
    );
  }

  void _navigateToDeliveryOrderPage() {
    // ✅ KOSONGKAN VARIABLE PENAMPUNG SEBELUM NAVIGASI
    _resetGrData();

    _logger.d('✅ Navigate to DeliveryOrderPage with DO ID: $_currentdoId');
    Get.offAll(() => DeliveryOrderPage());
  }

  // ✅ METHOD UNTUK KOSONGKAN VARIABLE PENAMPUNG
  void _safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  // ✅ PERBAIKI _resetGrData DENGAN SAFE SETSTATE
  void _resetGrData() {
    _safeSetState(() {
      _currentdoId = null;
      _isdoIdSavedToFirestore = false;
      _pendingGrDetails.clear();
    });
    debugPrint('🔄 GR data reset - variables cleared');
  }

  // ✅ DIALOG ERROR
  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("Gagal Menyimpan"),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _onDeletePressed(OutDetailModel outDetailModel) {
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
              if (outDetailModel.maktxUI != null)
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
                    outDetailModel.maktxUI ?? '',
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
                            (item) =>
                                item.mProductId == outDetailModel.mProductId,
                          );

                          // Hapus dari data utama
                          final currentModel = _getCurrentOutModel();
                          currentModel.details?.removeWhere(
                            (item) =>
                                item.mProductId == outDetailModel.mProductId,
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

  Widget _buildEnhancedHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          colors: [hijauGojek, hijauGojek],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false, // biar tidak nambah padding ekstra bawah
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _handleBackPress,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.from == "sync"
                              ? "${widget.flag?.documentno}"
                              : "${_getCurrentOutModel().documentno}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isReadOnlyMode
                              ? "Sales Order (View Only)"
                              : "Sales Order",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._buildActions(),
                ],
              ),
            ),
            if (_isSearching && !isReadOnlyMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _buildEnhancedSearchField(),
              ),
          ],
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
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: RefreshIndicator(
            backgroundColor: Colors.white,
            color: hijauGojek,
            onRefresh: _handleRefresh,
            child: Column(
              children: [
                _buildEnhancedHeader(),
                Expanded(
                  child: Obx(() {
                    // Tampilkan loading shimmer
                    if (isDetailsLoading.value) {
                      return _buildShimmerLoading();
                    }

                    // Tampilkan empty state untuk search
                    if (_isSearchActive.value &&
                        _paginatedDetailsList.isEmpty) {
                      return _buildSearchEmptyState();
                    }

                    // Tampilkan empty state normal
                    if (_paginatedDetailsList.isEmpty) {
                      return _buildEmptyState();
                    }

                    // ✅ TAMPILKAN DATA DENGAN PAGINATION
                    return CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(child: _buildModernHeaderInfo()),

                        // ✅ LIST DATA DENGAN PAGINATION
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            if (index < _paginatedDetailsList.length) {
                              return _buildModernProductCard(
                                _paginatedDetailsList[index],
                                index,
                              );
                            }
                            return SizedBox();
                          }, childCount: _paginatedDetailsList.length),
                        ),

                        // ✅ LOADING MORE INDICATOR
                        if (_isLoadingMore.value)
                          SliverToBoxAdapter(
                            child: _buildLoadingMoreIndicator(),
                          ),

                        // ✅ NO MORE DATA INDICATOR
                        if (!_hasMoreData.value &&
                            _paginatedDetailsList.isNotEmpty)
                          SliverToBoxAdapter(
                            child: _buildNoMoreDataIndicator(),
                          ),

                        // Bottom spacing
                        SliverToBoxAdapter(child: SizedBox(height: 150)),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: SingleChildScrollView(child: _buildModernBottomActionBar()),
          ),
        ),
      ),
    );
  }

  // Widget _buildRealtimeHeader() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.only(
  //         bottomLeft: Radius.circular(24),
  //         bottomRight: Radius.circular(24),
  //       ),
  //       gradient: LinearGradient(
  //         colors: [hijauGojek, hijauGojek],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       boxShadow: [
  //         BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Padding(
  //           padding: EdgeInsets.all(16),
  //           child: Row(
  //             children: [
  //               IconButton(
  //                 icon: Icon(Icons.arrow_back, color: Colors.white),
  //                 onPressed: _handleBackPress,
  //               ),
  //               Expanded(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     // Tampilkan status realtime
  //                     Row(
  //                       children: [
  //                         Container(
  //                           width: 8,
  //                           height: 8,
  //                           decoration: BoxDecoration(
  //                             color: isReadOnlyMode
  //                                 ? Colors.grey
  //                                 : Colors.blueAccent,
  //                             shape: BoxShape.circle,
  //                           ),
  //                         ),
  //                         SizedBox(width: 8),
  //                         Text(
  //                           isReadOnlyMode
  //                               ? "View Only"
  //                               : "Realtime", // ✅ TAMPILKAN STATUS MODE
  //                           style: TextStyle(
  //                             color: Colors.white70,
  //                             fontSize: 12,
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     SizedBox(height: 4),
  //                     Text(
  //                       widget.from == "sync"
  //                           ? "${widget.flag?.documentno}"
  //                           : "${_getCurrentOutModel().documentno}",
  //                       style: TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 18,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                     SizedBox(height: 4),
  //                     Text(
  //                       isReadOnlyMode
  //                           ? "Purchase Order Details (View Only)" // ✅ TEKS BERBEDA UNTUK MODE READ-ONLY
  //                           : "Purchase Order Details",
  //                       style: TextStyle(color: Colors.white70, fontSize: 14),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //               // ✅ SEMBUNYIKAN ACTION BUTTONS DI MODE READ-ONLY
  //               if (!isReadOnlyMode) ..._buildActions(),
  //             ],
  //           ),
  //         ),
  //         if (_isSearching &&
  //             !isReadOnlyMode) // ✅ HANYA TAMPILKAN SEARCH JIKA BUKAN READ-ONLY
  //           Container(
  //             padding: EdgeInsets.all(16),
  //             color: hijauGojek.withValues(alpha: 0.8),
  //             child: _buildSearchField(),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  Future<bool> _validateSerialNumberBeforeSave(String serialNumber) async {
    try {
      if (serialNumber.trim().isEmpty) {
        return true; // No serial number is allowed
      }

      final deliveryOrderController = Get.find<DeliveryOrderController>();
      final isUnique = await deliveryOrderController.isSerialNumberUnique(
        serialNumber,
      );

      if (!isUnique) {
        _showSerialNumberErrorDialog(serialNumber);
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('❌ Error validasi serial number: $e');
      return false;
    }
  }

  void _showSerialNumberErrorDialog(String serialNumber) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallDevice = screenWidth < 360;
    final double paddingValue = isSmallDevice ? 16.0 : 20.0;

    showDialog(
      context: context,
      barrierDismissible: false, // User harus menekan tombol secara eksplisit
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 400, // Maximum width untuk tablet
            minWidth: isSmallDevice ? 280 : 320,
          ),
          padding: EdgeInsets.all(paddingValue),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan icon dan title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade600,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Serial Number Sudah Digunakan",
                      style: TextStyle(
                        fontSize: isSmallDevice ? 18 : 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                        fontFamily: 'MonaSans',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Serial Number yang bermasalah
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Serial Number:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      serialNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade800,
                        fontFamily: 'Monospace',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Pesan error
              Text(
                "Serial number ini sudah digunakan di sistem dan tidak dapat digunakan kembali.",
                style: TextStyle(
                  fontSize: isSmallDevice ? 14 : 15,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 8),

              // Informasi tambahan
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Serial number harus unik secara global untuk semua product dan Good Receipt (GR).",
                        style: TextStyle(
                          fontSize: isSmallDevice ? 12 : 13,
                          color: Colors.orange.shade800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallDevice ? 12 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "OK",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isSmallDevice ? 14 : 15,
                        ),
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
                "SO Date",
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
          // ✅ SEMBUNYIKAN CONTAINER INPUT DI MODE READ-ONLY
          if (widget.from != "history" && !isReadOnlyMode)
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

  // Future<void> _sendToCperpWithLoading() async {
  //   if (_currentdoId == null) return;

  //   try {
  //     _isSendingToKafka.value = true;

  //     await _inController.sendToKafkaForGR(_currentdoId!);

  //     // Tunggu sebentar untuk memastikan status terupdate
  //     await Future.delayed(Duration(seconds: 2));

  //     Fluttertoast.showToast(
  //       msg: "Data berhasil dikirim ke CPERP",
  //       backgroundColor: Colors.green,
  //       textColor: Colors.white,
  //     );
  //   } catch (e) {
  //     Fluttertoast.showToast(
  //       msg: "Gagal mengirim ke CPERP: $e",
  //       backgroundColor: Colors.red,
  //       textColor: Colors.white,
  //     );
  //   } finally {
  //     _isSendingToKafka.value = false;
  //   }
  // }

  Future<void> _updateDeliveryOrderStatusToSuccess() async {
    // Ambil PO Document No dari widget, BUKAN GR ID
    final String? poDocumentNo = widget.flag?.documentno;

    if (poDocumentNo == null || poDocumentNo.isEmpty) {
      Fluttertoast.showToast(msg: "Error: SO Document Number tidak ditemukan!");
      return;
    }

    // Pastikan GR ID sudah ada (user sudah input setidaknya 1 item)
    if (_currentdoId == null) {
      Fluttertoast.showToast(
        msg: "Tidak ada data GR yang diinput untuk di-complete!",
      );
      return;
    }

    try {
      _isSendingToKafka.value = true; // Gunakan sebagai loading flag

      // --- BAGIAN 1: LOGIKA BARU UNTUK UPDATE PO ('in' collection) ---
      _logger.i(
        "Memulai update status 'is_fully_delivered' untuk PO: $poDocumentNo",
      );

      final poDocRef = FirebaseFirestore.instance
          .collection('out')
          .doc(poDocumentNo);

      // Gunakan Transaction untuk membaca, memodifikasi, dan menulis data PO
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(poDocRef);
        if (!docSnapshot.exists) {
          throw "Dokumen PO $poDocumentNo tidak ditemukan!";
        }

        final data = docSnapshot.data();
        if (data == null) {
          throw "Data Dokumen PO null!";
        }

        List<dynamic> detailsDynamic = data['details'] ?? [];
        List<Map<String, dynamic>> updatedDetails =
            List<Map<String, dynamic>>.from(detailsDynamic);

        // Flag untuk mengecek header
        bool allItemsAreFullyDelivered = true;

        if (updatedDetails.isEmpty) {
          // Jika tidak ada item, PO tidak bisa dianggap fully delivered
          allItemsAreFullyDelivered = false;
        }

        // 1. Cek setiap item di details
        for (int i = 0; i < updatedDetails.length; i++) {
          var item = updatedDetails[i];

          // Konversi ke num agar aman (bisa handle int atau double)
          num qtyDelivered = item['qtydelivered'] ?? 0;
          num qtyOrdered = item['qtyordered'] ?? 0;

          // 2. Bandingkan qtydelivered vs qtyordered
          // (Gunakan >= untuk keamanan jika ada over-delivery)
          if (qtyDelivered >= qtyOrdered && qtyOrdered > 0) {
            // 3. Update 'is_fully_delivered' di item
            item['is_fully_delivered'] = "Y";
            _logger.d("Item ${item['m_product_id']} di-set ke Y");
          } else {
            item['is_fully_delivered'] = "N";
            _logger.d("Item ${item['m_product_id']} di-set ke N");
            // 4. Jika satu item saja belum "Y", maka header juga "N"
            allItemsAreFullyDelivered = false;
          }
        }

        // 5. Siapkan data update untuk dokumen PO
        Map<String, dynamic> poUpdateData = {
          'details': updatedDetails, // Array details yang sudah diperbarui
          'is_fully_delivered': allItemsAreFullyDelivered
              ? "Y"
              : "N", // Field header utama
          'updated': FieldValue.serverTimestamp(), // Catat waktu update
          'updatedby': globalVM.username.value,
        };

        // 6. Update dokumen PO di dalam transaksi
        transaction.update(poDocRef, poUpdateData);
      });

      _logger.i("✅ Berhasil update 'is_fully_delivered' di PO: $poDocumentNo");

      // --- BAGIAN 2: LOGIKA ASLI (UPDATE 'good_receipt' collection) ---
      _logger.i("Memulai update status 'completed' untuk GR: $_currentdoId");

      await FirebaseFirestore.instance
          .collection('delivery_order')
          .doc(_currentdoId!)
          .set(
            {'status': 'completed'}, // Tandai GR sebagai 'completed'
            SetOptions(merge: true),
          );

      _logger.i("✅ Berhasil update status 'completed' di GR: $_currentdoId");

      // --- BAGIAN 3: FEEDBACK & NAVIGASI (Logika Asli) ---
      await Future.delayed(Duration(seconds: 1)); // Beri jeda sedikit

      Fluttertoast.showToast(
        msg: "Data PO & GR berhasil diupdate ke Completed",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      Future.delayed(const Duration(seconds: 1), () {
        Get.to(DeliveryOrderPage());
      });
    } catch (e) {
      _logger.e("❌ Gagal mengupdate status: $e");
      Fluttertoast.showToast(
        msg: "Gagal mengupdate status: $e",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      // Jangan navigasi jika gagal, biarkan user di halaman ini
    } finally {
      _isSendingToKafka.value = false;
    }
  }

  Widget _buildModernBottomActionBar() {
    return Obx(() {
      final displayList = _realtimeDetailsList.isNotEmpty
          ? _realtimeDetailsList
          : detailsList;

      final totalItems = displayList.length;
      final totalQty = _calculateTotalqtydelivered();

      final int totalInputItems = _pendingGrDetails.length;
      final int withSerialCount = _pendingGrDetails
          .where((d) => d.sn != null && d.sn!.isNotEmpty)
          .length;
      final int withoutSerialCount = totalInputItems - withSerialCount;

      if (isReadOnlyMode) {
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
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.visibility, color: Colors.grey, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "View Only Mode",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }

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
            // ✅ TAMPILKAN INFO GR JIKA SUDAH ADA
            if (_currentdoId != null || totalInputItems > 0)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _isdoIdSavedToFirestore
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isdoIdSavedToFirestore
                        ? Colors.green.shade200
                        : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GR ID Info
                    if (_currentdoId != null)
                      Row(
                        children: [
                          Icon(
                            _isdoIdSavedToFirestore
                                ? Icons.check_circle
                                : Icons.pending,
                            color: _isdoIdSavedToFirestore
                                ? Colors.green
                                : Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "DO ID: $_currentdoId",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isdoIdSavedToFirestore
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Data Input Summary
                    if (totalInputItems > 0) ...[
                      if (_currentdoId != null) SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Data Input:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            Row(
                              children: [
                                if (withSerialCount > 0)
                                  Text(
                                    "$withSerialCount SN",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                if (withSerialCount > 0 &&
                                    withoutSerialCount > 0)
                                  Text(" • ", style: TextStyle(fontSize: 11)),
                                if (withoutSerialCount > 0)
                                  Text(
                                    "$withoutSerialCount Non-SN",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Summary Items
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

            // ✅ TOMBOL ACTION
            if (widget.from != "history")
              Row(
                children: [
                  // Tombol Cancel / Kembali ke DeliveryOrder
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleCancelPress,
                      icon: Icon(
                        Icons.cancel,
                        color: _isdoIdSavedToFirestore
                            ? hijauGojek
                            : Colors.grey,
                      ),
                      label: Text(
                        _isdoIdSavedToFirestore
                            ? "Kembali ke DeliveryOrder"
                            : "Cancel",
                        style: TextStyle(
                          color: _isdoIdSavedToFirestore
                              ? hijauGojek
                              : Colors.grey,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: _isdoIdSavedToFirestore
                              ? hijauGojek
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  if (_currentdoId != null && _isdoIdSavedToFirestore) ...[
                    SizedBox(width: 12),
                    Expanded(
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('delivery_order')
                            .doc(_currentdoId)
                            .get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return SizedBox.shrink();
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>? ??
                              {};
                          final kafkaStatus = data['status'];
                          final bool isSent = kafkaStatus == "success";

                          return Obx(() {
                            // TAMPILKAN LOADING STATE DI BUTTON
                            if (_isSendingToKafka.value) {
                              return Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: hijauGojek.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Mengirim...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // TAMPILKAN BUTTON NORMAL
                            return ElevatedButton.icon(
                              onPressed: isSent
                                  ? null
                                  : _updateDeliveryOrderStatusToSuccess,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSent
                                    ? Colors.grey
                                    : hijauGojek,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                isSent
                                    ? Icons.check_circle
                                    : Icons.send_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: Text(
                                isSent ? 'Completed' : 'Complete GR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ],
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

  Future<void> _showMyDialogApprove(OutModel outDetailModel) async {
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
                        outDetailModel.approvedate = formattedDate;
                        outDetailModel.truck = containerinput.text;

                        final tDataList = outDetailModel.tData ?? [];

                        for (int i = 0; i < tDataList.length; i++) {
                          tDataList[i].appUser = globalVM.username.value;
                          tDataList[i].appVersion = globalVM.version.value;
                        }

                        outDetailModel.tData = tDataList;

                        List<Map<String, dynamic>> maptdata = tDataList
                            .map((item) => item.toMap())
                            .toList();

                        Get.back();
                        Get.back();

                        outDetailModel.dlvComp = "I";
                        bool sukses = await _outController.approveIn(
                          outDetailModel,
                          maptdata,
                        );
                        _outController.isapprove.value = true;

                        if (!sukses) {
                          Get.dialog(MyDialogAnimation("reject"));
                        } else {
                          Get.dialog(MyDialogAnimation("approve"));
                          await _outController.sendHistory(
                            outDetailModel,
                            maptdata,
                          );
                          if (widget.from != "sync" && ebeln != null) {
                            _outController.tolistSalesOrder.removeWhere(
                              (e) => e.ebeln == ebeln,
                            );
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

  Future _showMyDialog(OutDetailModel outDetailModel, String type) async {
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
                      '${outDetailModel.maktx}',
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
                                    _outController
                                        .tolistSalesOrder[widget.index]
                                        .tData ??
                                    [];

                                if (type == "ctn" && tabs == 0) {
                                  final int check = listPo
                                      .where(
                                        (element) =>
                                            element.matnr ==
                                            outDetailModel.matnr,
                                      )
                                      .length;

                                  if (check > 1) {
                                    final listpo = listPo
                                        .where(
                                          (element) =>
                                              (element.matnr ?? '').contains(
                                                outDetailModel.matnr ?? '',
                                              ),
                                        )
                                        .where(
                                          (element) =>
                                              !(element.cloned?.contains(
                                                    outDetailModel.cloned ?? '',
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
                                        (outDetailModel.menge?.toDouble() ??
                                            0) -
                                        ((hasilctn *
                                                (outDetailModel.umrez ?? 0)) +
                                            (currentCtn *
                                                (outDetailModel.umrez ?? 0)) +
                                            currentPcs +
                                            hasilpcs);

                                    if (!hasil.isNegative &&
                                        hasil <=
                                            (outDetailModel.menge?.toDouble() ??
                                                0)) {
                                      typeIndexctn = currentCtn;
                                    } else {
                                      final int hasil2 =
                                          (((outDetailModel.menge?.toDouble() ??
                                                          0) -
                                                      ((hasilctn *
                                                              (outDetailModel
                                                                      .umrez ??
                                                                  0)) +
                                                          currentPcs +
                                                          hasilpcs)) /
                                                  (outDetailModel.umrez == 0
                                                      ? 1
                                                      : (outDetailModel.umrez ??
                                                            1)))
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
                                        (currentCtn *
                                            (outDetailModel.umrez ?? 0)) +
                                        currentPcs;

                                    if (hasil <=
                                            (outDetailModel.menge?.toInt() ??
                                                0) &&
                                        (outDetailModel.menge?.toInt() ?? 0) >
                                            (outDetailModel.umrez ?? 0)) {
                                      typeIndexctn = currentCtn;
                                    } else {
                                      final int hasil2 =
                                          (((outDetailModel.menge?.toDouble() ??
                                                          0) -
                                                      currentPcs) /
                                                  (outDetailModel.umrez == 0
                                                      ? 1
                                                      : (outDetailModel.umrez ??
                                                            1)))
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
                                            element.matnr ==
                                            outDetailModel.matnr,
                                      )
                                      .length;

                                  if (check > 1) {
                                    final listpo = listPo
                                        .where(
                                          (element) =>
                                              element.matnr ==
                                              outDetailModel.matnr,
                                        )
                                        .where(
                                          (element) =>
                                              element.cloned !=
                                              outDetailModel.cloned,
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
                                        (outDetailModel.menge?.toInt() ?? 0) -
                                        ((hasilctn *
                                                (outDetailModel.umrez ?? 0)) +
                                            (currentCtn *
                                                (outDetailModel.umrez ?? 0)) +
                                            currentPcs +
                                            hasilpcs);

                                    if (!hasil.isNegative &&
                                        hasil <=
                                            (outDetailModel.menge?.toInt() ??
                                                0)) {
                                      typeIndexpcs = currentPcs;
                                    } else {
                                      final int hasil2 =
                                          (outDetailModel.menge?.toInt() ?? 0) -
                                          ((hasilctn *
                                                  (outDetailModel.umrez ?? 0)) +
                                              (currentCtn *
                                                  (outDetailModel.umrez ?? 0)) +
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
                                        (currentCtn *
                                            (outDetailModel.umrez ?? 0)) +
                                        currentPcs;

                                    if (hasil <=
                                        (outDetailModel.menge?.toInt() ?? 0)) {
                                      typeIndexpcs = currentPcs;
                                    } else {
                                      final int hasil2 =
                                          (outDetailModel.menge?.toInt() ?? 0) -
                                          (currentCtn *
                                              (outDetailModel.umrez ?? 0));
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

                                  if ((outDetailModel.menge ?? 0) <=
                                      typeIndexkg) {
                                    _controllerkg?.text =
                                        (outDetailModel.menge ?? 0).toString();
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
                                  _outController
                                      .tolistSalesOrder[widget.index]
                                      .tData ??
                                  [];

                              final check = listPo
                                  .where(
                                    (element) =>
                                        element.matnr == outDetailModel.matnr,
                                  )
                                  .length;

                              if (check > 1) {
                                final listpo = listPo
                                    .where(
                                      (element) =>
                                          element.matnr == outDetailModel.matnr,
                                    )
                                    .where(
                                      (element) =>
                                          element.cloned !=
                                          outDetailModel.cloned,
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
                                      (outDetailModel.menge?.toDouble() ?? 0) -
                                      ((hasilCtn *
                                              (outDetailModel.umrez ?? 0)) +
                                          (typeIndexctn *
                                              (outDetailModel.umrez ?? 0)) +
                                          typeIndexpcs +
                                          hasilPcs);

                                  if (hasil >= (outDetailModel.umrez ?? 0)) {
                                    typeIndexctn++;
                                    _controllerctn?.text = typeIndexctn
                                        .toString();
                                  }
                                } else if (type == "pcs") {
                                  final double hasil =
                                      (outDetailModel.menge?.toDouble() ?? 0) -
                                      ((hasilCtn *
                                              (outDetailModel.umrez ?? 0)) +
                                          (typeIndexctn *
                                              (outDetailModel.umrez ?? 0)) +
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

                                  if ((outDetailModel.menge ?? 0) <=
                                      typeIndexkg) {
                                    _controllerkg?.text =
                                        (outDetailModel.menge ?? 0).toString();
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
                                      (outDetailModel.menge?.toDouble() ?? 0) -
                                      ((typeIndexctn *
                                              (outDetailModel.umrez ?? 0)) +
                                          typeIndexpcs);

                                  if (hasil >= (outDetailModel.umrez ?? 0)) {
                                    typeIndexctn++;
                                    _controllerctn?.text = typeIndexctn
                                        .toString();
                                  }
                                } else if (type == "pcs") {
                                  final double hasil =
                                      (outDetailModel.menge?.toDouble() ?? 0) -
                                      ((typeIndexctn *
                                          (outDetailModel.umrez ?? 0)));

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

                                  if ((outDetailModel.menge ?? 0) <=
                                      typeIndexkg) {
                                    _controllerkg?.text =
                                        (outDetailModel.menge ?? 0).toString();
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

  Widget headerCard2History(OutDetailModel outDetailModel) {
    double baseWidth = 360.0028076172;
    double fem = MediaQuery.of(context).size.width / baseWidth;
    double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(8 * fem, 8 * fem, 17.88 * fem, 12 * fem),
      margin: EdgeInsets.fromLTRB(5 * fem, 0 * fem, 10 * fem, 10 * fem),
      width: double.infinity,
      height: outDetailModel.updated != "" ? 170 * fem : 100 * fem,
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
                    '${outDetailModel.maktx}',
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
                  'SKU: ${outDetailModel.matnr}',
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
                  'PO QTY : ${currency.format(outDetailModel.poqtyori ?? 0)} ${outDetailModel.pounitori ?? ''}',
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
                  visible: outDetailModel.descr != "",
                  child: Text(
                    'Description : ${outDetailModel.descr}',
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
                  visible: outDetailModel.updatedByUsername != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      'Update By: ${outDetailModel.updatedByUsername}',
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
                  visible: outDetailModel.updated != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      outDetailModel.updated != ""
                          ? 'Updated: ${globalVM.stringToDateWithTime(outDetailModel.updated ?? '')}'
                          : 'Updated: ${outDetailModel.updated}',
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
                  visible: outDetailModel.vfdat != "",
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 145 * fem),
                    child: Text(
                      outDetailModel.vfdat != ""
                          ? 'Exp Date: ${globalVM.dateToString(outDetailModel.vfdat ?? '')}'
                          : 'Exp Date: ${outDetailModel.vfdat}',
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
            visible: !(outDetailModel.maktx?.contains("Pallet") ?? false),
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
                        '${outDetailModel.qtctn}',
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
                      '${outDetailModel.qtuom}',
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

  Widget headerCard2(OutDetailModel outDetailModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double baseWidth = 360.0;
        final double fem = constraints.maxWidth / baseWidth;
        final double ffem = fem * 0.97;

        return Slidable(
          key: Key(outDetailModel.hashCode.toString()),
          groupTag: 'slidable_group',
          startActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.2,
            children: [
              SlidableAction(
                onPressed: (_) => _onAddPressed(outDetailModel),
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
                onPressed: (_) => _onDeletePressed(outDetailModel),
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
            height: (outDetailModel.updated?.isNotEmpty ?? false)
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
                Expanded(child: _buildLeftContent(outDetailModel, fem, ffem)),
                _buildQuantitySections(outDetailModel, fem, ffem),
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

  Widget _buildLeftContent(
    OutDetailModel outDetailModel,
    double fem,
    double ffem,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 145 * fem),
          child: Text(
            outDetailModel.maktx ?? '',
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
          'SKU: ${outDetailModel.matnr}',
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontSize: 13 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff9a9a9a),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'PO QTY: ${_formatNumber(outDetailModel.poqtyori)} ${outDetailModel.pounitori}',
          style: TextStyle(
            fontFamily: 'MonaSans',
            fontSize: 13 * ffem,
            fontWeight: FontWeight.w600,
            color: const Color(0xff9a9a9a),
          ),
        ),

        if ((outDetailModel.descr?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Description: ${outDetailModel.descr}',
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

        if ((outDetailModel.updatedByUsername?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Update By: ${outDetailModel.updatedByUsername}',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],

        if ((outDetailModel.updated?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Updated: ${_formatUpdatedDate(outDetailModel.updated ?? '')}',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 13 * ffem,
                fontWeight: FontWeight.w600,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ),
        ],

        if ((outDetailModel.vfdat?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(maxWidth: 145 * fem),
            child: Text(
              'Exp Date: ${_formatExpDate(outDetailModel.vfdat ?? '')}',
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

  Widget _buildQuantitySections(
    OutDetailModel outDetailModel,
    double fem,
    double ffem,
  ) {
    return Row(
      children: [
        if (_shouldShowCtnSection(outDetailModel)) ...[
          _buildQuantityItem(
            value: outDetailModel.qtctn.toString(),
            label: 'CTN',
            fem: fem,
            ffem: ffem,
          ),
          SizedBox(width: 12 * fem),
        ],
        _buildQuantityItem(
          value: outDetailModel.pounitori == "KG"
              ? outDetailModel.qtuom.toString()
              : outDetailModel.qtuom.toString(),
          label: outDetailModel.pounitori == "KG" ? 'KG' : 'PCS',
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

  bool _shouldShowCtnSection(OutDetailModel outDetailModel) {
    return outDetailModel.pounitori != "KG" &&
        !(outDetailModel.maktx?.contains("Pallet") ?? false);
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

  void _onAddPressed(OutDetailModel outDetailModel) {
    setState(() {
      if (widget.from == "sync") {
        _addToSyncList(outDetailModel);
      } else {
        _addToOutControllerList(outDetailModel);
      }
    });
  }

  void _addToSyncList(OutDetailModel outDetailModel) {
    final tData = widget.flag?.tData;
    if (tData == null) return;

    final clone2 = OutModel.clone(cloned);
    final clones =
        clone2.tData?.where((e) => e.matnr == outDetailModel.matnr).toList() ??
        [];

    for (int i = 0; i < clones.length; i++) {
      final clone = clones[i];
      clone.qtctn = 0;
      clone.qtuom = 0;
      clone.cloned = "cloned $i";
      tData.add(clone);
    }
  }

  void _addToOutControllerList(OutDetailModel outDetailModel) {
    final listPO = _outController.tolistSalesOrder[widget.index];
    final tData = listPO.tData;
    if (tData == null) return;

    final clone2 = OutModel.clone(cloned);
    final clones =
        clone2.tData?.where((e) => e.matnr == outDetailModel.matnr).toList() ??
        [];

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
              '${_outController.tolistSalesOrder[widget.index].truck}',
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
          _outController.tolistSalesOrder[widget.index].documentno != null,
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
                '${_outController.tolistSalesOrder[widget.index].documentno}',
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

  String _calculateTotalqtydelivered() {
    final displayList = _realtimeDetailsList.isNotEmpty
        ? _realtimeDetailsList
        : detailsList;

    final total = displayList.fold<double>(0, (currentSum, item) {
      final qtyOrdered = item.qtyordered ?? 0.0;
      final qtydelivered = item.qtydelivered ?? 0.0;
      final remainingQty = qtydelivered - qtyOrdered;
      return currentSum + (remainingQty > 0 ? remainingQty : 0);
    });
    return total.toStringAsFixed(2);
  }

  Widget _buildProductList(double fem, double ffem) {
    return Expanded(
      child: SizedBox(
        child: Obx(() {
          final listPO = _outController.tolistSalesOrder;
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
        ? '${_outController.dateToString(widget.flag?.aedat, "tes")}'
        : '${_outController.dateToString(_outController.tolistSalesOrder[widget.index].aedat, "tes")}';
  }

  String _getVendorValue() {
    return widget.from == "sync"
        ? '${widget.flag?.lifnr}'
        : '${_outController.tolistSalesOrder[widget.index].lifnr}';
  }

  int _getProductCount() {
    if (widget.from == "sync") {
      return widget.flag?.tData?.length ?? 0;
    } else {
      return _outController.tolistSalesOrder.isNotEmpty
          ? _outController.tolistSalesOrder[widget.index].tData?.length ?? 0
          : 0;
    }
  }

  int _getItemCount() {
    return _outController.tolistSalesOrder.isNotEmpty
        ? _outController.tolistSalesOrder[widget.index].tData?.length ?? 0
        : 0;
  }

  Future<void> _handleBackPress() async {
    // ✅ JIKA DALAM MODE READ-ONLY, LANGSUNG KEMBALI KE HOME PAGE
    if (isReadOnlyMode) {
      _logger.d('🔙 Read-only mode, navigating directly to Home');
      Get.until((route) => route.isFirst);
      return;
    }

    // ✅ CEK APAKAH HALAMAN INI DIBUKA DARI DeliveryOrder PAGE
    final bool isFromDeliveryOrderPage = widget.doId != null;

    // ✅ CEK APAKAH ADA DATA YANG SUDAH DIINPUT
    final bool hasAnyData = _hasAnyDataInput();
    final bool hasSerialData = _hasSerialNumberData();
    final bool hasNonSerialData = _hasNonSerialNumberData();

    debugPrint('🔍 Status data sebelum back:');
    debugPrint('   - From DeliveryOrder Page: $isFromDeliveryOrderPage');
    debugPrint('   - Total items: ${_pendingGrDetails.length}');
    debugPrint('   - Dengan serial number: $hasSerialData');
    debugPrint('   - Tanpa serial number: $hasNonSerialData');
    debugPrint('   - GR ID saved: $_isdoIdSavedToFirestore');

    // ✅ JIKA DIBUKA DARI DeliveryOrder PAGE → LANGSUNG KEMBALI KE DeliveryOrder PAGE
    if (isFromDeliveryOrderPage) {
      _logger.d(
        '🔙 Opened from DeliveryOrder Page, navigating back to DeliveryOrder Page',
      );

      if (hasAnyData) {
        _showSuccessToast("Data berhasil ditambahkan ke DO ID: $_currentdoId");
      }

      _resetGrData();
      Get.back();
      return;
    }

    // ✅ LOGIKA UNTUK HALAMAN YANG DIBUKA DARI IN PAGE
    if (hasAnyData && _isdoIdSavedToFirestore && _currentdoId != null) {
      // ✅ ADA DATA YANG SUDAH DIINPUT → TAWARKAN NAVIGASI KE DeliveryOrder PAGE
      _logger.d(
        '📦 Data sudah diinput, tawarkan navigasi ke DeliveryOrderPage',
      );

      final shouldNavigateToDeliveryOrder = await _showDataSavedDialog(
        hasSerialData: hasSerialData,
        hasNonSerialData: hasNonSerialData,
      );

      if (shouldNavigateToDeliveryOrder) {
        _navigateToDeliveryOrderPage();
      } else {
        _logger.d('👤 User memilih untuk lanjutkan input data');
      }
    }
    // ✅ JIKA BELUM ADA DATA SAMA SEKALI → LANGSUNG KEMBALI KE IN PAGE
    else if (!hasAnyData) {
      _logger.d('🔄 Tidak ada data yang diinput, kembali ke InPage');
      _resetGrData();
      Get.back();
    }
    // ✅ EDGE CASE: Ada data tapi belum disimpan
    else if (hasAnyData && !_isdoIdSavedToFirestore) {
      _logger.w(
        '⚠️ Ada data yang belum disimpan: ${_pendingGrDetails.length} items',
      );

      final shouldGoBack = await _showUnsavedDataDialog();

      if (shouldGoBack) {
        _resetGrData();
        Get.back();
      }
    }
  }

  // ================================
  // MODERN DIALOG COMPONENTS
  // ================================

  Future<bool> _showDataSavedDialog({
    required bool hasSerialData,
    required bool hasNonSerialData,
  }) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDevice = screenWidth < 360;
    final isTablet = screenWidth > 600;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(isTablet ? 80 : 20),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : double.infinity,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header dengan gradient
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallDevice ? 16 : 20,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00E676)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: isSmallDevice ? 24 : 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Data GR Telah Disimpan",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallDevice ? 16 : 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // GR ID Card
                          _buildInfoCard(
                            icon: Icons.confirmation_number_outlined,
                            iconColor: Color(0xFF00C853),
                            backgroundColor: Color(0xFFE8F5E8),
                            borderColor: Color(0xFFC8E6C9),
                            child: Text(
                              "DO ID: $_currentdoId",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D32),
                                fontSize: isSmallDevice ? 14 : 15,
                              ),
                            ),
                          ),

                          SizedBox(height: 16),

                          // Summary Data Card
                          _buildInfoCard(
                            icon: Icons.inventory_2_outlined,
                            iconColor: Color(0xFF2196F3),
                            backgroundColor: Color(0xFFE3F2FD),
                            borderColor: Color(0xFFBBDEFB),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total: ${_pendingGrDetails.length} items",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1565C0),
                                    fontSize: isSmallDevice ? 14 : 15,
                                  ),
                                ),
                                SizedBox(height: 8),
                                if (hasSerialData) ...[
                                  _buildDataItem(
                                    "Dengan serial number",
                                    _pendingGrDetails
                                        .where(
                                          (d) =>
                                              d.sn != null && d.sn!.isNotEmpty,
                                        )
                                        .length,
                                  ),
                                ],
                                if (hasNonSerialData) ...[
                                  _buildDataItem(
                                    "Tanpa serial number",
                                    _pendingGrDetails
                                        .where(
                                          (d) => d.sn == null || d.sn!.isEmpty,
                                        )
                                        .length,
                                  ),
                                ],
                              ],
                            ),
                          ),

                          SizedBox(height: 20),

                          // Description Text
                          Text(
                            "Data telah berhasil disimpan. Apakah Anda ingin melihat daftar DeliveryOrder?",
                            style: TextStyle(
                              fontSize: isSmallDevice ? 14 : 15,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Lanjutkan Input Button
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallDevice ? 10 : 12,
                                ),
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Lanjutkan Input",
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallDevice ? 13 : 14,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: 12),

                          // Lihat DeliveryOrder Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00C853),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallDevice ? 10 : 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                shadowColor: Color(
                                  0xFF00C853,
                                ).withValues(alpha: 0.3),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.list_alt_rounded,
                                    size: isSmallDevice ? 16 : 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Lihat DeliveryOrder",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: isSmallDevice ? 13 : 14,
                                    ),
                                  ),
                                ],
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
        ) ??
        false;
  }

  Future<bool> _showUnsavedDataDialog() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallDevice = screenWidth < 360;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  "Data Belum Disimpan",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            content: Text(
              "Ada ${_pendingGrDetails.length} item yang belum disimpan. "
              "Apakah Anda yakin ingin membatalkan?",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isSmallDevice ? 14 : 15,
              ),
            ),
            actions: [
              // Lanjutkan Input Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                child: Text(
                  "Lanjutkan Input",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              // Batalkan Input Button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Batalkan Input",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ================================
  // REUSABLE WIDGET COMPONENTS
  // ================================

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, int count) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: $count items",
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Color(0xFF00C853),
      textColor: Colors.white,
      fontSize: 14,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Widget _buildAppBarTitle(double fem, double ffem) {
    return Obx(() {
      final titleText = widget.from == "sync"
          ? widget.flag?.documentno ?? ''
          : _outController.tolistSalesOrder[widget.index].documentno ?? '';

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
    if (_isdoIdSavedToFirestore && _currentdoId != null) {
      // Jika sudah disimpan, tampilkan konfirmasi ke DeliveryOrderPage
      _handleBackPress();
    } else {
      // Jika belum disimpan, kembali ke InPage
      _showCancelConfirmation();
    }
  }

  // void _showNavigationConfirmation() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text("Lihat DeliveryOrder?"),
  //       content: Text(
  //         "Data GR sudah disimpan. Apakah Anda ingin melihat halaman DeliveryOrder?",
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: Text("Tambah Lagi"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.of(context).pop();
  //             _navigateToDeliveryOrderPage();
  //           },
  //           child: Text("Lihat DeliveryOrder"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showCancelConfirmation() {
    final BuildContext context = Get.context!;
    final bool hasPendingItems = _pendingGrDetails.isNotEmpty;
    final int pendingCount = _pendingGrDetails.length;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [hijauGojek, hijauGojekSecond],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasPendingItems
                            ? Icons.warning_amber_rounded
                            : Icons.help_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      hasPendingItems
                          ? "Batalkan Input?"
                          : "Konfirmasi Pembatalan",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'MonaSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Description
                    Text(
                      hasPendingItems
                          ? "Anda memiliki $pendingCount item yang belum disimpan. Semua data yang belum tersimpan akan hilang."
                          : "Apakah Anda yakin ingin membatalkan input? Perubahan yang belum disimpan akan hilang.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                        height: 1.5,
                        fontFamily: 'MonaSans',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Warning indicator untuk pending items
                    if (hasPendingItems) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFEF3C7)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFFD97706),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "$pendingCount item akan hilang",
                                style: const TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'MonaSans',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Lanjutkan Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: hijauGojek,
                          side: const BorderSide(color: hijauGojek),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text(
                          "Lanjutkan",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFamily: 'MonaSans',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Batalkan Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetGrData();
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          "Batalkan",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            fontFamily: 'MonaSans',
                          ),
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
    );
  }

  void _showSaveConfirmationDialog(
    OutDetailModel product,
    String? serialNumber,
    int quantity, {
    bool fromQR = false,
    bool shouldCloseBottomSheet = true,
    bool shouldNavigate = true,
    VoidCallback? onAfterSave,
  }) {
    final hasSerialNumber = serialNumber != null && serialNumber.isNotEmpty;
    final currentdoId = _currentdoId ?? "Akan digenerate";
    final productName =
        product.maktxUI ?? product.mProductId ?? "Unknown Product";
    final soNumber = widget.from == "sync"
        ? widget.flag?.documentno ?? ""
        : _getCurrentOutModel().documentno ?? "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan gradient
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [hijauGojek, hijauGojek.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bookmark_added_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Konfirmasi Penyimpanan",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Periksa kembali data Anda",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // GR ID Card
                    _buildInfoCardBackPress(
                      icon: Icons.tag_rounded,
                      iconColor: Colors.indigo,
                      backgroundColor: Colors.indigo.shade50,
                      title: "GR ID",
                      value: currentdoId,
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.shade50,
                          Colors.indigo.shade100.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // PO & Product Card
                    _buildInfoCardBackPress(
                      icon: Icons.receipt_long_rounded,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue.shade50,
                      title: "Purchase Order",
                      value: soNumber,
                      subtitle: productName,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Serial Number Card
                    _buildInfoCardBackPress(
                      icon: hasSerialNumber
                          ? Icons.qr_code_2_rounded
                          : Icons.qr_code_scanner_rounded,
                      iconColor: hasSerialNumber ? Colors.amber : Colors.grey,
                      backgroundColor: hasSerialNumber
                          ? Colors.amber.shade50
                          : Colors.grey.shade50,
                      title: hasSerialNumber
                          ? "Serial Number"
                          : "Tanpa Serial Number",
                      value: hasSerialNumber ? serialNumber : "-",
                      gradient: LinearGradient(
                        colors: hasSerialNumber
                            ? [
                                Colors.amber.shade50,
                                Colors.amber.shade100.withValues(alpha: 0.3),
                              ]
                            : [
                                Colors.grey.shade50,
                                Colors.grey.shade100.withValues(alpha: 0.3),
                              ],
                      ),
                    ),
                    SizedBox(height: 12),

                    // Quantity Card
                    _buildInfoCardBackPress(
                      icon: Icons.inventory_2_rounded,
                      iconColor: Colors.purple,
                      backgroundColor: Colors.purple.shade50,
                      title: "Kuantitas",
                      value: "$quantity unit",
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade50,
                          Colors.purple.shade100.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Warning text
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Data yang tersimpan tidak dapat diubah",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Container(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),

                    // Tombol Simpan
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hijauGojek,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          shadowColor: hijauGojek.withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Ya, Simpan",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
    ).then((confirmed) async {
      if (confirmed == true) {
        await _saveToFirestore(
          product,
          serialNumber,
          quantity,
          shouldCloseBottomSheet: shouldCloseBottomSheet,
          shouldNavigate: shouldNavigate,
        );

        if (onAfterSave != null) {
          onAfterSave();
        }
      }
    });
  }

  // Helper widget untuk info card
  Widget _buildInfoCardBackPress({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String value,
    String? subtitle,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleApprovePress(bool isSync) {
    final model = isSync
        ? widget.flag
        : _outController.tolistSalesOrder.isNotEmpty
        ? _outController.tolistSalesOrder[widget.index]
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
