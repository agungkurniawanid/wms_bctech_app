// [FILE LENGKAP: stock_take_detail.dart]

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms_bctech/controllers/auth/auth_controller.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/models/pid_document/pid_document_detail_model.dart';
import 'package:wms_bctech/models/stock/stock_take_detail_model.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart';
import 'package:logger/logger.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/models/pid_document/pid_document_model.dart';

class StockTakeDetail extends StatefulWidget {
  final StockTakeModel? stocktake;
  final int? index;
  final String? documentno;

  final bool isViewMode; // Mode preview/read-only
  final bool fromDocumentList; // Dari list PID document

  const StockTakeDetail({
    this.stocktake,
    this.index,
    this.documentno,
    this.isViewMode = false,
    this.fromDocumentList = false,
    super.key,
  });

  @override
  State<StockTakeDetail> createState() => _StockTakeDetailState();
}

class _StockTakeDetailState extends State<StockTakeDetail>
    with SingleTickerProviderStateMixin {
  // Definisi warna hijau Gojek
  final Color hijauGojek = const Color(0xFF00AA13);
  final Color hijauGojekLight = const Color(0xFF4CAF50);
  final Color hijauGojekDark = const Color(0xFF008A0E);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool allow = true;
  int idPeriodSelected = 1;
  String namechoice = "";
  ValueNotifier<List<String>> sortListBatch = ValueNotifier([]);
  ValueNotifier<List<String>> sortListSection = ValueNotifier([]);
  List<ItemChoice> listchoice = [];
  List<ItemChoice> listchoice2 = [];
  List<Category> listcategory = [];
  ScrollController controller = ScrollController();
  bool leading = true;
  GlobalKey srKey = GlobalKey();
  bool _isSearching = false;
  TextEditingController _searchQuery = TextEditingController();
  String searchQuery = '', barcodeScanRes = '';
  List<StockTakeDetailModel> detaillocal = [];
  ValueNotifier<String> selectedSection = ValueNotifier("");
  ValueNotifier<String> selectedBatch = ValueNotifier("");

  ValueNotifier<bool> checkboxvalidation = ValueNotifier(false);
  var choicein = "".obs;
  final TextEditingController _controllerbox = TextEditingController();
  final TextEditingController _controllerbun = TextEditingController();
  int tabs = 0;
  final Map<int, Widget> myTabs = const <int, Widget>{
    0: Text("BUN"),
    1: Text("BOX"),
  };
  FocusNode focusNode = FocusNode();
  int localctn = 0;
  double localpcs = 0.0;
  bool isScanning = false;

  late bool _isViewMode;
  late bool _fromDocumentList;

  // Data untuk list, BUKAN dari cache
  final List<Map<String, dynamic>> _dummyStockData = [];

  // 1. Dapatkan instance controller-nya
  final NewAuthController authController = Get.find<NewAuthController>();
  final GlobalVM globalVM = Get.find<GlobalVM>();

  // Variabel untuk cache data (physicalQty, different, labst)
  final List<PidDocumentDetailModel> _cachedPidDetails = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // ===================================================================
  // --- ✅ PERBAIKAN 1: Flag untuk mengatasi race condition ---
  // ===================================================================
  bool _isDataReady = false;
  // ===================================================================

  @override
  void initState() {
    super.initState();

    _isViewMode = widget.isViewMode;
    _fromDocumentList = widget.fromDocumentList;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // ===================================================================
    // --- ✅ PERBAIKAN 2: Panggil fungsi init asinkron ---
    // ===================================================================
    _initializeData();
    // ===================================================================

    _searchQuery = TextEditingController();
    sortListSection.value = ['A1-1', 'A1-2', 'B1-1', 'B1-2', 'C1-1'];
    selectedSection.value = 'A1-1';

    _animationController.forward();
  }

  // ===================================================================
  // --- ✅ PERBAIKAN 3: Buat fungsi init asinkron ---
  // ===================================================================
  Future<void> _initializeData() async {
    // 1. Populate _dummyStockData (ini cepat, dari data widget)
    _dummyStockData.clear();
    if (widget.stocktake?.detail != null &&
        widget.stocktake!.detail.isNotEmpty) {
      for (var productModel in widget.stocktake!.detail) {
        // productModel adalah StockTakeDetailModel

        // ===================================================================
        // --- ✅ PERBAIKAN 3.1: Buat Map secara manual ---
        // --- Ini untuk memperbaiki bug di mana productModel.toMap() ---
        // --- mungkin tidak menyertakan 'labst' atau 'matnr' ---
        // ===================================================================
        var productMap = {
          'matnr': productModel.matnr,
          'serno': productModel.serno,
          'maktx': productModel.maktx,

          // --- MODIFIKASI DISINI ---
          'labst': productModel.labst, // Pastikan tidak null
          'insme': productModel.insme, // Pastikan tidak null
          'speme': productModel.speme, // Pastikan tidak null
          // --- BATAS MODIFIKASI ---
          'isApprove': productModel.isApprove,
          'selectedChoice': productModel.selectedChoice,
          // 'checkboxValidation' akan ditambahkan di bawah
        };
        // ===================================================================

        productMap['checkboxValidation'] = ValueNotifier<bool>(false);
        // Set 'selectedChoice' HANYA jika belum ada
        if (productMap['selectedChoice'] == null ||
            (productMap['selectedChoice'] as String).isEmpty) {
          productMap['selectedChoice'] = 'UU';
        }

        _dummyStockData.add(productMap);
      }
    }

    // 2. Jika mode preview, AMBIL data cache dari Firestore
    //    Ini adalah data 'physicalQty' dan 'different' yang asli
    if (_fromDocumentList) {
      await _loadPidDocumentDetails(); // <-- TUNGGU (await) sampai selesai
    }

    // 3. Setelah semua data siap, set flag untuk re-render
    if (mounted) {
      setState(() {
        _isDataReady = true; // <-- Halaman siap di-build
      });
    }
  }
  // ===================================================================

  // ===================================================================
  // --- ✅ PERBAIKAN 4: Ubah _loadPidDocumentDetails ---
  // ===================================================================
  Future<void> _loadPidDocumentDetails() async {
    if (widget.documentno == null) return;

    // Hapus EasyLoading dari sini
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('pid_document')
          .doc(widget.documentno!)
          .get();

      if (docSnapshot.exists) {
        final pidDoc = PidDocumentModel.fromFirestore(docSnapshot, null);

        // JANGAN panggil setState di sini. Cukup isi data.
        // setState akan dipanggil oleh _initializeData()
        _cachedPidDetails.clear();
        _cachedPidDetails.addAll(
          pidDoc.products,
        ); // Ini berisi labst, physicalQty, different
        _logger.d(
          'Loaded ${_cachedPidDetails.length} items from cache for preview.',
        );
      }
    } catch (e) {
      _logger.e('Error loading PID document: $e');
      if (mounted) {
        EasyLoading.showError('Gagal memuat detail doc');
      }
    }
  }
  // ===================================================================

  @override
  void dispose() {
    _animationController.dispose();
    _searchQuery.dispose();
    _controllerbox.dispose();
    _controllerbun.dispose();
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  // [FILE: stock_take_detail.dart]

  String calculTotalbun(Map<String, dynamic> item, String validation) {
    final String? currentProductId = item['matnr']?.toString();
    final String? currentSerialNo = item['serno']?.toString();

    if (currentProductId == null) {
      return "0.0";
    }

    // Ambil data dari cache
    try {
      // --- MODIFIKASI DISINI ---
      final cachedDetail = _cachedPidDetails.firstWhere((detail) {
        if (detail.productId != currentProductId) return false;
        // Perbandingan ini (null == null) akan menghasilkan true
        return detail.productSN == currentSerialNo;
      });
      // --- BATAS MODIFIKASI ---

      // Jika ditemukan, tampilkan physicalQty yang tersimpan
      return (cachedDetail.physicalQty).toDouble().toString();
    } catch (e) {
      // Jika belum di-input (mode input), return 0.0
      return "0.0";
    }
  }

  // ===================================================================
  // --- ✅ FUNGSI INI SEKARANG AMAN KARENA _isDataReady ---
  // ===================================================================
  String calculTotalDifferent(Map<String, dynamic> item) {
    // 1. Dapatkan Stok Sistem
    String selectedChoice = item['selectedChoice'] ?? 'UU';
    double systemStock = 0.0;

    // 'item' adalah dari _dummyStockData
    // 'labst' di sini sudah benar karena perbaikan di _initializeData
    if (selectedChoice == "UU") {
      systemStock = (item['labst'] as num?)?.toDouble() ?? 0.0;
    } else if (selectedChoice == "QI") {
      systemStock = (item['insme'] as num?)?.toDouble() ?? 0.0;
    } else {
      systemStock = (item['speme'] as num?)?.toDouble() ?? 0.0;
    }

    // 2. Dapatkan Kuantitas Fisik & Selisih Tersimpan (dari cache)
    //    Karena kita 'await' _loadPidDocumentDetails, _cachedPidDetails
    //    pasti sudah terisi di mode preview.
    double physicalQty = 0.0;
    double? savedDifferent; // Ini adalah selisih yang tersimpan di Firestore

    final String? currentProductId = item['matnr']?.toString();
    final String? currentSerialNo = item['serno']?.toString();
    if (currentProductId != null) {
      try {
        // Cari data yang sesuai di cache
        final cachedDetail = _cachedPidDetails.firstWhere((detail) {
          if (detail.productId != currentProductId) return false;
          // Perbandingan ini (null == null) akan menghasilkan true
          return detail.productSN == currentSerialNo;
        });
        // Ambil data dari cache
        physicalQty = cachedDetail.physicalQty.toDouble();
        savedDifferent = cachedDetail.different;
      } catch (e) {
        // Belum ada di cache (terjadi saat mode input),
        // jadi physicalQty tetap 0
      }
    }

    // 3. Logika Tampilan
    //    Jika ini mode preview (isViewMode) DAN ada nilai selisih yang tersimpan,
    //    Tampilkan nilai yang tersimpan itu.
    //    INILAH YANG MEMPERBAIKI BUG PREVIEW ANDA.
    if (_isViewMode && savedDifferent != null) {
      return savedDifferent.toString();
    }

    //    Jika ini mode input, ATAU mode preview tapi data lama (savedDifferent=null),
    //    hitung selisihnya secara real-time.
    final double liveDifferent = systemStock - physicalQty;
    return liveDifferent.toString();
  }
  // ===================================================================

  String conversion(
    Map<String, dynamic> models,
    String name,
    String validation,
  ) {
    try {
      if (name == "KG") {
        return "-";
      } else {
        return "-";
      }
    } catch (e) {
      Logger().e(e);
      return "-";
    }
  }

  String calculTotalStockPCS(Map<String, dynamic> item, String flag) {
    return flag == "stock" ? "100" : "50";
  }

  String calculTotalStockCTN(Map<String, dynamic> item, String flag) {
    return flag == "stock" ? "20" : "10";
  }

  String calcultotalbox(Map<String, dynamic> item) {
    return "5.0";
  }

  String calculTotalpcs(Map<String, dynamic> item) {
    return "25.0";
  }

  Widget headerCard2(Map<String, dynamic> inmodel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: hijauGojek.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: hijauGojek.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hijauGojek.withValues(alpha: 0.3),
                  hijauGojekLight.withValues(alpha: 0.07),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [hijauGojek, hijauGojekDark],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              inmodel['maktx'] ?? 'Nama Produk Tdk Tersedia',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Info Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            icon: Icons.qr_code_2_rounded,
                            label: 'Box',
                            value: '0',
                            color: Colors.blue,
                          ),
                          _buildInfoChip(
                            icon: Icons.tag_rounded,
                            label: 'SKU',
                            value: inmodel['matnr'] ?? '0.0',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),

          // Status Chips Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: ["UU", "QI", "BLOCK"].map((choice) {
                final isSelected = inmodel['selectedChoice'] == choice;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        if (_isViewMode) return;
                        setState(() {
                          inmodel['selectedChoice'] = choice;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: choice == "UU"
                                      ? [hijauGojek, hijauGojekDark]
                                      : choice == "QI"
                                      ? [
                                          Colors.orange.shade400,
                                          Colors.orange.shade600,
                                        ]
                                      : [
                                          Colors.red.shade400,
                                          Colors.red.shade600,
                                        ],
                                )
                              : null,
                          color: isSelected ? null : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        (choice == "UU"
                                                ? hijauGojek
                                                : choice == "QI"
                                                ? Colors.orange
                                                : Colors.red)
                                            .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          choice,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Data Table Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [hijauGojekDark, hijauGojek],
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildTableHeaderCell('Unit', flex: 2),
                        _buildTableHeaderCell('Bun', flex: 2),
                        _buildTableHeaderCell('Box', flex: 2),
                        _buildTableHeaderCell('KG', flex: 2),
                      ],
                    ),
                  ),

                  // Stock Row
                  _buildDataRow(
                    label: 'Stock',
                    labelColor: hijauGojekDark,
                    values: [
                      inmodel['selectedChoice'] == "UU"
                          ? '${inmodel['labst']}'
                          : inmodel['selectedChoice'] == "QI"
                          ? '${inmodel['insme']}'
                          : '${inmodel['speme']}',
                      conversion(inmodel, "Box", "tampilan"),
                      conversion(inmodel, "KG", "tampilan"),
                    ],
                    isEven: true,
                  ),

                  // Physical Row
                  _buildDataRow(
                    label: 'Physical',
                    labelColor: Colors.blue.shade700,
                    values: [calculTotalbun(inmodel, "Bun"), "-", "-"],
                    isEven: false,
                  ),

                  // Different Row
                  _buildDataRow(
                    label: 'Different',
                    labelColor: const Color.fromARGB(255, 56, 55, 55),
                    values: [
                      calculTotalDifferent(inmodel), // <-- DIPANGGIL DI SINI
                      "-",
                      "-",
                    ],
                    isEven: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required Color labelColor,
    required List<String> values,
    required bool isEven,
  }) {
    return Container(
      color: isEven ? Colors.grey.shade50 : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          ...values.map(
            (value) => Expanded(
              flex: 2,
              child: Text(
                (value.isEmpty || value == "null") ? "-" : value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No Image Available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget modalBottomSheet(
    Map<String, dynamic> indetail,
    List<Map<String, dynamic>> inDetailList,
  ) {
    // Data untuk dropdown
    final List<String> sectionList = ['A'];
    final List<String> palletList = ['1'];
    final List<String> cellList = ['1'];

    final bool isReadOnly = _isViewMode;

    // Cari data yang sudah ada di cache
    PidDocumentDetailModel? existingDetail;
    try {
      String? itemSerno = indetail['serno']?.toString();
      existingDetail = _cachedPidDetails.firstWhere((d) {
        if (d.productId != indetail['matnr']?.toString()) return false;
        // Perbandingan ini (null == null) akan menghasilkan true
        return d.productSN == itemSerno;
      });
    } catch (e) {
      existingDetail = null;
    }

    // State untuk form
    String selectedSection = sectionList.first;
    String selectedPallet = palletList.first;
    String selectedCell = cellList.first;

    // Inisialisasi controller dengan data cache jika ada, jika tidak, '0'
    TextEditingController bunController = TextEditingController(
      text: existingDetail?.physicalQty.toString() ?? '0',
    );

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      hijauGojek.withValues(alpha: 0.1),
                      hijauGojekLight.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isReadOnly
                              ? [Colors.grey, Colors.grey.shade700]
                              : [hijauGojek, hijauGojekDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isReadOnly
                            ? Icons.visibility_rounded
                            : Icons.edit_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReadOnly ? 'View Product' : 'Edit Product',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${indetail['matnr'] ?? 'N/A'} - ${indetail['maktx'] ?? 'Nama Produk Tdk Tersedia'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isReadOnly
                                  ? Colors.grey.shade700
                                  : hijauGojekDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isReadOnly) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                ),
                              ),
                              child: Text(
                                'VIEW ONLY',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.grey.shade600,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // images
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              (indetail['image'] != null &&
                                  indetail['image'].toString().isNotEmpty)
                              ? Image.network(
                                  indetail['image'].toString(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildNoImagePlaceholder();
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                )
                              : _buildNoImagePlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Material/SKU/Product ID
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildReadOnlyField(
                                label: 'Material/SKU/Product ID',
                                value: indetail['matnr']?.toString() ?? 'N/A',
                                icon: Icons.qr_code_rounded,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildReadOnlyField(
                                label: 'Compatible',
                                value: '0',
                                icon: Icons.settings_suggest_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Material Description
                      _buildReadOnlyField(
                        label: 'Material Description',
                        value:
                            indetail['maktx']?.toString() ??
                            'Nama Produk Tdk Tersedia',
                        icon: Icons.description_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Stock Bun
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildReadOnlyField(
                                label: 'Stock Bun',
                                value: indetail['labst']?.toString() ?? '0.0',
                                icon: Icons.inventory_2_rounded,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildReadOnlyField(
                                label: 'Stock Box',
                                value: '0.0',
                                icon: Icons.inventory_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Section Dropdown (Read Only)
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildReadOnlyDropdown(
                                label: 'Section',
                                value: selectedSection,
                                items: sectionList,
                                icon: Icons.location_on_rounded,
                                onChanged: (value) {}, // read-only
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildReadOnlyField(
                                label: 'Total Physical Bun',
                                value: '0.0',
                                icon: Icons.inventory_2_rounded,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildReadOnlyField(
                                label: 'Total Physical Box',
                                value: '0.0',
                                icon: Icons.pallet,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bun Input Field (Bisa diinput)
                      Row(
                        children: [
                          // Bun Input
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: isReadOnly
                                  ? _buildReadOnlyField(
                                      label: 'Bun',
                                      value:
                                          existingDetail?.physicalQty
                                              .toString() ??
                                          '0',
                                      icon: Icons.add_circle_outline_rounded,
                                    )
                                  : _buildInputField(
                                      label: 'Bun',
                                      controller: bunController,
                                      icon: Icons.add_circle_outline_rounded,
                                      keyboardType: TextInputType.number,
                                      autoFocus: true,
                                    ),
                            ),
                          ),

                          // Box (Read Only)
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildReadOnlyField(
                                label: 'Box',
                                value: '0',
                                icon: Icons.all_inbox_rounded,
                              ),
                            ),
                          ),

                          // Pallet Dropdown (Read Only)
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildReadOnlyDropdown(
                                label: 'Pallet',
                                value: selectedPallet,
                                items: palletList,
                                icon: Icons.inventory_2_rounded,
                                onChanged: (value) {}, // read-only
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: // Cell Dropdown (Read Only)
                              _buildReadOnlyDropdown(
                                label: 'Cell',
                                value: selectedCell,
                                items: cellList,
                                icon: Icons.grid_view_rounded,
                                onChanged:
                                    (
                                      value,
                                    ) {}, // Tidak melakukan apa-apa karena read only
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: _buildReadOnlyField(
                                label: 'Total Physical Bun',
                                value: '0.0',
                                icon: Icons.inventory_2_rounded,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildReadOnlyField(
                                label: 'Total Physical Box',
                                value: '0.0',
                                icon: Icons.pallet,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Product SN
                      Visibility(
                        visible: false,
                        child: _buildReadOnlyField(
                          label: 'Product SN',
                          value: indetail['matnr']?.toString() ?? 'N/A',
                          icon: Icons.numbers_rounded,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isReadOnly) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Validasi input bun
                            if (bunController.text.isEmpty) {
                              EasyLoading.showError('Field Bun harus diisi');
                              return;
                            }

                            final bunValue = double.tryParse(
                              bunController.text,
                            );
                            if (bunValue == null) {
                              EasyLoading.showError(
                                'Field Bun harus berupa angka',
                              );
                              return;
                            }

                            // ===================================================================
                            // --- ✅ PERBAIKAN 5: Simpan 'labst' ke cache ---
                            // ===================================================================

                            // 1. Dapatkan Stok Sistem
                            String selectedChoice =
                                indetail['selectedChoice'] ?? 'UU';
                            double systemStock = 0.0;
                            if (selectedChoice == "UU") {
                              systemStock =
                                  (indetail['labst'] as num?)?.toDouble() ??
                                  0.0;
                            } else if (selectedChoice == "QI") {
                              systemStock =
                                  (indetail['insme'] as num?)?.toDouble() ??
                                  0.0;
                            } else {
                              systemStock =
                                  (indetail['speme'] as num?)?.toDouble() ??
                                  0.0;
                            }

                            // 2. Hitung Selisih
                            final double different = systemStock - bunValue;

                            EasyLoading.show(
                              status: 'Caching...',
                              maskType: EasyLoadingMaskType.black,
                            );

                            // Buat model detail
                            final newDetail = PidDocumentDetailModel(
                              // --- PERBAIKAN DI SINI ---
                              // 'productId' tidak boleh null, jadi 'N/A' adalah fallback
                              // 'productSN' HARUS null jika datanya null.
                              productId: indetail['matnr']?.toString() ?? 'N/A',
                              productSN:
                                  indetail['serno'], // <-- Cukup teruskan nilainya (bisa String atau null)

                              // --- BATAS PERBAIKAN ---
                              physicalQty: bunValue.toInt(),
                              different: different,
                              labst: systemStock,
                            );
                            // ===================================================================

                            // Cek apakah sudah ada di cache, jika ada, replace
                            final existingIndex = _cachedPidDetails.indexWhere((
                              d,
                            ) {
                              if (d.productId != newDetail.productId)
                                return false;
                              // Perbandingan ini (null == null) akan menghasilkan true
                              return d.productSN == newDetail.productSN;
                            });

                            if (existingIndex != -1) {
                              _cachedPidDetails[existingIndex] =
                                  newDetail; // Replace
                            } else {
                              _cachedPidDetails.add(newDetail); // Add new
                            }

                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );
                            if (!context.mounted) return;
                            EasyLoading.dismiss();
                            Navigator.of(context).pop();
                            EasyLoading.showSuccess('Data cached locally!');
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: hijauGojek,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Save',
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadOnlyField({
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
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyDropdown({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
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
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  items: items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.grey.shade500,
                  ),
                  dropdownColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
    bool autoFocus = false,
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
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hijauGojek.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            autofocus: autoFocus,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(icon, size: 20, color: hijauGojek),
              hintText: 'Enter $label',
              hintStyle: TextStyle(color: Colors.grey.shade400),
            ),
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchQuery,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        onChanged: updateSearchQuery,
      ),
    );
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

  void _startSearch() {
    setState(() {
      detaillocal.clear();
      for (var i = 0; i < _dummyStockData.length; i++) {
        detaillocal.add(StockTakeDetailModel.fromJson(_dummyStockData[i]));
      }
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
      _isSearching = false;
      _searchQuery.clear();
      _isSearching = false;
      detaillocal.clear();
    });
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return <Widget>[
        IconButton(
          icon: const Icon(Icons.clear_rounded, size: 24, color: Colors.white),
          onPressed: () {
            if (_searchQuery.text.isEmpty) {
              _stopSearching();
              return;
            }
            _clearSearchQuery();
          },
          tooltip: 'Clear',
        ),
        const SizedBox(width: 4),
      ];
    }
    return <Widget>[
      IconButton(
        icon: const Icon(
          Icons.assignment_rounded,
          size: 24,
          color: Colors.white,
        ),
        onPressed: () async {
          EasyLoading.showInfo('Counted page - Dummy Function');
        },
        tooltip: 'Counted',
      ),
      IconButton(
        icon: const Icon(
          Icons.qr_code_scanner_rounded,
          size: 24,
          color: Colors.white,
        ),
        onPressed: _scanBarcodeDummy,
        tooltip: 'Scan Barcode',
      ),
      IconButton(
        icon: const Icon(Icons.search_rounded, size: 24, color: Colors.white),
        onPressed: _startSearch,
        tooltip: 'Search',
      ),
      const SizedBox(width: 4),
    ];
  }

  void _scanBarcodeDummy() {
    setState(() {
      barcodeScanRes = 'DUMMY_BARCODE_${DateTime.now().millisecondsSinceEpoch}';
    });

    EasyLoading.showSuccess('Barcode scanned: $barcodeScanRes');
    if (_dummyStockData.isNotEmpty) {
      final product = _dummyStockData[0];
      _onProductTap(product, 0);
    }
  }

  Future<String> _generatePidId(String orgValue) async {
    // Format: PID<orgValue><yy>
    final currentYearYY = DateTime.now().year.toString().substring(2); // '25'
    final docPrefix = 'PID$orgValue$currentYearYY'; // 'PID276025'

    try {
      final generatedPidId = await _firestore.runTransaction<String>((
        transaction,
      ) async {
        // Query dokumen di tahun ini
        final lastPidQuery = await _firestore
            .collection('pid_document')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: docPrefix)
            .where(
              FieldPath.documentId,
              isLessThan: 'PID$orgValue${int.parse(currentYearYY) + 1}',
            )
            .orderBy(FieldPath.documentId, descending: true)
            .limit(1)
            .get();

        int nextSequence = 1;

        if (lastPidQuery.docs.isNotEmpty) {
          final lastPidId = lastPidQuery.docs.first.id;
          final sequenceMatch = RegExp(r'(\d{4})$').firstMatch(lastPidId);

          if (sequenceMatch != null) {
            final lastSequence = int.tryParse(sequenceMatch.group(1)!) ?? 0;
            nextSequence = lastSequence + 1;
          }
        }

        final sequenceString = nextSequence.toString().padLeft(4, '0');
        final newPidId = '$docPrefix$sequenceString';

        final existingDocSnapshot = await transaction.get(
          _firestore.collection('pid_document').doc(newPidId),
        );

        if (existingDocSnapshot.exists) {
          nextSequence++;
          final retrySequenceString = nextSequence.toString().padLeft(4, '0');
          final retryPidId = '$docPrefix$retrySequenceString';

          final retryDocSnapshot = await transaction.get(
            _firestore.collection('pid_document').doc(retryPidId),
          );

          if (retryDocSnapshot.exists) {
            throw Exception('PID ID collision, please try again');
          }
          return retryPidId;
        }

        return newPidId;
      }, timeout: const Duration(seconds: 10));

      _logger.d('✅ Generated PID ID: $generatedPidId');
      return generatedPidId;
    } catch (e) {
      _logger.e('❌ Error generating PID ID: $e');
      throw Exception('Gagal generate PID ID: $e');
    }
  }

  Future<void> _generateAndSavePidDocument() async {
    try {
      final orgValue = widget.stocktake?.orgValue ?? 'NA';
      final String newPidId = await _generatePidId(orgValue);
      final String createdBy = globalVM.username.value.isEmpty
          ? "Demo User"
          : globalVM.username.value;
      final String? whName = widget.stocktake?.whName;
      final String? whValue = widget.stocktake?.whValue;
      final String? orgName = widget.stocktake?.orgName;
      final String? locatorValue = widget.stocktake?.locatorValue;

      final PidDocumentModel pidDoc = PidDocumentModel(
        pidDocument: newPidId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        status: 'completed',
        whValue: whValue,
        whName: whName,
        locatorValue: locatorValue,
        orgValue: orgValue,
        orgName: orgName,
        products:
            _cachedPidDetails, // Ini sudah berisi 'labst', 'physicalQty', dan 'different'
      );

      await _firestore
          .collection('pid_document')
          .doc(newPidId)
          .set(pidDoc.toFirestore());

      _logger.d('✅ PID Document $newPidId saved successfully.');
    } catch (e) {
      _logger.e('❌ Error saving PID Document: $e');
      throw Exception('Gagal menyimpan dokumen: $e');
    }
  }

  Future _showMyDialogApprove(Map<String, dynamic> stockmodel) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
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
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirm Save',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure to save this stock take document?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hijauGojek.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hijauGojek.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: hijauGojekDark,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This will save all stock take data permanently',
                        style: TextStyle(
                          fontSize: 13,
                          color: hijauGojekDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!mounted) return;
                        EasyLoading.show(status: 'Saving Document...');
                        try {
                          await _generateAndSavePidDocument();
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          EasyLoading.showSuccess(
                            'Document saved successfully!',
                          );
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                          Get.back();
                        } catch (e) {
                          _logger.e('Error during approve process: $e');
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          EasyLoading.showError(
                            'Failed to save document: ${e.toString()}',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: hijauGojek,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save',
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
      canPop: allow,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        floatingActionButton: _buildFloatingActionButtons(),
        appBar: AppBar(
          elevation: 0,
          actions: _buildActions(),
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: _onBackPressed,
              color: Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [hijauGojek, hijauGojekDark],
              ),
            ),
          ),
          title: _isSearching
              ? _buildSearchField()
              : Text(
                  widget.stocktake?.whName ?? 'Document Not Found',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
          centerTitle: false,
        ),
        // ===================================================================
        // --- ✅ PERBAIKAN 6: Tampilkan loading jika data belum siap ---
        // ===================================================================
        body: !_isDataReady
            ? Center(child: CircularProgressIndicator(color: hijauGojek))
            : Column(children: [_buildHeaderSection(), _buildProductList()]),
        // ===================================================================
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    if (!_isApproveVisible() || _isViewMode) {
      return const SizedBox.shrink();
    }

    bool isApproveDisabled = _cachedPidDetails.length != _dummyStockData.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: _onEmailPressed,
          backgroundColor: Colors.orange.shade600,
          heroTag: "emailBtn",
          elevation: 4,
          child: const Icon(
            Icons.email_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        FloatingActionButton.extended(
          onPressed: isApproveDisabled ? null : _onApprovePressed,
          backgroundColor: isApproveDisabled
              ? Colors.grey.shade400
              : Colors.blueAccent,
          foregroundColor: isApproveDisabled
              ? Colors.grey.shade600
              : Colors.white,
          heroTag: "approveBtn",
          elevation: isApproveDisabled ? 0 : 4,
          icon: Icon(
            isApproveDisabled ? Icons.lock_rounded : Icons.check_circle_rounded,
            size: 24,
          ),
          label: Text(
            isApproveDisabled
                ? 'Complete all (${_cachedPidDetails.length}/${_dummyStockData.length})'
                : 'Approve',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }

  bool _isApproveVisible() {
    return (widget.stocktake?.isApprove ?? "N") == "N";
  }

  void _onEmailPressed() {
    EasyLoading.showInfo('Email sent successfully!');
  }

  void _onApprovePressed() {
    Map<String, dynamic> dummyData = {
      'documentno': widget.stocktake?.documentid ?? 'DUMMY_DOC',
      'isapprove': 'N',
    };
    _showMyDialogApprove(dummyData);
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                hijauGojek.withValues(alpha: 0.1),
                hijauGojekLight.withValues(alpha: 0.05),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: hijauGojek.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: hijauGojekDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getDataCountText(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: hijauGojekDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 6),
                    Obx(
                      () => Text(
                        globalVM.username.value.isEmpty
                            ? 'Demo User'
                            : TextHelper.formatUserName(
                                globalVM.username.value,
                              ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: listchoice.map((e) {
              final isSelected = idPeriodSelected == e.id;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _onChipSelected(e),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [hijauGojek, hijauGojekDark],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? hijauGojek : Colors.grey.shade300,
                          width: isSelected ? 0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: hijauGojek.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        e.labelName ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDataCountText() {
    // Fungsi ini sekarang aman karena _isDataReady
    final cachedCount = _cachedPidDetails.length;
    return '$cachedCount of ${_dummyStockData.length}';
  }

  void _onChipSelected(ItemChoice e) {
    setState(() {
      idPeriodSelected = e.id ?? 0;
      final choice = idPeriodSelected - 1;
      namechoice = listchoice[choice].label ?? '';
    });
  }

  Widget _buildProductList() {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          itemCount: _dummyStockData.length,
          itemBuilder: (BuildContext context, int index) {
            final product = _dummyStockData[index];
            return GestureDetector(
              child: headerCard2(product),
              onTap: () => _onProductTap(product, index),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onProductTap(Map<String, dynamic> product, int index) async {
    try {
      await _showProductBottomSheet(product);
    } catch (e) {
      Logger().e('Error in product tap: $e');
      EasyLoading.showError('Error loading product details');
    }
  }

  Future<void> _showProductBottomSheet(Map<String, dynamic> product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => modalBottomSheet(product, _dummyStockData),
    );

    // Panggil setState setelah modal ditutup
    // Ini akan me-render ulang headerCard2 dan _buildFloatingActionButtons
    setState(() {});
  }
}
