import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

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
  int typeIndexbox = 0;
  double typeIndexbun = 0;
  ValueNotifier<double> totalinput = ValueNotifier(0.0);
  ValueNotifier<double> bun = ValueNotifier(0.0);
  ValueNotifier<int> box = ValueNotifier(0);
  ValueNotifier<double> localpcsvalue = ValueNotifier(0.0);
  ValueNotifier<int> localctnvalue = ValueNotifier(0);
  ValueNotifier<double> stockbun = ValueNotifier(0.0);
  ValueNotifier<String> totalbox = ValueNotifier("");
  ValueNotifier<String> totalbun = ValueNotifier("");
  ValueNotifier<double> stockbox = ValueNotifier(0.0);
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
  final List<Map<String, dynamic>> _dummyStockData = [
    {
      'matnr': 'MAT001',
      'nORMT': 'BOX001',
      'mAKTX': 'Product A',
      'labst': 100.0,
      'insme': 50.0,
      'speme': 25.0,
      'selectedChoice': 'UU',
      'lgort': 'WH-A01',
      'werks': 'PLANT01',
      'marm': [
        {'meinh': 'KG', 'umrez': '10.0', 'umren': '1.0'},
        {'meinh': 'BOX', 'umrez': '1.0', 'umren': '1.0'},
      ],
      'checkboxValidation': ValueNotifier<bool>(false),
      'isApprove': 'N',
    },
    {
      'matnr': 'MAT002',
      'nORMT': 'BOX002',
      'mAKTX': 'Product B',
      'labst': 200.0,
      'insme': 75.0,
      'speme': 30.0,
      'selectedChoice': 'QI',
      'lgort': 'WH-B02',
      'werks': 'PLANT01',
      'marm': [
        {'meinh': 'KG', 'umrez': '5.0', 'umren': '1.0'},
        {'meinh': 'BOX', 'umrez': '1.0', 'umren': '1.0'},
      ],
      'checkboxValidation': ValueNotifier<bool>(false),
      'isApprove': 'N',
    },
    {
      'matnr': 'MAT003',
      'nORMT': 'BOX003',
      'mAKTX': 'Product C',
      'labst': 150.0,
      'insme': 60.0,
      'speme': 20.0,
      'selectedChoice': 'BLOCK',
      'lgort': 'WH-C03',
      'werks': 'PLANT02',
      'marm': [
        {'meinh': 'KG', 'umrez': '8.0', 'umren': '1.0'},
        {'meinh': 'BOX', 'umrez': '1.0', 'umren': '1.0'},
      ],
      'checkboxValidation': ValueNotifier<bool>(false),
      'isApprove': 'N',
    },
  ];

  final List<Map<String, dynamic>> _dummyInputData = [];

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
    return "50.0";
  }

  String conversion(
    Map<String, dynamic> models,
    String name,
    String validation,
  ) {
    try {
      if (name == "KG") {
        return "25.0";
      } else {
        return "10.0";
      }
    } catch (e) {
      Logger().e(e);
      return "0.0";
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
                              inmodel['mAKTX'],
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
                            value: inmodel['nORMT'],
                            color: Colors.blue,
                          ),
                          _buildInfoChip(
                            icon: Icons.tag_rounded,
                            label: 'SKU',
                            value: inmodel['matnr'],
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Checkbox
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: inmodel['checkboxValidation'],
                    builder: (context, value, _) {
                      return Checkbox(
                        value: value,
                        onChanged: (bool? newValue) {
                          inmodel['checkboxValidation'].value =
                              newValue ?? false;
                        },
                        activeColor: hijauGojek,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    },
                  ),
                ),
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
                    values: [calculTotalbun(inmodel, "Bun"), "5.0", "2.5"],
                    isEven: false,
                  ),

                  // Different Row
                  _buildDataRow(
                    label: 'Different',
                    labelColor: Colors.red.shade700,
                    values: ["-50.0", "-5.0", "-2.5"],
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
                value,
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
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        '${indetail['nORMT'].trim()} - ${indetail['mAKTX']}',
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
                  icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),

          // Product Image
          Container(
            margin: const EdgeInsets.all(20),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No Image Available',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
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
                      EasyLoading.show(
                        status: 'Saving...',
                        maskType: EasyLoadingMaskType.black,
                      );

                      _dummyInputData.add({
                        'matnr': indetail['matnr'],
                        'section': selectedSection.value,
                        'countBox': box.value,
                        'countBun': bun.value,
                        'selectedChoice': indetail['selectedChoice'],
                        'created': DateFormat(
                          'yyyy-MM-dd kk:mm:ss',
                        ).format(DateTime.now()),
                        'isTick': indetail['checkboxValidation'].value,
                      });

                      await Future.delayed(const Duration(seconds: 1));

                      EasyLoading.dismiss();
                      if (mounted) {
                        Navigator.of(context).pop();
                        EasyLoading.showSuccess('Data saved successfully!');
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
          ),
        ],
      ),
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
      _showProductBottomSheet(product);
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
                      onPressed: () async {
                        EasyLoading.show(status: 'Saving...');

                        await Future.delayed(const Duration(seconds: 2));
                        if (!mounted) return;
                        EasyLoading.showSuccess('Data saved successfully!');
                        Get.back();
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
        body: Column(children: [_buildHeaderSection(), _buildProductList()]),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    if (!_isApproveVisible()) {
      return const SizedBox.shrink();
    }

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

        FloatingActionButton(
          onPressed: _scanBarcodeDummy, // Menggunakan fungsi scan untuk "plus"
          backgroundColor: hijauGojek, // Warna hijau untuk aksi tambah
          heroTag: "addBtn", // Hero tag unik
          elevation: 4,
          child: const Icon(
            Icons.add_rounded, // Ikon "Plus"
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        // Approve Button
        FloatingActionButton.extended(
          onPressed: _onApprovePressed,
          backgroundColor: hijauGojek,
          foregroundColor: Colors.white,
          heroTag: "approveBtn",
          elevation: 4,
          icon: const Icon(Icons.check_circle_rounded, size: 24),
          label: const Text(
            'Approve',
            style: TextStyle(
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
  //   return hijauGojek;
  // }

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
        // Stats Bar
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
                    Text(
                      'Demo User',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Category Chips
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
    final approvedCount = _dummyStockData
        .where((element) => element['isApprove'] == "Y")
        .length;
    return '$approvedCount of ${_dummyStockData.length}';
  }

  // TextStyle _getChipTextStyle() {
  //   return const TextStyle(color: Colors.white);
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
      await _prepareProductDetail(product, index);
      await _showProductBottomSheet(product);
    } catch (e) {
      Logger().e('Error in product tap: $e');
      EasyLoading.showError('Error loading product details');
    }
  }

  Future<void> _prepareProductDetail(
    Map<String, dynamic> product,
    int index,
  ) async {
    sortListBatch.value.clear();
    _calculateStockBun(product);
    await _initializeCountValues(product, index);
    _calculateTotalValues(product);
  }

  void _calculateStockBun(Map<String, dynamic> productDetail) {
    stockbun.value = switch (productDetail['selectedChoice']) {
      "BLOCK" => productDetail['speme'],
      "QI" => productDetail['insme'],
      _ => productDetail['labst'],
    };
  }

  Future<void> _initializeCountValues(
    Map<String, dynamic> product,
    int index,
  ) async {
    if (_dummyInputData.isEmpty) {
      bun.value = 0;
      box.value = 0;
      selectedSection.value = sortListSection.value.firstWhere(
        (element) => element.contains("A1-1"),
      );
    } else {
      await _calculateExistingCounts(product, index);
    }
  }

  Future<void> _calculateExistingCounts(
    Map<String, dynamic> product,
    int index,
  ) async {
    final calculations = _dummyInputData
        .where(
          (element) =>
              element['selectedChoice'] == product['selectedChoice'] &&
              element['section'] == "A1-1" &&
              element['matnr'] == product['matnr'],
        )
        .toList();

    if (calculations.isEmpty) {
      bun.value = 0;
      box.value = 0;
      selectedSection.value = sortListSection.value.firstWhere(
        (element) => element.contains("A1-1"),
      );
    } else {
      _updateCountValues(calculations);
    }
  }

  void _updateCountValues(List<Map<String, dynamic>> calculations) {
    if (calculations.length > 1) {
      localpcs = 0;
      localctn = 0;
      for (final input in calculations) {
        localpcs += input['countBun'];
        localctn += (input['countBox'] as num).toInt();
      }
      bun.value = localpcs;
      box.value = localctn;
    } else {
      bun.value = calculations.first['countBun'];
      box.value = (calculations.first['countBox'] as num).toInt();
    }
  }

  void _calculateTotalValues(Map<String, dynamic> product) {
    totalbox.value = calcultotalbox(product);
    totalbun.value = calculTotalpcs(product);
    localpcsvalue.value = bun.value;
    localctnvalue.value = box.value;
  }

  Future<void> _showProductBottomSheet(Map<String, dynamic> product) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => modalBottomSheet(product, _dummyStockData),
    );
  }
}

// Dummy model classes
class StockTakeDetailModel {
  final Map<String, dynamic> data;

  StockTakeDetailModel(this.data);

  factory StockTakeDetailModel.fromJson(Map<String, dynamic> json) {
    return StockTakeDetailModel(json);
  }

  String get matnr => data['matnr'] ?? '';
  String get nORMT => data['nORMT'] ?? '';
  String get mAKTX => data['mAKTX'] ?? '';
  double get labst => data['labst'] ?? 0.0;
  double get insme => data['insme'] ?? 0.0;
  double get speme => data['speme'] ?? 0.0;
  String get selectedChoice => data['selectedChoice'] ?? 'UU';
  String get lgort => data['lgort'] ?? '';
  String get werks => data['werks'] ?? '';
  List<dynamic> get marm => data['marm'] ?? [];
  ValueNotifier<bool> get checkboxValidation => data['checkboxValidation'];
  String get isApprove => data['isApprove'] ?? 'N';
}

TextStyle safeGoogleFont(
  String fontFamily, {
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.normal,
  double height = 1.0,
  Color color = Colors.black,
}) {
  return TextStyle(
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    color: color,
  );
}
