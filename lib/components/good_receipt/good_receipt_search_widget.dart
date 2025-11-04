import 'package:flutter/material.dart';

class GoodReceiptSearchWidgets extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const GoodReceiptSearchWidgets({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search Good Receipt ID, PO Number, Created By...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: onChanged,
    );
  }
}
