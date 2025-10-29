import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/stock_check_model.dart';
import 'package:wms_bctech/pages/detail_stock_check_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in_controller.dart';
import 'package:wms_bctech/controllers/stock_check_controlller.dart';
import 'package:wms_bctech/controllers/weborder_controller.dart';
import 'package:wms_bctech/widgets/out_card_widget.dart';
import 'package:wms_bctech/widgets/text_widget.dart';

class StockCheckPage extends StatefulWidget {
  const StockCheckPage({super.key});

  @override
  State<StockCheckPage> createState() => _StockCheckPageState();
}

class _StockCheckPageState extends State<StockCheckPage> {
  final StockCheckVM _stockCheckVM = Get.find();
  final InVM inVM = Get.find();
  final WeborderVM weborderVM = Get.find();
  final GlobalVM _globalVM = Get.find();

  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  final List<StockModel> _originalStockList = [];
  final GlobalKey _scrollKey = GlobalKey();
  final GlobalKey p4Key = GlobalKey();

  bool _isSearching = false;
  bool allowBack = true;
  String searchQuery = '';
  String selectedChoice = "SR";
  String scannedData = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController();
    _stockCheckVM.onReady();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _filterStocks(newQuery);
    });
  }

  void _filterStocks(String search) {
    _stockCheckVM.toliststock.clear();
    final searchTerm = search.toUpperCase();

    final filteredList = _originalStockList
        .where((element) => (element.location?.contains(searchTerm) ?? false))
        .toList();

    _stockCheckVM.toliststock.addAll(filteredList);
  }

  void _startSearch() {
    setState(() {
      _originalStockList.clear();
      _originalStockList.addAll(_stockCheckVM.toliststock);
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();
  }

  void _clearSearchQuery() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      searchQuery = '';

      _stockCheckVM.toliststock.clear();
      _stockCheckVM.toliststock.addAll(_originalStockList);
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white30),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              _stopSearching();
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }

    return [
      IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
    ];
  }

  Widget _buildStockCard(StockModel stock) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(16 * fem, 11 * fem, 17 * fem, 0),
      width: double.infinity,
      child: SizedBox(
        width: double.infinity,
        height: 90 * fem,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: SizedBox(
                width: 325 * fem,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        21 * fem,
                        23 * fem,
                        20 * fem,
                        22 * fem,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10 * fem),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x3f000000),
                            offset: Offset(0 * fem, 4 * fem),
                            blurRadius: 5 * fem,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildLocationText(stock, ffem, fem),
                          _buildLastTransactionText(stock, ffem, fem),
                          _buildStatusIndicator(stock, fem),
                          _buildNavigationIcon(fem),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationText(StockModel stock, double ffem, double fem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 1 * fem, 29 * fem, 0),
      child: Text(
        stock.location ?? '',
        textAlign: TextAlign.center,
        style: safeGoogleFont(
          'Roboto',
          fontSize: 18 * ffem,
          fontWeight: FontWeight.w600,
          height: 1.1725 * ffem / fem,
          color: const Color(0xfff44236),
        ),
      ),
    );
  }

  Widget _buildLastTransactionText(StockModel stock, double ffem, double fem) {
    return Container(
      constraints: BoxConstraints(maxWidth: 200 * fem),
      child: RichText(
        text: TextSpan(
          style: safeGoogleFont(
            'Roboto',
            fontSize: 16 * ffem,
            fontWeight: FontWeight.w600,
            height: 1.1725 * ffem / fem,
            color: const Color(0xff2d2d2d),
          ),
          children: [
            const TextSpan(text: 'Last Transaction: \n'),
            TextSpan(
              text: _formatTransactionDate(stock),
              style: safeGoogleFont(
                'Roboto',
                fontSize: 16 * ffem,
                fontWeight: FontWeight.w600,
                height: 1.1725 * ffem / fem,
                color: const Color(0xff9a9a9a),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTransactionDate(StockModel stock) {
    final updatedAt = stock.formattedUpdatedAt ?? '';

    if (updatedAt.contains("Today") || updatedAt.contains("Yesterday")) {
      return updatedAt;
    }

    return _globalVM.stringToDateWithTime(updatedAt);
  }

  Widget _buildStatusIndicator(StockModel stock, double fem) {
    Color statusColor;
    switch (stock.color) {
      case "GREEN":
        statusColor = Colors.green;
        break;
      case "YELLOW":
        statusColor = Colors.yellow;
        break;
      default:
        statusColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 1 * fem),
      width: 14 * fem,
      height: 14 * fem,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7 * fem),
        color: statusColor,
      ),
    );
  }

  Widget _buildNavigationIcon(double fem) {
    return Container(
      margin: EdgeInsets.fromLTRB(5 * fem, 0, 0, 0),
      width: 11 * fem,
      height: 19.39 * fem,
      child: Image.asset(
        'data/images/vector-1HV.png',
        width: 11 * fem,
        height: 19.39 * fem,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: allowBack,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            actions: _buildAppBarActions(),
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 20.0),
              onPressed: () => Get.back(),
            ),
            backgroundColor: Colors.red,
            title: _isSearching
                ? _buildSearchField()
                : TextWidget(
                    text: "Stock Check",
                    maxLines: 2,
                    fontSize: 20,
                    color: Colors.white,
                  ),
            centerTitle: true,
          ),
          backgroundColor: kWhiteColor,
          body: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                      key: _scrollKey,
                      controller: _scrollController,
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: _stockCheckVM.toliststock.length,
                      itemBuilder: (BuildContext context, int index) {
                        final stock = _stockCheckVM.toliststock[index];
                        return GestureDetector(
                          child: _buildStockCard(stock),
                          onTap: () {
                            Get.to(
                              () =>
                                  DetailStockCheckPage(index, "stockcheckpage"),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
