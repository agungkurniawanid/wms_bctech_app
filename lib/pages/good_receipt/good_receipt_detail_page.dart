import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/helpers/date_helper.dart';
import 'package:wms_bctech/helpers/text_helper.dart';
import 'package:wms_bctech/models/good_receipt/good_receipt_detail_model.dart';
import 'package:wms_bctech/models/good_receipt/good_receipt_model.dart';
import 'package:logger/logger.dart';
import 'package:shimmer/shimmer.dart';

class GoodReceiptDetailPage extends StatefulWidget {
  final String grId;

  const GoodReceiptDetailPage({super.key, required this.grId});

  @override
  State<GoodReceiptDetailPage> createState() => _GoodReceiptDetailPageState();
}

class _GoodReceiptDetailPageState extends State<GoodReceiptDetailPage> {
  final Color _primaryColor = hijauGojek;
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF2D2D2D);
  final Color _textSecondaryColor = const Color(0xFF6B7280);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _errorColor = const Color(0xFFEF4444);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  bool isRefreshing = false;
  String _selectedFilter = 'All Items';
  final List<String> _filterList = ['All Items', 'With SN', 'Without SN'];

  GoodReceiptModel? _grinData;
  List<Map<String, dynamic>> _detailItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  final Map<String, String> _productNames = {};
  String _grinStatus = 'Belum Dikirim';
  Map<String, dynamic>? _editingItem;
  int _originalQuantity = 0;

  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _itemsPerPage = 20; // Jumlah item per halaman
  List<Map<String, dynamic>> _displayedItems = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadGrinDetailData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // Handle scroll untuk pagination
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreData();
    }
  }

  // Load more data untuk pagination
  // di good_receipt_detail_page.dart

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || _isSearching) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    // Simulasi delay untuk loading
    await Future.delayed(const Duration(milliseconds: 500));

    // Perhitungan startIndex sekarang benar (dimulai dari halaman ke-2)
    final startIndex =
        _currentPage * _itemsPerPage; // <-- (Akan menjadi 1 * 20 = 20)
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredItems.length) {
      // <-- Cek jika startIndex sudah di luar batas
      setState(() {
        _hasMoreData = false;
        _isLoadingMore = false;
      });
      return;
    }

    if (endIndex < _filteredItems.length) {
      setState(() {
        _displayedItems.addAll(_filteredItems.sublist(startIndex, endIndex));
        _currentPage++; // <-- Pindah ke halaman berikutnya
        _isLoadingMore = false;
      });
    } else {
      final remainingItems = _filteredItems.sublist(startIndex);
      setState(() {
        _displayedItems.addAll(remainingItems);
        _hasMoreData = false; // <-- Data sudah habis
        _isLoadingMore = false;
        // _currentPage tidak perlu di-increment lagi di sini
      });
    }
  }

  // Reset pagination ketika filter/search berubah
  // di good_receipt_detail_page.dart

  void _resetPagination() {
    setState(() {
      _currentPage = 1; // <-- UBAH INI DARI 0 MENJADI 1
      _hasMoreData = true;
      _isLoadingMore = false;
      _displayedItems = _filteredItems.take(_itemsPerPage).toList();

      // Logika tambahan untuk cek _hasMoreData
      if (_displayedItems.length < _itemsPerPage) {
        _hasMoreData = false;
      }
    });
  }

  // di good_receipt_detail_page.dart

  Future<void> _loadGrinDetailData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final grinDoc = await _firestore
          .collection('good_receipt')
          .doc(widget.grId)
          .get();

      if (grinDoc.exists) {
        _grinData = GoodReceiptModel.fromFirestore(grinDoc, null);

        // === TENTUKAN STATUS DARI status === (Bukan lastSentToKafkaLogStatus)
        final kafkaStatus = grinDoc.data()?['status'];
        if (kafkaStatus == null) {
          _grinStatus = 'Belum Dikirim';
        } else if (kafkaStatus == 'error') {
          _grinStatus = 'Error';
        } else if (kafkaStatus == 'completed') {
          _grinStatus = 'Completed';
        } else {
          _grinStatus = 'Processing'; // (Contoh: 'drafted', 'pending')
        }

        // Process detail items
        _detailItems = _processDetailItems(_grinData!.details);
        _filteredItems = List.from(_detailItems);
        _resetPagination(); // Initialize pagination

        // Load product names
        await _loadProductNames();
      } // <-- Hapus blok 'if (grinDoc.exists)' kedua yang duplikat

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading GRIN detail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _processDetailItems(
    List<GoodReceiptDetailModel> details,
  ) {
    return details.map((detail) {
      return {
        'sn': detail.sn,
        'productid': detail.productid,
        'qty': detail.qty,
        'productName': _productNames[detail.productid] ?? 'Loading...',
        'hasSN': detail.sn != null && detail.sn!.isNotEmpty,
        'originalIndex': details.indexOf(
          detail,
        ), // Simpan index asli untuk update
      };
    }).toList();
  }

  Future<void> _loadProductNames() async {
    try {
      if (_grinData == null) return;

      // Get PO number from GR IN data
      final poNumber = _grinData!.poNumber;

      // Query IN collection to find matching document
      final inQuery = await _firestore
          .collection('in')
          .where('documentno', isEqualTo: poNumber)
          .limit(1)
          .get();

      if (inQuery.docs.isNotEmpty) {
        final inData = inQuery.docs.first.data();
        final details = inData['details'] as List<dynamic>?;

        if (details != null) {
          for (final detail in details) {
            final productId = detail['m_product_id']?.toString();
            final productName = detail['m_product_name']?.toString();

            if (productId != null && productName != null) {
              _productNames[productId] = productName;
            }
          }

          // Update product names in detail items
          for (final item in _detailItems) {
            final productId = item['productid'];
            if (_productNames.containsKey(productId)) {
              item['productName'] = _productNames[productId]!;
            }
          }

          if (mounted) {
            setState(() {
              _filteredItems = _applyFiltersAndSearch(_detailItems);
              _resetPagination(); // Reset pagination ketika data berubah
            });
          }
        }
      }
    } catch (e) {
      _logger.e('Error loading product names: $e');
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isRefreshing = true;
    });

    await _loadGrinDetailData();

    setState(() {
      isRefreshing = false;
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _filteredItems = _applyFiltersAndSearch(_detailItems);
      _resetPagination(); // Reset pagination ketika search di-clear
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _filteredItems = _applyFiltersAndSearch(_detailItems);
      _resetPagination(); // Reset pagination ketika search berubah
    });
  }

  void _handleFilterChange(String? value) {
    setState(() {
      _selectedFilter = value ?? 'All Items';
      _filteredItems = _applyFiltersAndSearch(_detailItems);
      _resetPagination(); // Reset pagination ketika filter berubah
    });
  }

  List<Map<String, dynamic>> _applyFiltersAndSearch(
    List<Map<String, dynamic>> items,
  ) {
    String searchQuery = _searchController.text.toLowerCase();

    // Apply filter
    List<Map<String, dynamic>> filtered = items.where((item) {
      switch (_selectedFilter) {
        case 'With SN':
          return item['hasSN'] == true;
        case 'Without SN':
          return item['hasSN'] == false;
        default:
          return true;
      }
    }).toList();

    // Apply search
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final productName = item['productName']?.toString().toLowerCase() ?? '';
        final productId = item['productid']?.toString().toLowerCase() ?? '';
        final sn = item['sn']?.toString().toLowerCase() ?? '';

        return productName.contains(searchQuery) ||
            productId.contains(searchQuery) ||
            sn.contains(searchQuery);
      }).toList();
    }

    return filtered;
  }

  // Shimmer untuk load more
  Widget _buildLoadMoreShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          // Shimmer untuk 20 item loading
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            period: const Duration(milliseconds: 1500),
            child: Column(
              children: List.generate(20, (index) => _buildShimmerItem()),
            ),
          ),
          const SizedBox(height: 16),
          // Loading indicator kecil di bawah
          const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(hijauGojek),
          ),
          const SizedBox(height: 8),
          Text(
            'Loading more items...',
            style: TextStyle(color: _textSecondaryColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Widget untuk satu item shimmer
  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left colored indicator
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product name shimmer
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                // Product ID row
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 120,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Serial number row
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quantity row
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
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
        ],
      ),
    );
  }

  // Indicator untuk akhir list
  Widget _buildEndOfListIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withValues(alpha: 0.08),
              blurRadius: 12.0,
              offset: const Offset(0, 4.0),
              spreadRadius: 1.0,
            ),
          ],
          border: Border.all(
            color: _primaryColor.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.0,
              height: 20.0,
              decoration: BoxDecoration(
                color: _primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 14.0,
                color: _primaryColor,
              ),
            ),
            const SizedBox(width: 8.0),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All items loaded',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                      color: _textPrimaryColor,
                    ),
                  ),
                  Text(
                    '${_filteredItems.length} items total',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 11.0,
                      fontWeight: FontWeight.w400,
                      color: _textSecondaryColor.withValues(alpha: 0.8),
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

  // Fungsi untuk menampilkan bottom sheet edit quantity
  void _showEditQuantityBottomSheet(Map<String, dynamic> item) {
    _editingItem = item;
    _originalQuantity = item['qty'] ?? 0;
    _quantityController.text = _originalQuantity.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Section
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    color: _primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Quantity',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['productName'] ?? 'Unknown Product',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 14,
                          color: _textSecondaryColor,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quantity Input Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quantity',
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimaryColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Masukkan quantity...',
                      hintStyle: TextStyle(
                        fontFamily: 'MonaSans',
                        color: _textSecondaryColor.withValues(alpha: 0.6),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.format_list_numbered_rounded,
                          color: _textSecondaryColor,
                          size: 20,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quantity sebelumnya: $_originalQuantity',
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          fontSize: 12,
                          color: _textSecondaryColor,
                        ),
                      ),
                      if (_originalQuantity > 0)
                        GestureDetector(
                          onTap: () {
                            _quantityController.text = _originalQuantity
                                .toString();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                fontSize: 12,
                                color: _primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          _quantityController.clear();
                        },
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.grey.withValues(alpha: 0.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textSecondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Save Button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          _primaryColor,
                          _primaryColor.withValues(alpha: 0.9),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _saveQuantity,
                        borderRadius: BorderRadius.circular(12),
                        splashColor: Colors.white.withValues(alpha: 0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Simpan',
                                  style: TextStyle(
                                    fontFamily: 'MonaSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menyimpan quantity yang diedit
  Future<void> _saveQuantity() async {
    if (_editingItem == null) return;

    final newQuantity = int.tryParse(_quantityController.text);
    if (newQuantity == null || newQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Quantity harus angka yang valid dan lebih dari 0',
          ),
          backgroundColor: _errorColor,
        ),
      );
      return;
    }

    try {
      // Update di Firestore
      final grinRef = _firestore.collection('good_receipt').doc(widget.grId);
      final grinDoc = await grinRef.get();

      if (grinDoc.exists) {
        final data = grinDoc.data()!;
        final details = List<Map<String, dynamic>>.from(data['details']);

        // Update quantity pada item yang sesuai
        final originalIndex = _editingItem!['originalIndex'];
        if (originalIndex < details.length) {
          details[originalIndex]['qty'] = newQuantity;

          await grinRef.update({'details': details});

          // Update state lokal
          setState(() {
            _editingItem!['qty'] = newQuantity;
            // Refresh filtered items dan reset pagination
            _filteredItems = _applyFiltersAndSearch(_detailItems);
            _resetPagination();
          });

          if (mounted) {
            Navigator.of(context).pop();
            _quantityController.clear();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Quantity berhasil diupdate'),
                backgroundColor: _successColor,
              ),
            );
          }
        }
      }
    } catch (e) {
      _logger.e('Error updating quantity: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating quantity: $e'),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  // Fungsi untuk menghapus item
  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header dengan icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hapus Item',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Apakah Anda yakin ingin menghapus item ini?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Produk',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['productName'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tindakan ini tidak dapat dibatalkan',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.amber.shade900,
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

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
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
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.red.shade600.withValues(alpha: 0.3),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Hapus',
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
      ),
    );

    if (shouldDelete != true) return;

    final grinRef = _firestore.collection('good_receipt').doc(widget.grId);

    try {
      await _firestore.runTransaction((transaction) async {
        final grinSnap = await transaction.get(grinRef);
        if (!grinSnap.exists) {
          throw Exception('GR tidak ditemukan: ${widget.grId}');
        }

        final data = grinSnap.data()!;
        final details = List<Map<String, dynamic>>.from(data['details'] ?? []);
        final originalIndex = item['originalIndex'] as int;

        if (originalIndex < 0 || originalIndex >= details.length) {
          throw Exception(
            'originalIndex $originalIndex out of range (details length ${details.length})',
          );
        }

        final itemToDelete = Map<String, dynamic>.from(details[originalIndex]);

        final rawSerial =
            itemToDelete['sn'] ??
            itemToDelete['SN'] ??
            itemToDelete['serial_number'] ??
            itemToDelete['serialNumber'];
        final serialNumber = rawSerial is String
            ? rawSerial.trim()
            : (rawSerial?.toString().trim() ?? '');
        final isSerializedItem = serialNumber.isNotEmpty;

        details.removeAt(originalIndex);

        transaction.update(grinRef, {'details': details});

        if (isSerializedItem) {
          final serialDocRef = _firestore
              .collection('serial_numbers')
              .doc(serialNumber);
          final serialSnap = await transaction.get(serialDocRef);
          if (serialSnap.exists) {
            final sdata = serialSnap.data();
            if (sdata != null && sdata['gr_id'] == widget.grId) {
              transaction.delete(serialDocRef);
              return;
            }
          }

          throw Exception(
            'Serial doc with ID "$serialNumber" not found or gr_id mismatch inside transaction.',
          );
        }
      });

      setState(() {
        _detailItems.removeWhere(
          (d) => d['originalIndex'] == item['originalIndex'],
        );
        for (int i = 0; i < _detailItems.length; i++) {
          _detailItems[i]['originalIndex'] = i;
        }
        _filteredItems = _applyFiltersAndSearch(_detailItems);
        _resetPagination();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item berhasil dihapus'),
            backgroundColor: _successColor,
          ),
        );
      }
    } catch (e) {
      _logger.w(
        'Transaksi gagal atau serial tidak bisa dihapus dalam transaksi: $e — mencoba fallback non-transactional.',
      );

      try {
        final grinDoc = await grinRef.get();
        if (grinDoc.exists) {
          final data = grinDoc.data()!;
          final details = List<Map<String, dynamic>>.from(
            data['details'] ?? [],
          );
          final originalIndex = item['originalIndex'] as int;
          if (originalIndex >= 0 && originalIndex < details.length) {
            final itemToDelete = details[originalIndex];
            final rawSerial =
                itemToDelete['sn'] ??
                itemToDelete['SN'] ??
                itemToDelete['serial_number'] ??
                itemToDelete['serialNumber'];
            final serialNumber = rawSerial is String
                ? rawSerial.trim()
                : (rawSerial?.toString().trim() ?? '');

            details.removeAt(originalIndex);
            await grinRef.update({'details': details});

            if (serialNumber.isNotEmpty) {
              await _deleteSerialNumberBySn(serialNumber);
            }
          }
        }

        setState(() {
          _detailItems.removeWhere(
            (d) => d['originalIndex'] == item['originalIndex'],
          );
          for (int i = 0; i < _detailItems.length; i++) {
            _detailItems[i]['originalIndex'] = i;
          }
          _filteredItems = _applyFiltersAndSearch(_detailItems);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item berhasil dihapus (fallback)'),
              backgroundColor: _successColor,
            ),
          );
        }
      } catch (e2) {
        _logger.e('Gagal menghapus item (fallback): $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting item: $e2'),
              backgroundColor: _errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSerialNumberBySn(String serialNumber) async {
    try {
      final normalizedSn = serialNumber.trim();
      final lowerSn = normalizedSn.toLowerCase();
      final upperSn = normalizedSn.toUpperCase();

      _logger.i(
        '🔍 Mencoba hapus serial number: $normalizedSn (lower: $lowerSn) dari GR: ${widget.grId}',
      );

      // METODE 1: Coba doc ID sesuai case (original)
      final docRefOriginal = _firestore
          .collection('serial_numbers')
          .doc(normalizedSn);
      final docSnapOriginal = await docRefOriginal.get();

      if (docSnapOriginal.exists) {
        final data = docSnapOriginal.data();
        if (data != null && data['gr_id'] == widget.grId) {
          await docRefOriginal.delete();
          _logger.i(
            '✅ Berhasil hapus serial number (original ID match): $normalizedSn',
          );
          return;
        }
      }

      // METODE 2: Coba versi lowercase
      final docRefLower = _firestore.collection('serial_numbers').doc(lowerSn);
      final docSnapLower = await docRefLower.get();

      if (docSnapLower.exists) {
        final data = docSnapLower.data();
        if (data != null && data['gr_id'] == widget.grId) {
          await docRefLower.delete();
          _logger.i(
            '✅ Berhasil hapus serial number (lowercase match): $lowerSn',
          );
          return;
        }
      }

      // METODE 3: Coba versi uppercase
      final docRefUpper = _firestore.collection('serial_numbers').doc(upperSn);
      final docSnapUpper = await docRefUpper.get();

      if (docSnapUpper.exists) {
        final data = docSnapUpper.data();
        if (data != null && data['gr_id'] == widget.grId) {
          await docRefUpper.delete();
          _logger.i(
            '✅ Berhasil hapus serial number (uppercase match): $upperSn',
          );
          return;
        }
      }

      // METODE 4: Fallback query (jaga-jaga jika doc ID tidak sama)
      _logger.i('🧩 Fallback query by gr_id...');
      final querySnapshot = await _firestore
          .collection('serial_numbers')
          .where('gr_id', isEqualTo: widget.grId)
          .get();

      for (var doc in querySnapshot.docs) {
        final id = doc.id.toLowerCase();
        if (id == lowerSn) {
          await doc.reference.delete();
          _logger.i(
            '✅ Berhasil hapus serial number (fallback query): ${doc.id}',
          );
          return;
        }
      }

      _logger.w(
        '⚠ Serial number tidak ditemukan dalam semua metode: $normalizedSn',
      );
    } catch (e) {
      _logger.e('❌ Error menghapus serial number $serialNumber: $e');
      throw Exception('Gagal menghapus serial number: $e');
    }
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: _clearSearchQuery,
        ),
      ];
    }

    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: _handleRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _startSearch,
          ),
        ],
      ),
    ];
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search Product Name, Product ID, SN...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (value) => _updateSearchQuery(value),
    );
  }

  Widget _buildHeaderInfo() {
    if (_grinData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // GR ID and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _grinData!.grId,
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
              Text(
                _grinData!.createdAt != null
                    ? DateHelper.formatDate(
                        _grinData!.createdAt!.toIso8601String(),
                      )
                    : 'No Date',
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // PO Number and Created By
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.receipt_long,
                  'PO Number',
                  _grinData!.poNumber,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Icons.person,
                  'Created By',
                  TextHelper.formatUserName(_grinData!.createdBy ?? 'Unknown'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total Items and Status
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Icons.inventory_2,
                  'Total Items',
                  '${_detailItems.length} items',
                ),
              ),
              Expanded(
                child: Expanded(
                  child: _buildInfoItem(
                    Icons.sync,
                    'Status',
                    _grinStatus,
                    valueColor: _getStatusColor(_grinStatus),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return _successColor;
      case 'Error':
        return _errorColor;
      case 'Belum Dikirim':
        return _warningColor;
      default:
        return _textSecondaryColor;
    }
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 12,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 14,
                  color: valueColor ?? _textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_displayedItems.length} of ${_filteredItems.length} items shown', // Tampilkan jumlah yang ditampilkan vs total
            style: TextStyle(
              fontFamily: 'MonaSans',
              fontSize: 14,
              color: _textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_alt, color: _primaryColor, size: 18),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton(
                    dropdownColor: Colors.white,
                    icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                    value: _selectedFilter,
                    items: _filterList
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontFamily: 'MonaSans',
                                color: _textPrimaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _handleFilterChange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildShimmerLoader();
    }

    if (_grinData == null) {
      return _buildErrorState();
    }

    if (_detailItems.isEmpty) {
      return _buildEmptyState();
    }

    return _buildDetailList();
  }

  Widget _buildShimmerLoader() {
    return Expanded(
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            period: const Duration(milliseconds: 1500),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Data Not Found",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Unable to load GRIN details",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: _textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _primaryColor,
              ),
              child: TextButton(
                onPressed: _handleRefresh,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontFamily: 'MonaSans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_outlined,
                size: 60,
                color: _textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Items Found",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No items available for this good receive",
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: _textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailList() {
    return Expanded(
      child: RefreshIndicator(
        backgroundColor: Colors.white,
        color: _primaryColor,
        onRefresh: _handleRefresh,
        child: ListView.builder(
          controller: _scrollController,
          shrinkWrap: true,
          clipBehavior: Clip.hardEdge,
          itemCount:
              _displayedItems.length +
              (_isLoadingMore ? 1 : 0) +
              (!_hasMoreData && _displayedItems.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            // Loading indicator untuk load more
            if (_isLoadingMore && index == _displayedItems.length) {
              return _buildLoadMoreShimmer();
            }

            // End of list indicator
            if (!_hasMoreData &&
                _displayedItems.isNotEmpty &&
                index == _displayedItems.length) {
              return _buildEndOfListIndicator();
            }

            // Item data
            return _buildDetailCard(_displayedItems[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> item, int index) {
    final hasSN = item['hasSN'] == true;
    final sn = item['sn'] ?? 'Without Serial Number';
    final productName = item['productName'] ?? 'Unknown Product';
    final productId = item['productid'] ?? 'Unknown ID';
    final qty = item['qty'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: hasSN ? _successColor : _warningColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and SN Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _textPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: hasSN
                              ? _successColor.withValues(alpha: 0.1)
                              : _warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hasSN
                                ? _successColor.withValues(alpha: 0.3)
                                : _warningColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          hasSN ? 'With SN' : 'No SN',
                          style: TextStyle(
                            fontFamily: 'MonaSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: hasSN ? _successColor : _warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Product ID
                  _buildDetailRow(Icons.qr_code, 'Product ID', productId),
                  const SizedBox(height: 8),
                  // Serial Number
                  _buildDetailRow(
                    Icons.confirmation_number,
                    'Serial Number',
                    sn,
                  ),
                  const SizedBox(height: 8),
                  // Quantity
                  _buildDetailRow(
                    Icons.format_list_numbered,
                    'Quantity',
                    '$qty pcs',
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 24, thickness: 1),
                  // Action buttons
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: hasSN ? _successColor : _warningColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hasSN ? 'Serialized Item' : 'Non-Serialized Item',
                            style: TextStyle(
                              fontFamily: 'MonaSans',
                              fontSize: 12,
                              color: _textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // HANYA TAMPILKAN TOMBOL JIKA STATUS BUKAN COMPLETED
                      if (_grinStatus != 'Completed')
                        Row(
                          children: [
                            // Tombol Edit hanya untuk item tanpa SN
                            if (!hasSN)
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  onPressed: () =>
                                      _showEditQuantityBottomSheet(item),
                                  icon: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: _primaryColor,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            if (!hasSN) const SizedBox(width: 8),
                            // Tombol Hapus
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _errorColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () => _deleteItem(item),
                                icon: Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: _errorColor,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: _primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 12,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  fontSize: 14,
                  color: _textPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleBackPress() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: hijauGojek,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          appBar: AppBar(
            actions: _buildAppBarActions(),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                size: 20.0,
                color: Colors.white,
              ),
              onPressed: _handleBackPress,
            ),
            backgroundColor: _primaryColor,
            elevation: 0,
            title: _isSearching
                ? _buildSearchField()
                : Text(
                    "GRIN Details",
                    style: TextStyle(
                      fontFamily: 'MonaSans',
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
          backgroundColor: _backgroundColor,
          body: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Information
                _buildHeaderInfo(),
                // List Header with filter and count
                _buildListHeader(),
                const SizedBox(height: 16),
                // Content
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
