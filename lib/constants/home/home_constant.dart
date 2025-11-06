import 'package:flutter/material.dart';

class HomeDataConstant {
  static const List<Map<String, dynamic>> listChoice = [
    {'id': 1, 'label': 'FZ', 'labelName': 'Frozen', 'color': Colors.blue},
    {'id': 2, 'label': 'CH', 'labelName': 'Chemical', 'color': Colors.green},
    {'id': 10, 'label': 'ALL', 'labelName': 'All', 'color': Colors.orange},
  ];

  static const List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.login, 'title': 'In', 'color': Colors.blue},
    {'icon': Icons.logout, 'title': 'Out', 'color': Colors.green},
    {'icon': Icons.inventory_2, 'title': 'Stock\nTake', 'color': Colors.orange},
    {'icon': Icons.more_horiz, 'title': 'More', 'color': Colors.purple},
  ];
}

// checked
