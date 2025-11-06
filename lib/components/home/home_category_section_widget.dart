import 'package:flutter/material.dart';
import 'package:wms_bctech/constants/home/home_constant.dart';

class HomeCategorySectionWidget extends StatefulWidget {
  const HomeCategorySectionWidget({super.key});

  @override
  State<HomeCategorySectionWidget> createState() =>
      _HomeCategorySectionWidgetState();
}

class _HomeCategorySectionWidgetState extends State<HomeCategorySectionWidget> {
  int idPeriodSelected = 1;
  String selectedCategory = 'All';
  void _handleCategorySelection(int id, String label) {
    setState(() {
      idPeriodSelected = id;
      selectedCategory = label;
    });
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HomeDataConstant.listChoice.map((choice) {
          final isSelected = idPeriodSelected == choice['id'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                choice['labelName'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: Colors.grey[100],
              selected: isSelected,
              selectedColor: choice['color'],
              checkmarkColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              shadowColor: choice['color']?.withValues(alpha: 0.5),
              onSelected: (_) =>
                  _handleCategorySelection(choice['id'], choice['label']),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? choice['color'] ?? Colors.transparent
                      : Colors.grey[300]!,
                  width: isSelected ? 0 : 1,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              labelPadding: EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [const SizedBox(height: 8), _buildCategoryChips()],
        ),
      ),
    );
  }
}

// checked
