import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/stock_take_model.dart';
import 'package:wms_bctech/pages/stock_take_header_page.dart';
import 'package:wms_bctech/controllers/stock_tick_controller.dart';
import 'package:wms_bctech/components/out_card_widget.dart';
import 'package:wms_bctech/components/text_widget.dart';

class StockTickPage extends StatefulWidget {
  const StockTickPage({super.key});

  @override
  State<StockTickPage> createState() => _StockTickPageState();
}

class _StockTickPageState extends State<StockTickPage> {
  final StockTickVM _stockTickVM = Get.find();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool allowBack = true;
  String searchQuery = '';
  List<StocktickModel> _originalStockList = [];

  @override
  void initState() {
    super.initState();
    _stockTickVM.listStock();
    _initializeData();
  }

  void _initializeData() {
    _originalStockList = List.from(_stockTickVM.toliststock);
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _filterStocks(newQuery);
    });
  }

  void _filterStocks(String search) {
    final query = search.toUpperCase();
    _stockTickVM.toliststock.value = _originalStockList
        .where((element) => element.lGORT.contains(query))
        .toList();
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
      searchQuery = '';
      _stockTickVM.toliststock.value = List.from(_originalStockList);
    });
  }

  void _clearSearchQuery() {
    if (_searchController.text.isEmpty) {
      _stopSearching();
      return;
    }
    _searchController.clear();
    _updateSearchQuery('');
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
        IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearchQuery),
      ];
    }

    return [
      IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
    ];
  }

  Widget _buildStockItem(StocktickModel stock) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return Container(
      padding: EdgeInsets.fromLTRB(16 * fem, 11 * fem, 17 * fem, 0 * fem),
      width: double.infinity,
      child: SizedBox(
        width: double.infinity,
        height: 90 * fem,
        child: Stack(
          children: [
            Positioned(
              left: 0 * fem,
              top: 0 * fem,
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
                          _buildLocationText(
                            stock.lGORT.isNotEmpty
                                ? stock.lGORT.join(', ')
                                : '-',
                            fem,
                            ffem,
                          ),
                          _buildLastTransactionText(stock.updated, fem, ffem),
                          _buildOnlineIndicator(fem),
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

  Widget _buildLocationText(String location, double fem, double ffem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0 * fem, 1 * fem, 29 * fem, 0 * fem),
      child: Text(
        location,
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

  Widget _buildLastTransactionText(String updated, double fem, double ffem) {
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
              text: updated,
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

  Widget _buildOnlineIndicator(double fem) {
    return Container(
      padding: EdgeInsets.fromLTRB(0 * fem, 0 * fem, 0 * fem, 1 * fem),
      width: 14 * fem,
      height: 14 * fem,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7 * fem),
        color: Colors.red,
      ),
    );
  }

  Widget _buildNavigationIcon(double fem) {
    return Container(
      margin: EdgeInsets.fromLTRB(5 * fem, 0 * fem, 0 * fem, 0 * fem),
      width: 11 * fem,
      height: 19.39 * fem,
      child: Image.asset(
        'data/images/vector-1HV.png',
        width: 11 * fem,
        height: 19.39 * fem,
      ),
    );
  }

  void _onStockItemTap(StocktickModel stock) {
    _stockTickVM.choicelocation = stock.lGORT;
    Get.to(() => StockTakeHeader(stock));
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
                    text: "Stock Take",
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
                  child: Obx(() {
                    return ListView.builder(
                      shrinkWrap: true,
                      scrollDirection: Axis.vertical,
                      itemCount: _stockTickVM.toliststock.length,
                      itemBuilder: (BuildContext context, int index) {
                        final stock = _stockTickVM.toliststock[index];
                        return GestureDetector(
                          child: _buildStockItem(stock),
                          onTap: () => _onStockItemTap(stock),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
