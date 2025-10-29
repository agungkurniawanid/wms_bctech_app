import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wms_bctech/constants/theme_constant.dart';
import 'package:wms_bctech/pages/home/home_page.dart';
import 'package:wms_bctech/pages/profile/profile_page.dart';
import 'package:wms_bctech/controllers/global_controller.dart';

class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({super.key});

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigation>
    with SingleTickerProviderStateMixin {
  final GlobalVM globalVM = Get.find<GlobalVM>();
  late final TabController _tabController;
  late final PageController _pageController;

  final RxInt _selectedIndex = 0.obs;

  final List<Widget> _pages = const [
    HomePage(key: PageStorageKey('Page1')),
    ProfilePage(key: PageStorageKey('Page2')),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _pages.length,
      vsync: this,
      initialIndex: _selectedIndex.value,
    );
    _pageController = PageController(initialPage: _selectedIndex.value);
    _tabController.addListener(_handleTabSelection);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemStatusBarContrastEnforced: false,
      ),
    );
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      final newIndex = _tabController.index;
      _selectedIndex.value = newIndex;
      _pageController.jumpToPage(newIndex);
      EasyLoading.dismiss();
    }
  }

  void _onItemTapped(int index) {
    _tabController.animateTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (_tabController.index != index) {
      _tabController.index = index;
      _selectedIndex.value = index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _pageController.dispose();
    _selectedIndex.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = hijauGojek;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Obx(
          () => _BottomNavigationBar(
            currentIndex: _selectedIndex.value,
            primaryColor: primaryColor,
            onItemTapped: _onItemTapped,
          ),
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Color primaryColor;
  final Function(int) onItemTapped;

  const _BottomNavigationBar({
    required this.currentIndex,
    required this.primaryColor,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const itemCount = 2;
    final itemWidth = screenWidth / itemCount;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left:
                currentIndex * itemWidth +
                (itemWidth / 2) -
                (itemWidth * 0.3) / 2,
            top: 0,
            child: Container(
              width: itemWidth * 0.3,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    primaryColor,
                    primaryColor.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _BottomNavItem(
                index: 0,
                inactiveIcon: FontAwesomeIcons.house,
                activeIcon: FontAwesomeIcons.solidHouse,
                label: 'Home',
                isActive: currentIndex == 0,
                primaryColor: primaryColor,
                onTap: onItemTapped,
              ),
              _BottomNavItem(
                index: 1,
                inactiveIcon: FontAwesomeIcons.user,
                activeIcon: FontAwesomeIcons.solidUser,
                label: 'Profile',
                isActive: currentIndex == 1,
                primaryColor: primaryColor,
                onTap: onItemTapped,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final int index;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final Color primaryColor;
  final Function(int) onTap;

  const _BottomNavItem({
    required this.index,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            FaIcon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'MonaSans',
                color: isActive ? primaryColor : Colors.grey,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
