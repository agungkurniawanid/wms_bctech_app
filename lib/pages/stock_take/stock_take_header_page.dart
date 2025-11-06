import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/stock/stock_take_model.dart';
import 'package:wms_bctech/pages/stock_take/stock_take_detail_page.dart';

class StockTakeHeader extends StatefulWidget {
  final StockTakeModel? stocktake;
  const StockTakeHeader({this.stocktake, super.key});

  @override
  State<StockTakeHeader> createState() => _StockTakeHeaderState();
}

class _StockTakeHeaderState extends State<StockTakeHeader>
    with SingleTickerProviderStateMixin {
  // Definisi warna hijau Gojek
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

  // Data dummy untuk dokumen stock take
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
                                colors: [hijauGojek, hijauGojekDark],
                              )
                            : null,
                        color: isSelected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? hijauGojek : Colors.grey.shade300,
                          width: isSelected ? 0 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: hijauGojek.withValues(alpha: 0.3),
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
            color: hijauGojek.withValues(alpha: 0.08),
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
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Document Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [hijauGojek, hijauGojekDark],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: hijauGojek.withValues(alpha: 0.3),
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

                    // Status Badge
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

                // Divider
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

                // Info Section
                Row(
                  children: [
                    // Left Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.person_rounded,
                            'Created By',
                            document['createdby'],
                            hijauGojek,
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

                    // Vertical Divider
                    Container(
                      width: 1,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Colors.grey.shade200,
                    ),

                    // Right Section - Stats
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: hijauGojek.withValues(alpha: 0.1),
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

                // Bottom Action
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: hijauGojek.withValues(alpha: 0.05),
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
                        color: hijauGojek,
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

  Future<void> _showCreateDocumentDialog() async {
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
                'Create New Document?',
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
                'Are you sure to create a new stock take document based on current stock?',
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
                        'This action will create a new document for stock taking',
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                StockTakeDetail(stocktake: widget.stocktake),
                          ),
                        );
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
                            'Create',
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

  Future<void> _createNewDocument() async {
    try {
      EasyLoading.show(
        status: 'Creating Document...',
        maskType: EasyLoadingMaskType.black,
      );

      // Simulasi pembuatan dokumen baru
      await Future.delayed(const Duration(seconds: 2));

      // Tambah dokumen dummy baru
      final newDoc = {
        'documentno': 'DOC00${_dummyDocuments.length + 1}',
        'createdby': 'Demo User',
        'created': DateTime.now().toString().substring(0, 19),
        'isapprove': 'N',
        'lGORT': ['WH-NEW'],
        'totalItems': 0,
      };

      setState(() {
        _dummyDocuments.insert(0, newDoc);
        _filterDocuments();
      });

      EasyLoading.dismiss();
      Get.back();
      EasyLoading.showSuccess('Document created successfully!');
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to create document');
    }
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
                  hijauGojek.withValues(alpha: 0.1),
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
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showCreateDocumentDialog,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Create Document',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hijauGojek,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> document, int index) {
    // Buat StockTakeModel dummy dari data document
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
                colors: [hijauGojek, hijauGojekDark],
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
          onPressed: _showCreateDocumentDialog,
          backgroundColor: hijauGojek,
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
    super.dispose();
  }
}
