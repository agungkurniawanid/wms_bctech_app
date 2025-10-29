import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/models/stock_take_detail_model.dart';
import 'package:wms_bctech/controllers/global_controller.dart';
import 'package:wms_bctech/controllers/stock_tick_controller.dart';
import 'package:wms_bctech/widgets/text_widget.dart';

class CountedPage extends StatefulWidget {
  final int index;

  const CountedPage({super.key, required this.index});

  @override
  State<CountedPage> createState() => _CountedPageState();
}

class _CountedPageState extends State<CountedPage> {
  final GlobalVM _globalVm = Get.find();
  final StockTickVM _stockTickVm = Get.find();

  final TextEditingController _searchController = TextEditingController();

  String _dropdownValue = 'All';
  String _searchQuery = '';
  bool _isSearching = false;

  static const List<String> _dropdownOptions = ['All', 'UU', 'QI', 'BLOCK'];
  static const Color _primaryColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _stockTickVm.tolistinput.value = _stockTickVm.tolistcounted
        .where((element) => element.createdBy == _globalVm.username.value)
        .toList();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearching() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
      _stockTickVm.searchValue.value = '';
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
      _stockTickVm.searchValue.value = newQuery;
    });
  }

  double _getConversionRate(StockTakeDetailModel item, String unitType) {
    final marmList = (item.marm ?? []).where((element) {
      final meinh = element.meinh ?? '';

      if (unitType == "KG") {
        return meinh == "KG";
      } else {
        return meinh != "KG" && meinh != "PAK";
      }
    }).toList();

    if (marmList.isEmpty) return 0.0;

    final firstUmrez = marmList.first.umrez;
    return double.tryParse(firstUmrez ?? '0') ?? 0.0;
  }

  double _calculateTotalQuantity(StockTakeDetailModel item, String unitType) {
    final filteredItems = _dropdownValue == "All"
        ? _stockTickVm.tolistforinputstocktake
              .where((element) => element.matnr == item.mATNR)
              .toList()
        : _stockTickVm.tolistforinputstocktake
              .where(
                (element) =>
                    element.matnr == item.mATNR &&
                    element.selectedChoice == _dropdownValue,
              )
              .toList();

    double total = 0.0;
    final conversionRate = _getConversionRate(item, unitType);

    for (final element in filteredItems) {
      final boxContribution = element.countBox * conversionRate;
      total += boxContribution + element.countBox;
    }

    return total;
  }

  int _calculateTotalPcs(StockTakeDetailModel item, String flag) {
    if (flag == "stock") {
      final items = _stockTickVm.tolistdocument[widget.index].detail
          .where((element) => element.mATNR == item.mATNR)
          .toList();
      return items.fold(0, (sum, element) => sum + element.insme.toInt());
    } else {
      final filteredItems = _dropdownValue == "All"
          ? _stockTickVm.tolistforinputstocktake
                .where(
                  (element) =>
                      element.matnr == item.mATNR &&
                      element.createdBy == _globalVm.username.value,
                )
                .toList()
          : _stockTickVm.tolistforinputstocktake
                .where(
                  (element) =>
                      element.matnr == item.mATNR &&
                      element.createdBy == _globalVm.username.value &&
                      element.selectedChoice == _dropdownValue,
                )
                .toList();

      return filteredItems.fold(
        0,
        (sum, element) => sum + element.countBun.toInt(),
      );
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
              _searchController.clear();
            }
          },
        ),
      ];
    }

    return [
      Row(
        children: [
          _buildDropdownFilter(),
          IconButton(icon: const Icon(Icons.search), onPressed: _startSearch),
        ],
      ),
    ];
  }

  Widget _buildDropdownFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _dropdownValue,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: _primaryColor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          items: _dropdownOptions.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (newValue) {
            setState(() => _dropdownValue = newValue!);
          },
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Container(
      width: double.infinity,
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HeaderItem(flex: 1, text: 'No', alignment: Alignment.centerLeft),
          _HeaderItem(flex: 2, text: 'Item', alignment: Alignment.centerLeft),
          _HeaderItem(flex: 1, text: 'BUN', alignment: Alignment.center),
          _HeaderItem(flex: 1, text: 'BOX', alignment: Alignment.center),
          _HeaderItem(flex: 1, text: 'KG', alignment: Alignment.center),
        ],
      ),
    );
  }

  Widget _buildListItem(StockTakeDetailModel item, int index) {
    final totalPcsPhysical = _calculateTotalPcs(item, "physical");
    final totalPcsStock = _calculateTotalPcs(item, "stock");
    final pcsDifference = totalPcsPhysical - totalPcsStock;

    final totalBoxQuantity = _calculateTotalQuantity(item, "Box");
    final boxConversionRate = _getConversionRate(item, "Box");
    final boxValue = boxConversionRate == 0
        ? 0.0
        : totalBoxQuantity / boxConversionRate;

    final totalKgQuantity = _calculateTotalQuantity(item, "KG");
    final kgConversionRate = _getConversionRate(item, "KG");
    final kgValue = kgConversionRate == 0
        ? 0.0
        : totalKgQuantity / kgConversionRate;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ListItemText(
                flex: 1,
                text: '${index + 1}',
                alignment: Alignment.centerLeft,
              ),
              _ListItemText(
                flex: 2,
                text: item.mAKTX,
                alignment: Alignment.centerLeft,
              ),
              _ListItemText(
                flex: 1,
                text: pcsDifference.toString(),
                alignment: Alignment.center,
              ),
              _ListItemText(
                flex: 1,
                text: boxValue.toStringAsFixed(1),
                alignment: Alignment.center,
              ),
              _ListItemText(
                flex: 1,
                text: kgValue.toStringAsFixed(1),
                alignment: Alignment.center,
              ),
            ],
          ),
        ),
        const Divider(thickness: 1.0, height: 1.0, color: Colors.grey),
      ],
    );
  }

  List<StockTakeDetailModel> _getFilteredList() {
    final document = _stockTickVm.tolistdocumentnosame.firstWhere(
      (element) => element.documentno == _stockTickVm.document.value,
    );

    List<StockTakeDetailModel> filteredList;

    if (_isSearching) {
      if (_searchQuery.isEmpty) {
        filteredList = [];
      } else {
        filteredList = document.detail
            .where(
              (element) => element.mAKTX.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
            )
            .toList();
      }
    } else {
      filteredList = document.detail
          .where((element) => element.checkboxValidation.value)
          .toList();
    }

    filteredList.sort((a, b) => a.mAKTX.compareTo(b.mAKTX));
    return filteredList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: _isSearching
              ? _buildSearchField()
              : TextWidget(text: "Counted", maxLines: 2, color: Colors.white),
        ),
        actions: _buildAppBarActions(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderRow(),
          const Divider(thickness: 1.0),
          Expanded(
            child: Obx(() {
              final filteredList = _getFilteredList();
              return ListView.builder(
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  return _buildListItem(filteredList[index], index);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeaderItem extends StatelessWidget {
  final int flex;
  final String text;
  final Alignment alignment;

  const _HeaderItem({
    required this.flex,
    required this.text,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _ListItemText extends StatelessWidget {
  final int flex;
  final String text;
  final Alignment alignment;

  const _ListItemText({
    required this.flex,
    required this.text,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
