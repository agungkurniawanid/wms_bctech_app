import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/stock_check_model.dart';
import 'package:wms_bctech/pages/detail_pid_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/in/in_controller.dart';
import 'package:wms_bctech/controllers/pid_controller.dart';
import 'package:wms_bctech/controllers/weborder_controller.dart';
import 'package:wms_bctech/components/out_card_widget.dart';
import 'package:wms_bctech/components/text_widget.dart';

class PidPage extends StatefulWidget {
  const PidPage({super.key});

  @override
  State<PidPage> createState() => _PidPageState();
}

class _PidPageState extends State<PidPage> {
  final PidViewModel _pidVM = Get.find();
  final InVM inVM = Get.find();
  final WeborderVM weborderVM = Get.find();
  final GlobalVM globalVM = Get.find();

  final List<StockModel> _listStockModel = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final GlobalKey srKey = GlobalKey();
  final GlobalKey p4Key = GlobalKey();

  bool allowPop = true;
  bool _isSearching = false;
  bool leading = true;
  String choice = "SR";
  String scannedData = '';
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pidVM.onReady();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: allowPop,
      child: SafeArea(
        child: Scaffold(
          appBar: _buildAppBar(),
          backgroundColor: kWhiteColor,
          body: _buildBody(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      actions: _buildAppBarActions(),
      automaticallyImplyLeading: false,
      backgroundColor: Colors.red,
      title: _isSearching ? _buildSearchField() : _buildTitle(),
      centerTitle: true,
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _handleClearSearch,
        ),
      ];
    }

    return [
      IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
    ];
  }

  Widget _buildTitle() {
    return TextWidget(
      text: "PID",
      maxLines: 2,
      fontSize: 20,
      color: Colors.white,
    );
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

  Widget _buildBody() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Expanded(child: _buildStockList())],
      ),
    );
  }

  Widget _buildStockList() {
    return Obx(() {
      return ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: _pidVM.tolistpid.length,
        itemBuilder: (BuildContext context, int index) {
          return _buildStockCard(_pidVM.tolistpid[index], index);
        },
      );
    });
  }

  Widget _buildStockCard(StockModel stock, int index) {
    return GestureDetector(
      onTap: () => _navigateToDetailPage(index),
      child: _StockCard(stock: stock),
    );
  }

  void _navigateToDetailPage(int index) {
    Get.to(() => DetailPidPage(index, "pidPage"));
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _performSearch(newQuery);
    });
  }

  void _performSearch(String search) {
    _pidVM.tolistpid.clear();
    search = search.toUpperCase();

    final filteredList = _listStockModel
        .where((element) => (element.recordid?.contains(search) ?? false))
        .toList();

    _pidVM.tolistpid.addAll(filteredList);
  }

  void _startSearch() {
    setState(() {
      _listStockModel.clear();
      _listStockModel.addAll(_pidVM.tolistpid);
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();
    setState(() {
      _isSearching = false;
    });
  }

  void _handleClearSearch() {
    if (_searchController.text.isEmpty) {
      _stopSearching();
      return;
    }
    _clearSearchQuery();
  }

  void _clearSearchQuery() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _pidVM.tolistpid.clear();
      _pidVM.tolistpid.addAll(_listStockModel);
    });
  }
}

class _StockCard extends StatelessWidget {
  final StockModel stock;

  const _StockCard({required this.stock});

  @override
  Widget build(BuildContext context) {
    final double baseWidth = 360;
    final double fem = MediaQuery.of(context).size.width / baseWidth;
    final double ffem = fem * 0.97;

    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10 * fem),
      padding: EdgeInsets.fromLTRB(20 * fem, 30 * fem, 3 * fem, 15 * fem),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x3f000000),
            offset: Offset(0 * fem, 4 * fem),
            blurRadius: 5 * fem,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHeaderRow(stock, fem, ffem),
          if (stock.recordid != "HQ") _buildStatusRow(stock, fem, ffem),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(StockModel stock, double fem, double ffem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRecordId(stock, fem, ffem),
        _buildLastTransaction(stock, fem, ffem),
        _buildStatusIndicator(stock, fem),
        _buildNavigationIcon(fem),
      ],
    );
  }

  Widget _buildRecordId(StockModel stock, double fem, double ffem) {
    final String recordId = stock.recordid ?? '';
    final String displayText = recordId.length > 9
        ? '${recordId.substring(0, 8)}\n${recordId.substring(8)}'
        : recordId;

    final double fontSize = recordId.length > 2 ? 15 * ffem : 18 * ffem;

    return Container(
      margin: EdgeInsets.fromLTRB(0, 1 * fem, 10 * fem, 0),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: safeGoogleFont(
          'Roboto',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          height: 1.1725 * ffem / fem,
          color: const Color(0xfff44236),
        ),
      ),
    );
  }

  Widget _buildLastTransaction(StockModel stock, double fem, double ffem) {
    final GlobalVM globalVM = Get.find();
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
              text: _getFormattedUpdateTime(stock, globalVM),
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

  String _getFormattedUpdateTime(StockModel stock, GlobalVM globalVM) {
    final updatedAt = stock.formattedUpdatedAt ?? '';

    if (updatedAt.contains("Today") || updatedAt.contains("Yesterday")) {
      return updatedAt;
    }

    return globalVM.stringToDateWithTime(updatedAt);
  }

  Widget _buildStatusIndicator(StockModel stock, double fem) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 1 * fem),
      width: 14 * fem,
      height: 14 * fem,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7 * fem),
        color: _getStatusColor(stock.color ?? ''),
      ),
    );
  }

  Color _getStatusColor(String color) {
    switch (color) {
      case "GREEN":
        return Colors.green;
      case "YELLOW":
        return Colors.yellow;
      default:
        return Colors.red;
    }
  }

  Widget _buildNavigationIcon(double fem) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 20 * fem, 0),
      width: 11 * fem,
      height: 19.39 * fem,
      child: Image.asset(
        'data/images/vector-1HV.png',
        width: 11 * fem,
        height: 19.39 * fem,
      ),
    );
  }

  Widget _buildStatusRow(StockModel stock, double fem, double ffem) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(0, 1 * fem, 10 * fem, 0),
          child: Text(
            'Status : ${stock.isApprove}',
            textAlign: TextAlign.center,
            style: safeGoogleFont(
              'Roboto',
              fontSize: 18 * ffem,
              fontWeight: FontWeight.w600,
              height: 1.1725 * ffem / fem,
              color: stock.isApprove == "Counted"
                  ? Colors.green
                  : const Color(0xfff44236),
            ),
          ),
        ),
      ],
    );
  }
}
