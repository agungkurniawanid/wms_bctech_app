import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wms_bctech/constants/good_receipt/good_receipt_constant.dart';

class GoodReceiptHeaderWidget extends StatelessWidget {
  final RxInt itemCount;
  final String? selectedSort;
  final List<String> sortList;
  final Function(String?) onSortChanged;
  final String itemName;
  final RxList? reactiveList;

  const GoodReceiptHeaderWidget({
    super.key,
    required this.itemCount,
    required this.selectedSort,
    required this.sortList,
    required this.onSortChanged,
    this.itemName = 'data',
    this.reactiveList,
  });

  GoodReceiptHeaderWidget.fromReactiveList({
    super.key,
    required this.reactiveList,
    required this.selectedSort,
    required this.sortList,
    required this.onSortChanged,
    this.itemName = 'data',
  }) : itemCount = RxInt(0);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: GoodReceiptConstant.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${reactiveList != null ? reactiveList!.length : itemCount.value} $itemName shown',
              style: TextStyle(
                fontFamily: 'MonaSans',
                fontSize: 14,
                color: GoodReceiptConstant.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            _buildSortDropdown(),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: GoodReceiptConstant.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.sort, color: GoodReceiptConstant.primaryColor, size: 18),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              icon: Icon(
                Icons.arrow_drop_down,
                color: GoodReceiptConstant.primaryColor,
              ),
              hint: Text(
                'Sort By',
                style: TextStyle(
                  fontFamily: 'MonaSans',
                  color: GoodReceiptConstant.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              value: selectedSort,
              items: sortList
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontFamily: 'MonaSans',
                          color: GoodReceiptConstant.textPrimaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onSortChanged,
            ),
          ),
        ],
      ),
    );
  }
}
