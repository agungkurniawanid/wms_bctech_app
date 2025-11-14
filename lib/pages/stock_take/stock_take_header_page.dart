import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:wms_bctech/constants/theme_constant.dart'; // Pastikan path import ini benar
import 'package:wms_bctech/helpers/date_helper.dart'; // Pastikan path import ini benar
import 'package:wms_bctech/helpers/text_helper.dart'; // Pastikan path import ini benar // Pastikan path import ini benar
import 'package:wms_bctech/models/pid_document/pid_document_model.dart';
import 'package:wms_bctech/models/stock/stock_take_detail_model.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart'; // Pastikan path import ini benar// Pastikan path import ini benar
import 'package:wms_bctech/pages/stock_take/stock_take_detail_page.dart'; // Pastikan path import ini benar
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
      'label': 'N', // 'N' akan kita petakan ke status != 'completed'
      'labelName': 'In Progress',
      'icon': Icons.pending_actions_rounded,
    },
    {
      'id': 2,
      'label': 'Y', // 'Y' akan kita petakan ke status == 'completed'
      'labelName': 'Completed',
      'icon': Icons.check_circle_rounded,
    },
  ];

  final List<PidDocumentModel> _allPidDocuments = [];
  final List<PidDocumentModel> _filteredDocuments = [];

  // --- MODIFIKASI: Variabel State untuk Pagination ---
  bool _isLoading = true; // Loading untuk data awal
  bool _isLoadingMore = false; // Loading untuk pagination
  bool _hasMoreData = true; // Apakah masih ada data di server
  DocumentSnapshot? _lastDocument; // Kursor untuk query pagination
  static const int _pageSize = 50; // Jumlah data per halaman
  // --- END MODIFIKASI ---

  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Product selection variables (Tidak berubah)
  final Set<String> _selectedProductIds = {};
  final TextEditingController _productSearchController =
      TextEditingController();

  bool allowBack = true;
  bool _isSearching = false;
  int _selectedStatusId = 2;
  String searchQuery = '';
  String _choiceForChip = 'Y';

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

    // --- MODIFIKASI: Panggil _loadInitialData dan tambahkan listener ---
    _loadInitialData(); // Ganti _setupDocumentStream
    _controller.addListener(_onScroll); // Listener untuk pagination
    // --- END MODIFIKASI ---

    _animationController.forward();
  }

  // --- MODIFIKASI: Listener untuk Scroll Controller ---
  void _onScroll() {
    // Cek jika sudah di akhir list, tidak sedang loading, dan masih ada data
    if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData &&
        !_isLoading) {
      _loadMoreData();
    }
  }
  // --- END MODIFIKASI ---

  // --- MODIFIKASI: Ganti _setupDocumentStream menjadi _loadInitialData ---
  Future<void> _loadInitialData() async {
    // Set loading true untuk menampilkan 10 shimmer
    setState(() {
      _isLoading = true;
      _hasMoreData = true; // Asumsikan ada data saat load awal
      _lastDocument = null; // Reset kursor
    });

    try {
      final locator = widget.stocktake?.locatorValue;
      if (locator == null || locator.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasMoreData = false;
        });
        _filterDocuments();
        return;
      }

      // Query ke collection 'pid_document'
      final query = FirebaseFirestore.instance
          .collection('pid_document')
          .where('locatorValue', isEqualTo: locator)
          .orderBy('createdAt', descending: true)
          .limit(_pageSize); // Ambil 50 data pertama

      // --- MODIFIKASI: Gunakan .get() BUKAN .snapshots() ---
      final querySnapshot = await query.get();

      final List<PidDocumentModel> fetchedDocs = querySnapshot.docs
          .map((doc) => PidDocumentModel.fromFirestore(doc, null))
          .toList();

      // Update kursor
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      // Cek apakah data yang didapat < page size
      if (fetchedDocs.length < _pageSize) {
        _hasMoreData = false;
      }

      if (!mounted) return;
      setState(() {
        _allPidDocuments.clear(); // Hapus data lama
        _allPidDocuments.addAll(fetchedDocs);
        _isLoading = false; // Set loading false setelah data didapat
      });

      _filterDocuments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      EasyLoading.showError('Error memuat data: $e');
    }
  }
  // --- END MODIFIKASI ---

  // --- MODIFIKASI: Tambahkan fungsi _loadMoreData ---
  Future<void> _loadMoreData() async {
    if (_isLoading || _isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final locator = widget.stocktake?.locatorValue;
      if (locator == null || locator.isEmpty || _lastDocument == null) {
        setState(() {
          _isLoadingMore = false;
          _hasMoreData = false;
        });
        return;
      }

      // Query ke collection 'pid_document'
      final query = FirebaseFirestore.instance
          .collection('pid_document')
          .where('locatorValue', isEqualTo: locator)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!) // Mulai dari dokumen terakhir
          .limit(_pageSize); // Ambil 50 data berikutnya

      final querySnapshot = await query.get();

      final List<PidDocumentModel> fetchedDocs = querySnapshot.docs
          .map((doc) => PidDocumentModel.fromFirestore(doc, null))
          .toList();

      // Update kursor
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      // Cek apakah data yang didapat < page size
      if (fetchedDocs.length < _pageSize) {
        _hasMoreData = false;
      }

      if (!mounted) return;
      setState(() {
        _allPidDocuments.addAll(fetchedDocs); // Tambahkan data baru ke list
        _isLoadingMore = false;
      });

      _filterDocuments();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      EasyLoading.showError('Error memuat data: $e');
    }
  }
  // --- END MODIFIKASI ---

  // --- MODIFIKASI: _handleRefresh memanggil _loadInitialData ---
  Future<void> _handleRefresh() async {
    // Panggil _loadInitialData untuk me-reset dan mengambil 50 data pertama
    await _loadInitialData();
  }
  // --- END MODIFIKASI ---

  void _filterDocuments() {
    setState(() {
      _filteredDocuments.clear();

      // 1. Filter berdasarkan Status Tab
      List<PidDocumentModel> statusFiltered = [];
      if (_choiceForChip == 'Y') {
        // 'Y' = Completed
        statusFiltered = _allPidDocuments
            .where((doc) => doc.status == 'completed')
            .toList();
      } else {
        // 'N' = In Progress (semua status selain 'completed')
        statusFiltered = _allPidDocuments
            .where((doc) => doc.status != 'completed')
            .toList();
      }

      // 2. Filter berdasarkan Search Query
      if (searchQuery.isEmpty) {
        _filteredDocuments.addAll(statusFiltered);
      } else {
        final query = searchQuery.toUpperCase();
        _filteredDocuments.addAll(
          statusFiltered.where(
            (doc) => doc.pidDocument.toUpperCase().contains(query),
          ),
        );
      }
    });
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      searchQuery = ''; // Pastikan reset query
    });
    _filterDocuments(); // Terapkan ulang filter
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
    _filterDocuments(); // Panggil filter utama
  }

  void _showProductSelectionBottomSheet() {
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
  ) {
    // 1. Buat Model "Sementara" (Transient Model)
    // Tidak perlu 'async' atau 'EasyLoading' karena kita tidak menyimpan apa-apa
    final stockTakeModel = StockTakeModel(
      // Beri ID kosong. Halaman detail akan tahu
      // ini adalah dokumen baru yang perlu DIBUAT saat di-save.
      documentid: '',
      // (misal: Get.find<GlobalVM>().username.value)
      createdBy: 'Demo User',
      created: DateTime.now().toString(),
      isApprove: 'N', // Dokumen baru pasti belum diapprove
      // Ambil data dari warehouse/lokator saat ini
      lGort: widget.stocktake?.lGort ?? ['WH-NEW'],
      whName: widget.stocktake?.whName ?? 'New Warehouse',
      whValue: widget.stocktake?.whValue ?? '',
      locatorValue: widget.stocktake?.locatorValue ?? '',
      orgValue: widget.stocktake?.orgValue ?? '',
      orgName: widget.stocktake?.orgName ?? '',
      lastQuery: widget.stocktake?.lastQuery ?? '',

      // Masukkan list produk yang tadi dipilih
      detail: selectedProducts
          .map((p) => StockTakeDetailModel.fromJson(p))
          .toList(),
      countDetail: selectedProducts.length,

      // Beri doctype unik agar halaman detail tahu ini ADALAH PID BARU
      // yang harus disimpan ke koleksi 'pid_document'
      doctype: 'pid_document_NEW',

      updated: '',
      updatedby: '',
    );

    // 2. Navigasi ke Halaman Detail
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockTakeDetail(
          stocktake: stockTakeModel,

          // PENTING: Set ke false. Ini adalah mode input, bukan lihat saja.
          isViewMode: false,

          // Flag ini memberi tahu halaman detail bahwa ini adalah
          // dokumen PID baru, bukan dari list 'stock'
          fromDocumentList: true,
        ),
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
              _stopSearching();
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: _statusChoices.map((choice) {
          final isSelected = _selectedStatusId == choice['id'];
          // ✅ TAMBAHAN: Tentukan apakah tab ini disabled (ID 1 = In Progress)
          final bool isDisabled = choice['id'] == 1;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // ✅ MODIFIKASI: Matikan splash effect jika disabled
                    splashColor: isDisabled ? Colors.transparent : null,
                    highlightColor: isDisabled ? Colors.transparent : null,
                    onTap: () => _onStatusSelected(choice),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [hijauGojekLight, hijauGojekDark],
                              )
                            : null,
                        // ✅ MODIFIKASI: Beri warna abu-abu jika disabled
                        color: isSelected
                            ? null
                            : (isDisabled
                                  ? Colors.grey.shade200
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? hijauGojekLight
                              // ✅ MODIFIKASI: Ubah border jika disabled
                              : (isDisabled
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade300),
                          width: isSelected ? 0 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: hijauGojekLight.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            choice['icon'],
                            // ✅ MODIFIKASI: Ubah warna ikon jika disabled
                            color: isSelected
                                ? Colors.white
                                : (isDisabled
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            size: 22, // 🔹 lebih kecil dari 28
                          ),
                          const SizedBox(height: 6),
                          Text(
                            choice['labelName'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5, // 🔹 dari 13 → 11.5
                              fontWeight: FontWeight.w600,
                              // ✅ MODIFIKASI: Ubah warna teks jika disabled
                              color: isSelected
                                  ? Colors.white
                                  : (isDisabled
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade700),
                              letterSpacing: 0.2,
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
    });
    _filterDocuments(); // Terapkan filter
  }

  Widget _buildDocumentCard(PidDocumentModel document, int index) {
    final isCompleted = document.status == 'completed';

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
          onTap: () => _navigateToDetail(document, index), // Kirim model
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
                            document.pidDocument, // Ganti ke pidDocument
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
                            TextHelper.formatUserName(
                              document.createdBy ?? 'N/A',
                            ), // Ganti ke createdBy
                            hijauGojekLight,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.access_time_rounded,
                            'Created At',
                            DateHelper.formatDate(
                              document.createdAt?.toLocal().toString(),
                            ), // Ganti ke createdAt
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
                          '${document.products.length}', // Ganti ke total products
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

  Widget _buildLoadingShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 220, // Sesuaikan tinggi dengan card asli
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // --- MODIFIKASI: Update _buildDocumentList untuk handle pagination ---
  Widget _buildDocumentList() {
    // 1. Handle Loading Awal
    if (_isLoading) {
      return Expanded(
        child: ListView.builder(
          // --- MODIFIKASI: Tampilkan 10 shimmer placeholder ---
          itemCount: 10,
          itemBuilder: (context, index) => _buildLoadingShimmerCard(),
        ),
      );
    }

    // 2. Handle Empty State
    if (_filteredDocuments.isEmpty) {
      return Expanded(child: _buildEmptyState());
    }

    // 3. Handle Data + Pagination Loading
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView.builder(
          controller: _controller,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          // --- MODIFIKASI: Tambah 1 item untuk shimmer loading pagination ---
          itemCount: _filteredDocuments.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            // --- MODIFIKASI: Cek jika ini item terakhir (loading shimmer) ---
            if (index == _filteredDocuments.length) {
              return _buildLoadingShimmerCard(); // Shimmer saat scroll
            }
            // --- END MODIFIKASI ---

            final document =
                _filteredDocuments[index]; // Ini adalah PidDocumentModel
            return _buildDocumentCard(document, index);
          },
        ),
      ),
    );
  }
  // --- END MODIFIKASI ---

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
              _isSearching || searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isSearching || searchQuery.isNotEmpty
                ? 'Dokumen Tidak Ditemukan'
                : 'Belum Ada Dokumen',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSearching || searchQuery.isNotEmpty
                ? 'Coba ubah kata kunci pencarian Anda'
                : 'Dokumen "In Progress" atau "Completed" akan tampil di sini',
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

  // [FILE: stock_take_header.dart]

  void _navigateToDetail(PidDocumentModel document, int index) {
    // Buat StockTakeModel 'palsu' dari PidDocumentModel untuk navigasi
    final stockTakeModel = StockTakeModel(
      documentid: document.pidDocument,
      createdBy: document.createdBy ?? '',
      created: document.createdAt?.toString() ?? '',
      isApprove: document.status == 'completed' ? 'Y' : 'N',
      lGort: (document.locatorValue != null) ? [document.locatorValue!] : [],
      detail: document.products.map((pidProduct) {
        // 'pidProduct' adalah PidDocumentDetailModel (dari Firestore)
        // Ini berisi: productId, productSN, physicalQty, different, labst

        // Cari produk asli dari list utama (widget.stocktake.detail)
        // untuk mendapatkan maktx, insme, speme
        StockTakeDetailModel? originalProduct;
        try {
          // --- PERBAIKAN UTAMA DI SINI ---
          // Validasi harus menggunakan KEDUA productId dan productSN

          originalProduct = widget.stocktake?.detail.firstWhere((d) {
            // Cek ID produk dulu
            if (d.matnr != pidProduct.productId) return false;

            // Cek serial number. Ini sudah benar menangani null == null.
            return d.serno == pidProduct.productSN;
          });
          // --- BATAS PERBAIKAN ---
        } catch (e) {
          originalProduct = null;
        }

        // Tentukan stok sistem (labst) yang akan digunakan.
        // Prioritaskan 'labst' yang tersimpan di 'pid_document' (pidProduct.labst),
        // karena itu adalah snapshot stok pada saat dokumen dibuat.
        final double systemStock =
            pidProduct.labst ?? (originalProduct?.labst ?? 0.0);

        return StockTakeDetailModel(
          matnr: pidProduct.productId,
          serno: pidProduct.productSN, // Tetap teruskan serno ASLI dari pidDoc
          // 1. Ambil maktx dari produk asli yang cocok (unik)
          maktx: originalProduct?.maktx ?? 'Product ${pidProduct.productId}',

          // 2. Gunakan stok sistem yang sudah kita tentukan di atas
          labst: systemStock,

          // 3. Ambil tipe stok lain dari produk asli
          insme: originalProduct?.insme ?? 0.0,
          speme: originalProduct?.speme ?? 0.0,
          isApprove: document.status == 'completed' ? 'Y' : 'N',

          // 4. Asumsikan 'UU' karena PID doc tidak menyimpan info ini
          selectedChoice: 'UU',
          checkboxValidation: ValueNotifier<bool>(false),
        );
      }).toList(),
      updated: '',
      updatedby: '',
      doctype: 'pid_document',
      lastQuery: widget.stocktake?.lastQuery ?? '',
      countDetail: document.products.length,
      whName: document.whName ?? widget.stocktake?.whName ?? 'Warehouse',
      whValue: document.whValue ?? widget.stocktake?.whValue ?? '',
      locatorValue:
          document.locatorValue ?? widget.stocktake?.locatorValue ?? '',
      orgValue: document.orgValue ?? widget.stocktake?.orgValue ?? '',
      orgName: document.orgName ?? widget.stocktake?.orgName ?? '',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StockTakeDetail(
          stocktake: stockTakeModel,
          index: index,
          documentno: document.pidDocument,
          isViewMode: true, // Flag untuk mode preview
          fromDocumentList: true, // Flag dari list PID document
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
        body: RefreshIndicator(
          onRefresh: _handleRefresh, // <-- Panggil fungsi refresh
          color: hijauGojekLight,
          child: Column(
            children: [_buildStatusChoiceChips(), _buildDocumentList()],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showProductSelectionBottomSheet,
          backgroundColor: Colors.blueAccent,
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
    // --- MODIFIKASI: Hapus listener scroll ---
    _controller.removeListener(_onScroll); // Hapus listener
    // --- END MODIFIKASI ---

    _animationController.dispose();
    _controller.dispose(); // Dispose controller utama
    _searchController.dispose();
    _productSearchController.dispose();
    super.dispose();
  }
}

// =======================================================================
// ===               _ProductSelectionBottomSheet                    ===
// =======================================================================
// Bottom Sheet Widget yang terpisah dengan pagination dan live search
// (Kode ini disalin dari prompt Anda dan tidak diubah)

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
    // --- PERUBAHAN: Logika untuk 'serno' saat membuat key ---
    // Kita ganti '?? 'NO_SERNO'' menjadi '?? '''
    // Ini memastikan bahwa 'serno' yang null akan menjadi string kosong (""),
    // yang membuatnya unik dan berbeda dari serial number lain.
    // (matnr: "A", serno: null)  -> key "A|"
    // (matnr: "A", serno: "123") -> key "A|123"
    final serno = product['serno']?.toString() ?? '';
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
                          final serno = product['serno']?.toString() ?? '';

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
                                  'SKU: ${product['matnr'] ?? ''}',
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
