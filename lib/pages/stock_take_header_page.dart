import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/config/database_config.dart';
import 'package:wms_bctech/config/global_variable_config.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/models/category_model.dart';
import 'package:wms_bctech/models/item_choice_model.dart';
import 'package:wms_bctech/models/stock_take_model.dart';
import 'package:wms_bctech/pages/stock_take_detail_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/stock_tick_controller.dart';
import 'package:wms_bctech/components/out_card_widget.dart';
import 'package:wms_bctech/components/text_widget.dart';
import 'package:logger/logger.dart';

class StockTakeHeader extends StatefulWidget {
  final StocktickModel stocktake;
  const StockTakeHeader(this.stocktake, {super.key});

  @override
  State<StockTakeHeader> createState() => _StockTakeHeaderState();
}

class _StockTakeHeaderState extends State<StockTakeHeader> {
  static const double _baseWidth = 360.0;

  final GlobalVM _globalVm = Get.find();
  final StockTickVM _stockTickVm = Get.find();

  late double _fem;
  late double _ffem;

  final List<ItemChoice> _statusChoices = [];
  final List<ItemChoice> _categoryChoices = [];
  final List<StocktickModel> _stockLocal = [];

  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey srKey = GlobalKey();

  bool allowBack = true;
  bool _isSearching = false;
  int _selectedStatusId = 1;
  String searchQuery = '';
  String _werks = '';
  String _lgort = '';

  @override
  void initState() {
    super.initState();
    _initializeMetrics();
    _getChoiceChips();
  }

  void _initializeMetrics() {
    _fem = MediaQuery.of(context).size.width / _baseWidth;
    _ffem = _fem * 0.97;
  }

  void _parseLGORT() {
    if (widget.stocktake.lGORT.isNotEmpty) {
      final String item = widget.stocktake.lGORT.first;
      final cleanedItem = item.replaceAll(RegExp(r'[\[\]]'), '').trim();
      final parts = cleanedItem.split('-');

      if (parts.length == 2) {
        _werks = parts[0];
        _lgort = parts[1];
      }
    }
  }

  Future<void> _getChoiceChips() async {
    try {
      final List<Category> categories = await DatabaseHelper.db
          .getCategoryWithRole("STOCKTAKE");

      setState(() {
        for (final category in categories) {
          _categoryChoices.add(
            ItemChoice(
              id: _categoryChoices.length + 1,
              label: category.inventoryGroupId,
              labelName: category.inventoryGroupId,
            ),
          );
        }

        _statusChoices.addAll([
          ItemChoice(id: 1, label: "N", labelName: "In Progress"),
          ItemChoice(id: 2, label: "Y", labelName: "Completed"),
        ]);

        _stockTickVm.choiceforchip = _statusChoices.first.label ?? '';
        _stockTickVm.onReady();
      });
    } catch (e) {
      _showError('Failed to load categories: $e');
    }
  }

  void _startSearch() {
    setState(() {
      _stockLocal.clear();
      _stockLocal.addAll(_stockTickVm.tolistdocument);
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
      _stockTickVm.tolistdocument.assignAll(_stockLocal);
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
      _searchDocuments(newQuery);
    });
  }

  void _searchDocuments(String search) {
    try {
      final filteredList = _stockLocal
          .where((element) => element.documentno.contains(search.toUpperCase()))
          .toList();

      _stockTickVm.tolistdocument.assignAll(filteredList);
    } catch (e) {
      _showError('Search failed: $e');
      _stockTickVm.tolistdocument.assignAll([]);
    }
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
            } else {
              _clearSearchQuery();
            }
          },
        ),
      ];
    }

    return [
      IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
    ];
  }

  Widget _buildStatusChoiceChips() {
    return Wrap(
      spacing: 25,
      children: _statusChoices
          .map(
            (choice) => ChoiceChip(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              labelStyle: TextStyle(
                fontSize: 16 * _ffem,
                color: _selectedStatusId == choice.id
                    ? Colors.white
                    : Colors.white,
              ),
              backgroundColor: Colors.grey,
              label: Text(choice.labelName ?? ''),
              selected: _selectedStatusId == choice.id,
              onSelected: (_) => _onStatusSelected(choice),
              selectedColor: const Color(0xfff44236),
              elevation: 10,
            ),
          )
          .toList(),
    );
  }

  void _onStatusSelected(ItemChoice choice) {
    setState(() {
      _selectedStatusId = choice.id ?? 0;
      _stockTickVm.choiceforchip = choice.label ?? '';
      _stockTickVm.onReady();
    });
  }

  Widget _buildDocumentCard(StocktickModel document) {
    return Container(
      margin: EdgeInsets.fromLTRB(5 * _fem, 0, 10 * _fem, 10 * _fem),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 13 * _fem),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8 * _fem),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x3f000000),
                  offset: Offset(0 * _fem, 4 * _fem),
                  blurRadius: 5 * _fem,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDocumentHeader(document),
                _buildDocumentInfo(document),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader(StocktickModel document) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 1.66 * _fem),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildDocumentNumber(document),
          _buildStatusAndArrow(document),
        ],
      ),
    );
  }

  Widget _buildDocumentNumber(StocktickModel document) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 12 * _fem, 13.34 * _fem),
      width: 130 * _fem,
      height: 38 * _fem,
      decoration: const BoxDecoration(
        color: Color(0xfff44236),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Center(
        child: Text(
          document.documentno,
          style: _buildTextStyle(16, FontWeight.w600, Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatusAndArrow(StocktickModel document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(60 * _fem, 0, 25 * _fem, 10.34 * _fem),
          child: Text(
            document.isapprove == "Y" ? 'Completed' : '',
            style: _buildTextStyle(
              16,
              FontWeight.w600,
              const Color(0xff2d2d2d),
            ),
          ),
        ),
        SizedBox(
          width: 11 * _fem,
          height: 19.39 * _fem,
          child: Image.asset(
            'data/images/vector-1HV.png',
            width: 11 * _fem,
            height: 19.39 * _fem,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentInfo(StocktickModel document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoText('Created By:   ${document.createdby}'),
        _buildInfoText('Created At : ${document.created}'),
      ],
    );
  }

  Widget _buildInfoText(String text) {
    return Container(
      margin: EdgeInsets.fromLTRB(12 * _fem, 0, 0, 0),
      child: Text(
        text,
        style: _buildTextStyle(16, FontWeight.w600, const Color(0xff2d2d2d)),
      ),
    );
  }

  TextStyle _buildTextStyle(
    double fontSize,
    FontWeight fontWeight,
    Color color,
  ) {
    return safeGoogleFont(
      'Roboto',
      fontSize: fontSize * _ffem,
      fontWeight: fontWeight,
      height: 1.1725 * _ffem / _fem,
      color: color,
    );
  }

  Future<void> _showCreateDocumentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: SizedBox(
              height: MediaQuery.of(context).size.height / 2.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildWarningIcon(),
                  _buildDialogMessage(),
                  _buildDialogButtons(setState),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWarningIcon() {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 1 * _fem, 15.5 * _fem),
      width: 35 * _fem,
      height: 35 * _fem,
      child: Image.asset(
        'data/images/mdi-warning-circle-vJo.png',
        width: 35 * _fem,
        height: 35 * _fem,
      ),
    );
  }

  Widget _buildDialogMessage() {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 48 * _fem),
      constraints: BoxConstraints(maxWidth: 256 * _fem),
      child: Text(
        'Are you sure to create a new stock take document based on current stock?',
        textAlign: TextAlign.center,
        style: _buildTextStyle(16, FontWeight.w600, const Color(0xff2d2d2d)),
      ),
    );
  }

  Widget _buildDialogButtons(StateSetter setState) {
    return SizedBox(
      width: double.infinity,
      height: 25 * _fem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [_buildCancelButton(), _buildConfirmButton(setState)],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        margin: EdgeInsets.fromLTRB(20 * _fem, 0, 16 * _fem, 0),
        padding: EdgeInsets.fromLTRB(24 * _fem, 5 * _fem, 25 * _fem, 5 * _fem),
        height: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xfff44236)),
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * _fem),
        ),
        child: Center(
          child: SizedBox(
            width: 30 * _fem,
            height: 30 * _fem,
            child: Image.asset(
              'data/images/cancel-viF.png',
              width: 30 * _fem,
              height: 30 * _fem,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(StateSetter setState) {
    return GestureDetector(
      onTap: _createNewDocument,
      child: Container(
        padding: EdgeInsets.fromLTRB(24 * _fem, 5 * _fem, 25 * _fem, 5 * _fem),
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xff2cab0c),
          borderRadius: BorderRadius.circular(12 * _fem),
          boxShadow: [
            BoxShadow(
              color: const Color(0x3f000000),
              offset: Offset(0 * _fem, 4 * _fem),
              blurRadius: 2 * _fem,
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 30 * _fem,
            height: 30 * _fem,
            child: Image.asset(
              'data/images/check-circle-fg7.png',
              width: 30 * _fem,
              height: 30 * _fem,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createNewDocument() async {
    try {
      EasyLoading.show(
        status: 'Loading Create Document',
        maskType: EasyLoadingMaskType.black,
      );

      _parseLGORT();
      await _stockTickVm.getStock(_lgort, _werks, _globalVm.username.value);

      EasyLoading.dismiss();
      Get.back();
    } catch (e) {
      EasyLoading.dismiss();
      _showError('Failed to create document: $e');
    }
  }

  void _showError(String message) {
    Logger().e(message);
  }

  Widget _buildDocumentList() {
    final filteredDocuments = _stockTickVm.tolistdocument
        .where((element) => element.isapprove == _stockTickVm.choiceforchip)
        .toList();

    if (filteredDocuments.isEmpty) {
      return _buildEmptyState();
    }

    return Expanded(
      child: Obx(
        () => ListView.builder(
          controller: _controller,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: filteredDocuments.length,
          itemBuilder: (BuildContext context, int index) {
            final document = filteredDocuments[index];
            return GestureDetector(
              onTap: () => _navigateToDetail(document, index),
              child: _buildDocumentCard(document),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: Image.asset(
              'data/images/undrawnodatarekwbl-1-1.png',
              fit: BoxFit.cover,
            ),
          ),
          TextWidget(text: "No Data", fontSize: 15),
        ],
      ),
    );
  }

  void _navigateToDetail(StocktickModel document, int index) {
    _stockTickVm.searchValue.value = '';
    Get.to(() => StockTakeDetail(document, index, document.documentno));
  }

  void _handleBackPress() {
    GlobalVar.choicecategory = _globalVm.choicecategory.value;
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    _initializeMetrics();

    return PopScope(
      canPop: allowBack,
      child: SafeArea(
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: _showCreateDocumentDialog,
            backgroundColor: Colors.red,
            child: Icon(Icons.add),
          ),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              iconSize: 20.0,
              onPressed: _handleBackPress,
            ),
            backgroundColor: Colors.red,
            title: Padding(
              padding: const EdgeInsets.only(right: 5),
              child: _isSearching
                  ? _buildSearchField()
                  : TextWidget(
                      text: widget.stocktake.lGORT.isNotEmpty
                          ? widget.stocktake.lGORT.first
                          : "Stock Take",
                      maxLines: 2,
                      fontSize: 18 * _ffem,
                      color: Colors.white,
                    ),
            ),
            actions: _buildAppBarActions(),
            centerTitle: true,
          ),
          backgroundColor: kWhiteColor,
          body: Container(
            padding: const EdgeInsets.only(bottom: 25, left: 5),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 5),
                _buildStatusChoiceChips(),
                _buildDocumentList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
