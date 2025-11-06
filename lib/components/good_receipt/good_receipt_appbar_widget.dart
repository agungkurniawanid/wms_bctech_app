import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:wms_bctech/constants/good_receipt/good_receipt_constant.dart';
import 'package:wms_bctech/controllers/good_receipt/good_receipt_controller.dart';

class GoodReceiptAppbarWidget extends StatefulWidget
    implements PreferredSizeWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onBackPressed;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback onStartSearch;
  final ValueChanged<String>? onSearchChanged;
  final GoodReceiptController grinController;

  const GoodReceiptAppbarWidget({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.onBackPressed,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onStartSearch,
    this.onSearchChanged,
    required this.grinController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<GoodReceiptAppbarWidget> createState() =>
      _GoodReceiptAppbarWidgetState();
}

class _GoodReceiptAppbarWidgetState extends State<GoodReceiptAppbarWidget> {
  final FocusNode _searchFocusNode = FocusNode();
  final Logger _logger = Logger();
  bool _isFocusRequested = false;

  @override
  void initState() {
    super.initState();
    _logger.d(
      '🎨 GoodReceiptAppbarWidget initState, isSearching: ${widget.isSearching}',
    );
  }

  @override
  void didUpdateWidget(covariant GoodReceiptAppbarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _logger.d(
      '🔄 GoodReceiptAppbarWidget didUpdateWidget, old: ${oldWidget.isSearching}, new: ${widget.isSearching}',
    );

    if (widget.isSearching && !oldWidget.isSearching) {
      _logger.d('🎯 Masuk mode search, request focus');
      _requestFocus();
    } else if (!widget.isSearching && oldWidget.isSearching) {
      _logger.d('🚪 Keluar mode search, unfocus');
      _searchFocusNode.unfocus();
      _isFocusRequested = false;
    }
  }

  void _requestFocus() {
    if (!_isFocusRequested && mounted) {
      _isFocusRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            widget.isSearching &&
            _searchFocusNode.hasFocus == false) {
          _logger.d('🎯 Executing focus request');
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _logger.d('🧹 GoodReceiptAppbarWidget dispose');
    _searchFocusNode.unfocus();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.d(
      '🎨 GoodReceiptAppbarWidget build, isSearching: ${widget.isSearching}',
    );

    return AppBar(
      actions: _buildAppBarActions(),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20.0, color: Colors.white),
        onPressed: widget.onBackPressed,
      ),
      backgroundColor: GoodReceiptConstant.primaryColor,
      elevation: 0,
      title: widget.isSearching
          ? _buildSearchField()
          : Text(
              "List Good Receipt",
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
    );
  }

  Widget _buildSearchField() {
    _logger.d(
      '🔍 Building search field, hasFocus: ${_searchFocusNode.hasFocus}',
    );

    return TextField(
      controller: widget.searchController,
      focusNode: _searchFocusNode,
      autofocus: false,
      decoration: const InputDecoration(
        hintText: 'Search GR ID, PO Number, Created By...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) {
        _logger.d(
          '📝 Search text changed: "${query.substring(0, query.length > 10 ? 10 : query.length)}..."',
        );
        widget.onSearchChanged?.call(query);
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (widget.isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            _logger.d('🧹 Clear search button ditekan');
            widget.onClearSearch();
          },
        ),
      ];
    }

    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: () {
              _logger.d('🔄 Refresh button ditekan');
              widget.onRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              _logger.d('🔍 Search button ditekan - Masuk mode search');
              widget.onStartSearch();
            },
          ),
        ],
      ),
    ];
  }
}

// checked
