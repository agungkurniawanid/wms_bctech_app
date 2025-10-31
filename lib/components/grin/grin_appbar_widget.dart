import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:wms_bctech/components/grin/grin_search_widget.dart';
import 'package:wms_bctech/constants/grin/grin_constant.dart';
import 'package:wms_bctech/controllers/grin/grin_controller.dart';

class GrinAppbarWidget extends StatefulWidget implements PreferredSizeWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final VoidCallback onBackPressed;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback onStartSearch;
  final ValueChanged<String>? onSearchChanged;
  final GrinController grinController;

  const GrinAppbarWidget({
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
  State<GrinAppbarWidget> createState() => _GrinAppbarWidgetState();
}

class _GrinAppbarWidgetState extends State<GrinAppbarWidget> {
  final FocusNode _searchFocusNode = FocusNode();
  bool _localSearching = false;

  @override
  void initState() {
    super.initState();
    // ✅ Fokuskan search field jika langsung dalam mode search
    if (widget.isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant GrinAppbarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ FIXED: Logic yang lebih sederhana dan konsisten
    if (widget.isSearching && !oldWidget.isSearching) {
      // Baru masuk mode search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    } else if (!widget.isSearching && oldWidget.isSearching) {
      // Keluar dari mode search
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 GrinAppbarWidget build, isSearching: $_localSearching');

    return AppBar(
      actions: _buildAppBarActions(),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20.0, color: Colors.white),
        onPressed: widget.onBackPressed,
      ),
      backgroundColor: GrinConstants.primaryColor,
      elevation: 0,
      title:
          widget
              .isSearching // ✅ GUNAKAN widget.isSearching
          ? _buildSearchField()
          : Text(
              "List Good Receive",
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
    return TextField(
      controller: widget.searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search GR ID, PO Number, Created By...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged:
          widget.onSearchChanged ??
          widget.grinController.updateSearchQueryGrinPage,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (widget.isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () {
            debugPrint('🧹 Clear search button ditekan');
            widget.searchController.clear();
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
              debugPrint('🔄 Refresh button ditekan');
              widget.onRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              debugPrint('🔍 Search button ditekan - Masuk mode search');
              widget.onStartSearch();
            },
          ),
        ],
      ),
    ];
  }
}
