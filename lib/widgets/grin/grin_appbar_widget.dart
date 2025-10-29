import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/grin/grin_constant.dart';
import 'package:wms_bctech/controllers/grin/grin_controller.dart';
import 'package:wms_bctech/widgets/grin/grin_search_widget.dart';

class GrinAppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final TextEditingController? searchController;
  final VoidCallback onBackPressed;
  final VoidCallback onClearSearch;
  final VoidCallback onRefresh;
  final VoidCallback onStartSearch;
  final ValueChanged<String>? onSearchChanged;
  final GrinController grinController;

  const GrinAppbarWidget({
    super.key,
    required this.isSearching,
    this.searchController,
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
  Widget build(BuildContext context) {
    return AppBar(
      actions: _buildAppBarActions(),
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20.0, color: Colors.white),
        onPressed: onBackPressed,
      ),
      backgroundColor: GrinConstants.primaryColor,
      elevation: 0,
      title: isSearching
          ? GrinSearchWidget(
              controller: searchController!,
              onChanged:
                  onSearchChanged ?? grinController.updateSearchQueryGrinPage,
            )
          : Text(
              "Good Receive IN",
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

  List<Widget> _buildAppBarActions() {
    if (isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: onClearSearch,
        ),
      ];
    }

    return [
      Row(
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onStartSearch,
          ),
        ],
      ),
    ];
  }
}
