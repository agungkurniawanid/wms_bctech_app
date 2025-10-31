// todo:✅ Clean Code checked
import 'package:flutter/material.dart';

class HomeMoreOptionsBottomSheetWidget extends StatefulWidget {
  const HomeMoreOptionsBottomSheetWidget({super.key});

  @override
  State<HomeMoreOptionsBottomSheetWidget> createState() =>
      _HomeMoreOptionsBottomSheetWidgetState();
}

class _HomeMoreOptionsBottomSheetWidgetState
    extends State<HomeMoreOptionsBottomSheetWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'More Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Opening Settings')));
            },
          ),

          ListTile(
            leading: Icon(Icons.help),
            title: Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Opening Help & Support')));
            },
          ),

          ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Opening About')));
            },
          ),
        ],
      ),
    );
  }
}
