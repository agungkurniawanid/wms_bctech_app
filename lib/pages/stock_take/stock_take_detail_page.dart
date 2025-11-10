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

// MODIFIKASI: Tambahkan impor yang diperlukan
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wms_bctech/models/pid_document/pid_document_model.dart';

class StockTakeDetail extends StatefulWidget {
  final StockTakeModel? stocktake;
  final int? index;
  final String? documentno;

  const StockTakeDetail({
    this.stocktake,
    this.index,
    this.documentno,
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

  // --- PERBAIKAN: Hapus semua ValueNotifier yang tidak perlu ---
  // ValueNotifier<double> bun = ValueNotifier(0.0); // DIHAPUS
  // ValueNotifier<int> box = ValueNotifier(0); // DIHAPUS
  // ValueNotifier<double> localpcsvalue = ValueNotifier(0.0); // DIHAPUS
  // ValueNotifier<int> localctnvalue = ValueNotifier(0); // DIHAPUS
  // ValueNotifier<double> stockbun = ValueNotifier(0.0); // DIHAPUS
  // ValueNotifier<String> totalbox = ValueNotifier(""); // DIHAPUS
  // ValueNotifier<String> totalbun = ValueNotifier(""); // DIHAPUS
  // ValueNotifier<double> stockbox = ValueNotifier(0.0); // DIHAPUS
  // -----------------------------------------------------------

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

  // Data dummy untuk menggantikan data dari Firestore
  final List<Map<String, dynamic>> _dummyStockData = [];
  // final List<Map<String, dynamic>> _dummyInputData = []; // MODIFIKASI: Tidak digunakan lagi, diganti _cachedPidDetails

  // 1. Dapatkan instance controller-nya
  final NewAuthController authController = Get.find<NewAuthController>();
  final GlobalVM globalVM = Get.find<GlobalVM>();

  // MODIFIKASI: Tambahkan variabel untuk cache data dan koneksi Firestore
  final List<PidDocumentDetailModel> _cachedPidDetails = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _dummyStockData.clear(); // Bersihkan daftar
    if (widget.stocktake?.detail != null &&
        widget.stocktake!.detail.isNotEmpty) {
      // Loop data dari header
      for (var productModel in widget.stocktake!.detail) {
        // Ubah model ke Map
        var productMap = productModel.toMap();

        // Tambahkan field UI yang dibutuhkan oleh headerCard2
        productMap['checkboxValidation'] = ValueNotifier<bool>(false);
        productMap['selectedChoice'] = 'UU'; // Atur default 'UU'

        // Tambahkan ke daftar
        _dummyStockData.add(productMap);
      }
    }
    _searchQuery = TextEditingController();
    sortListSection.value = ['A1-1', 'A1-2', 'B1-1', 'B1-2', 'C1-1'];
    selectedSection.value = 'A1-1';

    _initializeChoiceChips();
    _animationController.forward();
  }

  void _initializeChoiceChips() {
    listchoice = [
      ItemChoice(id: 1, label: 'FZ', labelName: 'Frozen'),
      ItemChoice(id: 2, label: 'CH', labelName: 'Chilled'),
      ItemChoice(id: 3, label: 'ALL', labelName: 'All Products'),
    ];
    namechoice = listchoice[0].label!;
  }

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

  String calculTotalbun(Map<String, dynamic> item, String validation) {
    return "0.0";
  }

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
            color: hijauGojek.withOpacity(0.1), // MODIFIKASI: withOpacity
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: hijauGojek.withOpacity(0.3), // MODIFIKASI: withOpacity
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
                  hijauGojek.withOpacity(0.3), // MODIFIKASI: withOpacity
                  hijauGojekLight.withOpacity(0.07), // MODIFIKASI: withOpacity
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
                          // KODE PERBAIKAN
                          Expanded(
                            child: Text(
                              // 1. Ubah ke 'maktx' (huruf kecil)
                              // 2. Beri nilai default jika null
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

                // Checkbox
                // Container(
                //  ... (Kode Checkbox Anda yang dikomentari)
                // ),
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
                                            .withOpacity(0.3), // MODIFIKASI
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
                    values: ["0.0", "-", "-"],
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
        color: color.withOpacity(0.1), // MODIFIKASI
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ), // MODIFIKASI
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
                (value.isEmpty || value == "null") // MODIFIKASI: Perbaikan
                    ? "-"
                    : value,
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

  Widget modalBottomSheet(
    Map<String, dynamic> indetail,
    List<Map<String, dynamic>> inDetailList,
  ) {
    // Data untuk dropdown (hanya nilai default saja karena read only)
    final List<String> sectionList = ['A'];
    final List<String> palletList = ['1'];
    final List<String> cellList = ['1'];

    // ---
    // Logika Kunci: Cek data yang sudah ada di cache
    // ---
    PidDocumentDetailModel? existingDetail;
    try {
      existingDetail = _cachedPidDetails.firstWhere(
        (d) => d.productId == indetail['matnr']?.toString(),
      );
    } catch (e) {
      existingDetail = null; // Tidak ditemukan
    }

    // State untuk form
    String selectedSection = sectionList.first;
    String selectedPallet = palletList.first;
    String selectedCell = cellList.first;

    // Inisialisasi controller dengan data cache jika ada, jika tidak, '0'
    TextEditingController bunController = TextEditingController(
      text: existingDetail?.physicalQty.toString() ?? '0',
    );
    TextEditingController boxController = TextEditingController(text: '0');

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
                      hijauGojek.withOpacity(0.1), // MODIFIKASI
                      hijauGojekLight.withOpacity(0.05), // MODIFIKASI
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [hijauGojek, hijauGojekDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
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
                            'Edit Product',
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
                              color: hijauGojekDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      // Material/SKU/Product ID
                      _buildReadOnlyField(
                        label: 'Material/SKU/Product ID',
                        value: indetail['matnr']?.toString() ?? 'N/A',
                        icon: Icons.qr_code_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Compatible
                      _buildReadOnlyField(
                        label: 'Compatible',
                        value: '0',
                        icon: Icons.settings_suggest_rounded,
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
                      _buildReadOnlyField(
                        label: 'Stock Bun',
                        value: indetail['labst']?.toString() ?? '0.0',
                        icon: Icons.inventory_2_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Stock Box
                      _buildReadOnlyField(
                        label: 'Stock Box',
                        value: '0.0',
                        icon: Icons.inventory_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Section Dropdown (Read Only)
                      _buildReadOnlyDropdown(
                        label: 'Section',
                        value: selectedSection,
                        items: sectionList,
                        icon: Icons.location_on_rounded,
                        onChanged:
                            (
                              value,
                            ) {}, // Tidak melakukan apa-apa karena read only
                      ),
                      const SizedBox(height: 16),

                      // Total Physical Bun
                      _buildReadOnlyField(
                        label: 'Total Physical Bun',
                        value: '0.0',
                        icon: Icons.inventory_2_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Total Physical Box
                      _buildReadOnlyField(
                        label: 'Total Physical Box',
                        value: '0.0',
                        icon: Icons.pallet,
                      ),
                      const SizedBox(height: 16),

                      // Bun Input Field (Bisa diinput)
                      _buildInputField(
                        label: 'Bun',
                        controller: bunController,
                        icon: Icons.add_circle_outline_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      // Box Field (Read Only)
                      _buildReadOnlyField(
                        label: 'Box',
                        value: '0',
                        icon: Icons.all_inbox_rounded,
                      ),
                      const SizedBox(height: 16),

                      // Pallet Dropdown (Read Only)
                      _buildReadOnlyDropdown(
                        label: 'Pallet',
                        value: selectedPallet,
                        items: palletList,
                        icon: Icons.inventory_2_rounded,
                        onChanged:
                            (
                              value,
                            ) {}, // Tidak melakukan apa-apa karena read only
                      ),
                      const SizedBox(height: 16),

                      // Cell Dropdown (Read Only)
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
                      const SizedBox(height: 16),

                      // Product SN
                      _buildReadOnlyField(
                        label: 'Product SN',
                        value: indetail['matnr']?.toString() ?? 'N/A',
                        icon: Icons.numbers_rounded,
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          // Validasi input bun
                          if (bunController.text.isEmpty) {
                            EasyLoading.showError('Field Bun harus diisi');
                            return;
                          }

                          final bunValue = double.tryParse(bunController.text);
                          if (bunValue == null) {
                            EasyLoading.showError(
                              'Field Bun harus berupa angka',
                            );
                            return;
                          }

                          // MODIFIKASI: Ganti logika save
                          EasyLoading.show(
                            status: 'Caching...',
                            maskType: EasyLoadingMaskType.black,
                          );

                          // Buat model detail
                          final newDetail = PidDocumentDetailModel(
                            productId: indetail['matnr']?.toString() ?? 'N/A',
                            productSN:
                                indetail['serno']?.toString() ??
                                'N/A', // Sesuai permintaan
                            physicalQty: bunValue
                                .toInt(), // Hanya ambil BUN qty
                          );

                          // Cek apakah sudah ada di cache, jika ada, replace
                          final existingIndex = _cachedPidDetails.indexWhere(
                            (d) => d.productId == newDetail.productId,
                          );

                          // Perbarui list di main state, bukan di modal state
                          // Kita tidak perlu setState di dalam modal,
                          // karena datanya akan di-refresh oleh setState
                          // di _showProductBottomSheet setelah modal ditutup
                          if (existingIndex != -1) {
                            _cachedPidDetails[existingIndex] =
                                newDetail; // Replace
                          } else {
                            _cachedPidDetails.add(newDetail); // Add new
                          }

                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );

                          EasyLoading.dismiss();
                          if (mounted) {
                            Navigator.of(context).pop();
                            EasyLoading.showSuccess('Data cached locally!');
                          }
                          // MODIFIKASI: Selesai
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
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk field read only
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

  // Widget untuk dropdown read only
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

  // Widget untuk field input (hanya untuk field Bun)
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required TextInputType keyboardType,
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
              color: hijauGojek.withOpacity(0.5), // MODIFIKASI
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
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
        color: Colors.white.withOpacity(0.2), // MODIFIKASI
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchQuery,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7), // MODIFIKASI
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
      // PERBAIKAN: Panggil _onProductTap agar logikanya konsisten
      // dan meneruskan index
      _onProductTap(product, 0);
    }
  }

  // MODIFIKASI: Logika untuk generate ID baru
  Future<String> _generatePidId(String orgValue) async {
    // Format: PID<orgValue><yy>
    final currentYearYY = DateTime.now().year.toString().substring(2); // '25'
    final docPrefix = 'PID$orgValue$currentYearYY'; // 'PID276625'

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
          // Ambil 4 digit terakhir sebagai sequence
          final sequenceMatch = RegExp(r'(\d{4})$').firstMatch(lastPidId);

          if (sequenceMatch != null) {
            final lastSequence = int.tryParse(sequenceMatch.group(1)!) ?? 0;
            nextSequence = lastSequence + 1;
          }
        }

        // Format sequence '0001'
        final sequenceString = nextSequence.toString().padLeft(4, '0');
        final newPidId = '$docPrefix$sequenceString'; // 'PID2766250001'

        // Cek keamanan transaksi
        final existingDocSnapshot = await transaction.get(
          _firestore.collection('pid_document').doc(newPidId),
        );

        if (existingDocSnapshot.exists) {
          // Jika terjadi tabrakan (sangat jarang)
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

  // MODIFIKASI: Logika untuk menyimpan dokumen PID ke Firestore
  Future<void> _generateAndSavePidDocument() async {
    try {
      final orgValue = widget.stocktake?.orgValue ?? 'NA';
      // 1. Generate ID
      final String newPidId = await _generatePidId(orgValue);

      // 2. Siapkan data header
      final String? createdBy = globalVM.username.value.isEmpty
          ? "Demo User"
          : globalVM.username.value;
      final String? whName = widget.stocktake?.whName;
      final String? whValue = widget.stocktake?.whValue;
      final String? orgName = widget.stocktake?.orgName;
      final String? locatorValue =
          widget.stocktake?.locatorValue; // Ambil locator jika ada

      // 3. Buat Model
      final PidDocumentModel pidDoc = PidDocumentModel(
        pidDocument: newPidId,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        status: 'completed', // Status setelah diapprove
        whValue: whValue,
        whName: whName,
        locatorValue: locatorValue,
        orgValue: orgValue,
        orgName: orgName,
        products: _cachedPidDetails, // Gunakan data dari cache
      );

      // 4. Simpan ke Firestore
      await _firestore
          .collection('pid_document')
          .doc(newPidId)
          .set(pidDoc.toFirestore());

      _logger.d('✅ PID Document $newPidId saved successfully.');
    } catch (e) {
      _logger.e('❌ Error saving PID Document: $e');
      // Lempar error agar bisa ditangkap oleh dialog
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
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Title
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

              // Description
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

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: hijauGojek.withOpacity(0.1), // MODIFIKASI
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hijauGojek.withOpacity(0.3), // MODIFIKASI
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

              // Action Buttons
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
                      // MODIFIKASI: Update logika OnPressed
                      onPressed: () async {
                        EasyLoading.show(status: 'Saving Document...');

                        try {
                          // Panggil fungsi generator dan save
                          await _generateAndSavePidDocument();

                          if (!mounted) return;
                          EasyLoading.showSuccess(
                            'Document saved successfully!',
                          );

                          // Tutup dialog
                          Navigator.of(context).pop();

                          // Kembali ke halaman sebelumnya setelah sukses
                          Get.back();
                        } catch (e) {
                          _logger.e('Error during approve process: $e');
                          EasyLoading.showError(
                            'Failed to save document: ${e.toString()}',
                          );
                          // Jangan tutup dialog jika error
                        }
                      },
                      // MODIFIKASI: Selesai
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
              color: Colors.white.withOpacity(0.2), // MODIFIKASI
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
        body: Column(children: [_buildHeaderSection(), _buildProductList()]),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    if (!_isApproveVisible()) {
      return const SizedBox.shrink();
    }

    // MODIFIKASI: Tambahkan logika disable tombol approve
    // Tombol disable jika jumlah item di cache tidak sama dengan total item
    bool isApproveDisabled = _cachedPidDetails.length != _dummyStockData.length;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Email Button
        FloatingActionButton(
          onPressed: _onEmailPressed,
          backgroundColor: Colors.blue.shade600,
          heroTag: "emailBtn",
          elevation: 4,
          child: const Icon(
            Icons.email_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 16),
        // Approve Button
        FloatingActionButton.extended(
          // MODIFIKASI: Terapkan logika disable
          onPressed: isApproveDisabled ? null : _onApprovePressed,
          backgroundColor: isApproveDisabled
              ? Colors.grey.shade400
              : hijauGojek,
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
            // Beri feedback ke user
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

  // Color _getApproveButtonColor() {
  //  return hijauGojek;
  // }

  void _onEmailPressed() {
    EasyLoading.showInfo('Email sent successfully!');
  }

  void _onApprovePressed() {
    // Logika ini sudah benar, panggil dialog konfirmasi
    // Logika save yang sebenarnya sudah dipindah ke tombol "Save" di dalam dialog
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
        // Stats Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                hijauGojek.withOpacity(0.1), // MODIFIKASI
                hijauGojekLight.withOpacity(0.05), // MODIFIKASI
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
                      color: hijauGojek.withOpacity(0.1), // MODIFIKASI
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
                                  color: hijauGojek.withOpacity(
                                    0.3,
                                  ), // MODIFIKASI
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
    // MODIFIKASI: Ubah untuk menghitung data yang di-cache
    final cachedCount = _cachedPidDetails.length;
    return '$cachedCount of ${_dummyStockData.length}';
  }

  // TextStyle _getChipTextStyle() {
  //  return const TextStyle(color: Colors.white);
  // }

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
    final isApproved = (widget.stocktake?.isApprove) == "Y";

    if (isApproved) return;

    try {
      // --- PERBAIKAN: Hapus pemanggilan ke fungsi yang tidak perlu ---
      // await _prepareProductDetail(product, index); // DIHAPUS
      // -------------------------------------------------------------
      await _showProductBottomSheet(product);
    } catch (e) {
      Logger().e('Error in product tap: $e');
      EasyLoading.showError('Error loading product details');
    }
  }

  // --- PERBAIKAN: Hapus semua fungsi state yang tidak perlu ---
  // Future<void> _prepareProductDetail(...) // DIHAPUS
  // void _calculateStockBun(...) // DIHAPUS
  // Future<void> _initializeCountValues(...) // DIHAPUS
  // Future<void> _calculateExistingCounts(...) // DIHAPUS
  // void _updateCountValues(...) // DIHAPUS
  // void _calculateTotalValues(...) // DIHAPUS
  // --------------------------------------------------------

  Future<void> _showProductBottomSheet(Map<String, dynamic> product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => modalBottomSheet(product, _dummyStockData),
    );
    // ---
    // Panggil setState di sini setelah modal ditutup
    // ---
    // Ini akan memaksa widget _buildFloatingActionButtons dan _getDataCountText
    // untuk membangun ulang dirinya sendiri dan mengecek ulang
    // `_cachedPidDetails.length`
    setState(() {});
  }
}
