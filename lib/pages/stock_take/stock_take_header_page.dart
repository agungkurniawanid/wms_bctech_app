import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart';
import 'package:wms_bctech/models/stock/stock_take_detail_model.dart';
import 'package:wms_bctech/pages/stock_take/stock_take_detail_page.dart';
import 'package:shimmer/shimmer.dart'; // Pastikan package shimmer sudah ditambahkan

class StockTakeHeader extends StatefulWidget {
  final StockTakeModel? stocktake;
  const StockTakeHeader({this.stocktake, super.key});

  @override
  State<StockTakeHeader> createState() => _StockTakeHeaderState();
}

class _StockTakeHeaderState extends State<StockTakeHeader>
    with SingleTickerProviderStateMixin {
  final Color hijauGojekLight = const Color(0xFF4CAF50);
  final Color hijauGojekDark = const Color(0xFF008A0E);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _statusChoices = [
    {
      'id': 1,
      'label': 'N',
      'labelName': 'In Progress',
      'icon': Icons.pending_actions_rounded,
    },
    {
      'id': 2,
      'label': 'Y',
      'labelName': 'Completed',
      'icon': Icons.check_circle_rounded,
    },
  ];

  final List<Map<String, dynamic>> _dummyDocuments = [
    {
      'documentno': 'DOC001',
      'createdby': 'User A',
      'created': '2024-01-15 10:30:00',
      'isapprove': 'N',
      'lGORT': ['WH-A01'],
      'totalItems': 125,
    },
    {
      'documentno': 'DOC002',
      'createdby': 'User B',
      'created': '2024-01-14 14:20:00',
      'isapprove': 'Y',
      'lGORT': ['WH-B02'],
      'totalItems': 89,
    },
    {
      'documentno': 'DOC003',
      'createdby': 'User C',
      'created': '2024-01-13 09:15:00',
      'isapprove': 'N',
      'lGORT': ['WH-C03'],
      'totalItems': 234,
    },
    {
      'documentno': 'DOC004',
      'createdby': 'User A',
      'created': '2024-01-12 16:45:00',
      'isapprove': 'Y',
      'lGORT': ['WH-D04'],
      'totalItems': 156,
    },
  ];

  final List<Map<String, dynamic>> _filteredDocuments = [];
  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Product selection variables
  final Set<String> _selectedProductIds = {}; // Store selected product IDs
  final TextEditingController _productSearchController =
      TextEditingController();

  bool allowBack = true;
  bool _isSearching = false;
  int _selectedStatusId = 1;
  String searchQuery = '';
  String _choiceForChip = 'N';

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
    _initializeData();
    _animationController.forward();
  }

  void _initializeData() {
    _filteredDocuments.addAll(_dummyDocuments);
    _filterDocuments();
  }

  void _filterDocuments() {
    setState(() {
      _filteredDocuments.clear();
      _filteredDocuments.addAll(
        _dummyDocuments
            .where((doc) => doc['isapprove'] == _choiceForChip)
            .toList(),
      );
    });
  }

  void _startSearch() {
    setState(() {
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
      _searchController.clear();
      _filterDocuments();
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _searchDocuments(newQuery);
    });
  }

  void _searchDocuments(String search) {
    if (search.isEmpty) {
      _filterDocuments();
    } else {
      final query = search.toUpperCase();
      setState(() {
        _filteredDocuments.clear();
        _filteredDocuments.addAll(
          _dummyDocuments
              .where(
                (doc) =>
                    doc['documentno'].contains(query) &&
                    doc['isapprove'] == _choiceForChip,
              )
              .toList(),
        );
      });
    }
  }

  void _showProductSelectionBottomSheet() {
    // Reset search controller ketika bottom sheet dibuka
    _productSearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductSelectionBottomSheet(
        stocktake: widget.stocktake,
        hijauGojek: hijauGojekLight,
        hijauGojekDark: hijauGojekDark,
        selectedProductIds: _selectedProductIds,
        onConfirm: _createNewDocumentWithProducts,
        productSearchController: _productSearchController,
      ),
    );
  }

  void _createNewDocumentWithProducts(
    List<Map<String, dynamic>> selectedProducts,
  ) async {
    try {
      EasyLoading.show(status: 'Membuat dokumen...');

      final newDocRef = FirebaseFirestore.instance.collection('stock').doc();
      final newDocId = newDocRef.id;

      final newDocument = {
        'documentid': newDocId,
        'createdby': 'Demo User',
        'created': DateTime.now().toString(),
        'isapprove': 'N',
        'lGORT': widget.stocktake?.lGort ?? ['WH-NEW'],
        'detail': selectedProducts,
        'totalItems': selectedProducts.length,
        'documentno': 'DOC${DateTime.now().millisecondsSinceEpoch}',
        'whName': widget.stocktake?.whName ?? 'New Warehouse',
      };

      await newDocRef.set(newDocument);

      EasyLoading.dismiss();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StockTakeDetail(
            stocktake: StockTakeModel(
              documentid: newDocId,
              createdBy: 'Demo User',
              created: DateTime.now().toString(),
              isApprove: 'N',
              lGort: widget.stocktake?.lGort ?? ['WH-NEW'],
              detail: selectedProducts
                  .map((p) => StockTakeDetailModel.fromJson(p))
                  .toList(),
              updated: '',
              updatedby: '',
              doctype: 'stocktake',
              lastQuery: '',
              countDetail: selectedProducts.length,
              whName: widget.stocktake?.whName ?? 'New Warehouse',
              whValue: '',
              locatorValue: '',
            ),
          ),
        ),
      );

      EasyLoading.showSuccess('Dokumen berhasil dibuat!');
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Gagal membuat dokumen: $e');
    }
  }

  Widget _buildSearchField() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Cari nomor dokumen...',
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
        onChanged: _updateSearchQuery,
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear_rounded, size: 24, color: Colors.white),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              _stopSearching();
            } else {
              _clearSearchQuery();
            }
          },
          tooltip: 'Clear',
        ),
        const SizedBox(width: 4),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.search_rounded, size: 24, color: Colors.white),
        onPressed: _startSearch,
        tooltip: 'Search',
      ),
      const SizedBox(width: 4),
    ];
  }

  Widget _buildStatusChoiceChips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: _statusChoices.map((choice) {
          final isSelected = _selectedStatusId == choice['id'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onStatusSelected(choice),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [hijauGojekLight, hijauGojekDark],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? hijauGojekLight
                              : Colors.grey.shade300,
                          width: isSelected ? 0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: hijauGojekLight.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            choice['icon'],
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            choice['labelName'] ?? '',
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onStatusSelected(Map<String, dynamic> choice) {
    setState(() {
      _selectedStatusId = choice['id'] ?? 0;
      _choiceForChip = choice['label'] ?? 'N';
      _filterDocuments();
    });
  }

  Widget _buildDocumentCard(Map<String, dynamic> document, int index) {
    final isCompleted = document['isapprove'] == 'Y';

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
            color: hijauGojekLight.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToDetail(document, index),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [hijauGojekLight, hijauGojekDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: hijauGojekLight.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.description_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            document['documentno'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCompleted
                              ? Colors.blue.shade200
                              : Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.pending_actions_rounded,
                            size: 16,
                            color: isCompleted
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCompleted ? 'Completed' : 'In Progress',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCompleted
                                  ? Colors.blue.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade100,
                        Colors.grey.shade200,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.person_rounded,
                            'Created By',
                            document['createdby'],
                            hijauGojekLight,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time_rounded,
                            'Created At',
                            document['created'],
                            Colors.blue.shade600,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey.shade200,
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hijauGojekLight.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: hijauGojekDark,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${document['totalItems']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: hijauGojekDark,
                          ),
                        ),
                        Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: hijauGojekLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 13,
                          color: hijauGojekDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: hijauGojekLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentList() {
    if (_filteredDocuments.isEmpty) {
      return Expanded(child: _buildEmptyState());
    }

    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: _filteredDocuments.length,
          itemBuilder: (BuildContext context, int index) {
            final document = _filteredDocuments[index];
            return _buildDocumentCard(document, index);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  hijauGojekLight.withValues(alpha: 0.1),
                  hijauGojekLight.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Documents Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new document to get started',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> document, int index) {
    final stockTakeModel = StockTakeModel(
      documentid: document['documentno'],
      createdBy: document['createdby'],
      created: document['created'],
      isApprove: document['isapprove'],
      lGort: document['lGORT'],
      detail: [],
      updated: '',
      updatedby: '',
      doctype: '',
      lastQuery: '',
      countDetail: 0,
      whName: '',
      whValue: '',
      locatorValue: '',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockTakeDetail(
          stocktake: stockTakeModel,
          index: index,
          documentno: document['documentno'],
        ),
      ),
    );
  }

  void _handleBackPress() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: _handleBackPress,
              color: Colors.white,
            ),
          ),
          actions: _buildAppBarActions(),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [hijauGojekLight, hijauGojekDark],
              ),
            ),
          ),
          title: _isSearching
              ? _buildSearchField()
              : Text(
                  (widget.stocktake?.lGort.isNotEmpty ?? false)
                      ? widget.stocktake!.lGort.join(', ')
                      : "PID ${widget.stocktake?.whName}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
          centerTitle: true,
        ),
        body: Column(
          children: [_buildStatusChoiceChips(), _buildDocumentList()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showProductSelectionBottomSheet,
          backgroundColor: hijauGojekLight,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'New Document',
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
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _searchController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }
}

// Bottom Sheet Widget yang terpisah dengan pagination dan live search
class _ProductSelectionBottomSheet extends StatefulWidget {
  final StockTakeModel? stocktake;
  final Color hijauGojek;
  final Color hijauGojekDark;
  final Set<String> selectedProductIds;
  final Function(List<Map<String, dynamic>>) onConfirm;
  final TextEditingController productSearchController;

  const _ProductSelectionBottomSheet({
    required this.stocktake,
    required this.hijauGojek,
    required this.hijauGojekDark,
    required this.selectedProductIds,
    required this.onConfirm,
    required this.productSearchController,
  });

  @override
  State<_ProductSelectionBottomSheet> createState() =>
      _ProductSelectionBottomSheetState();
}

class _ProductSelectionBottomSheetState
    extends State<_ProductSelectionBottomSheet> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _allProducts = [];
  final List<Map<String, dynamic>> _displayedProducts = [];
  final Map<String, Map<String, dynamic>> _selectedProductsMap = {};

  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isSearching = false;
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();

    // Setup live search
    widget.productSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = widget.productSearchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
        _performSearch(query);
      });
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      // Kembalikan ke data awal
      setState(() {
        _isSearching = false;
        _displayedProducts.clear();
        _currentPage = 0;
        _hasMoreData = true;
      });
      _loadMoreData();
    } else {
      // Lakukan pencarian
      setState(() {
        _isSearching = true;
        _displayedProducts.clear();

        final searchLower = query.toLowerCase();
        final filteredProducts = _allProducts.where((product) {
          final matnr = (product['matnr'] ?? '').toString().toLowerCase();
          final maktx = (product['maktx'] ?? '').toString().toLowerCase();
          return matnr.contains(searchLower) || maktx.contains(searchLower);
        }).toList();

        _displayedProducts.addAll(filteredProducts);
        _hasMoreData = false; // Tidak perlu pagination saat search
      });
    }
  }

  void _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch semua data dari Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('stock')
          .where('_documentid', isEqualTo: widget.stocktake?.documentid ?? '')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final productDoc = snapshot.docs.first;
        final productData = productDoc.data();
        final details = productData['detail'] as List<dynamic>? ?? [];

        setState(() {
          _allProducts.clear();
          _allProducts.addAll(
            details.map((e) => e as Map<String, dynamic>).toList(),
          );
        });
      }

      // --- PERBAIKAN DI SINI ---
      // Set loading ke false SETELAH data di-fetch
      // dan SEBELUM memanggil _loadMoreData
      setState(() {
        _isLoading = false;
      });
      // --- END PERBAIKAN ---

      // Load first page
      _loadMoreData(); // Sekarang fungsi ini akan berjalan
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      EasyLoading.showError('Gagal memuat data: $e');
    }
  }

  void _loadMoreData() {
    if (_isLoading || !_hasMoreData || _isSearching) return;

    setState(() {
      _isLoading = true;
    });

    // Simulasi delay untuk loading
    Future.delayed(const Duration(milliseconds: 500), () {
      final startIndex = _currentPage * _pageSize;
      final endIndex = startIndex + _pageSize;

      if (startIndex >= _allProducts.length) {
        setState(() {
          _hasMoreData = false;
          _isLoading = false;
        });
        return;
      }

      final newProducts = _allProducts.sublist(
        startIndex,
        endIndex > _allProducts.length ? _allProducts.length : endIndex,
      );

      setState(() {
        _displayedProducts.addAll(newProducts);
        _currentPage++;
        _isLoading = false;
        _hasMoreData = endIndex < _allProducts.length;
      });
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _toggleProductSelection(Map<String, dynamic> product) {
    final matnr = product['matnr']?.toString() ?? 'NO_MATNR';
    final serno = product['serno']?.toString() ?? 'NO_SERNO';
    final String productKey = '$matnr|$serno';

    setState(() {
      // Menggunakan productKey (berisi matnr|serno)
      if (_selectedProductsMap.containsKey(productKey)) {
        _selectedProductsMap.remove(productKey);
        widget.selectedProductIds.remove(productKey);
      } else {
        _selectedProductsMap[productKey] =
            product; // Tetap simpan seluruh objek
        widget.selectedProductIds.add(productKey);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedProductsMap.isEmpty) {
      EasyLoading.showError('Pilih minimal satu produk');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Buat Dokumen PID?',
          style: TextStyle(
            color: widget.hijauGojekDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin membuat dokumen PID dengan:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.hijauGojek.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.hijauGojek.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: widget.hijauGojek,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedProductsMap.length} produk terpilih',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.hijauGojekDark,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ..._selectedProductsMap.values
                .take(3)
                .map(
                  (product) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.hijauGojek,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            product['maktx'] ?? 'No Name',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (_selectedProductsMap.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... dan ${_selectedProductsMap.length - 3} produk lainnya',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              widget.onConfirm(_selectedProductsMap.values.toList());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.hijauGojek,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Ya, Buat Dokumen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.hijauGojek.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.inventory_2_rounded,
                                color: widget.hijauGojekDark,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Pilih Produk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_selectedProductsMap.length} produk dipilih',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade700,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: widget.productSearchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau SKU produk...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: widget.hijauGojek,
                      size: 22,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                            onPressed: () {
                              widget.productSearchController.clear();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              // Product List
              Expanded(
                child: _displayedProducts.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount:
                            _displayedProducts.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _displayedProducts.length) {
                            return _buildLoadingShimmer();
                          }

                          final product = _displayedProducts[index];
                          final matnr =
                              product['matnr']?.toString() ?? 'NO_MATNR';
                          final serno =
                              product['serno']?.toString() ?? 'NO_SERNO';

                          // Gunakan kombinasi matnr|serno agar selalu unik
                          final String productKey = '$matnr|$serno';

                          final isSelected = _selectedProductsMap.containsKey(
                            productKey,
                          );

                          return _buildProductItem(product, isSelected);
                        },
                      ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.hijauGojek,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Buat Dokumen (${_selectedProductsMap.length})',
                                style: const TextStyle(
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? widget.hijauGojek.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? widget.hijauGojek : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? widget.hijauGojek.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _toggleProductSelection(product),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? widget.hijauGojek : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? widget.hijauGojek
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['maktx'] ?? 'No Name',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? widget.hijauGojekDark
                              : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'SKU: ${product['matnr'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: hijauGojek.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'SERNO: ${product['serno'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: hijauGojek,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Stock Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? widget.hijauGojek.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_rounded,
                        size: 16,
                        color: isSelected
                            ? widget.hijauGojekDark
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product['labst'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected
                              ? widget.hijauGojekDark
                              : Colors.grey.shade700,
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
    );
  }

  Widget _buildLoadingShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isNotEmpty
                ? 'Tidak ada produk ditemukan'
                : 'Tidak ada produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Coba kata kunci lain'
                : 'Belum ada produk tersedia',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    widget.productSearchController.removeListener(_onSearchChanged);
    super.dispose();
  }
}
