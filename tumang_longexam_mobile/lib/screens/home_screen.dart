import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'item_screen.dart';
import 'archive_screen.dart';
import 'wishlist_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_text.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.username = ''});
  final String username;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final UserService _userService = UserService();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getUserData();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool get _isAdmin => _userData['type']?.toString().toLowerCase() == 'admin';
  bool get _isViewer => _userData['type']?.toString().toLowerCase() == 'viewer';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Define available pages based on user type
    final List<Widget> pages = [
      const ItemScreen(),
      if (!_isViewer) const ArchiveScreen(), // Hide archive for viewers
      if (_isViewer) const WishlistScreen(), // Only show wishlist for viewers
      const ProfileScreen(),
    ];

    // Define tab labels based on user type
    final List<String> tabLabels = [
      _isViewer ? 'Items' : 'List of Items', // Change title for admin/editor
      if (!_isViewer) 'Archive', // Hide archive for viewers
      if (_isViewer) 'Wishlist', // Only show wishlist for viewers
      'Profile',
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 2,
          title: CustomText(
            text: _selectedIndex < tabLabels.length
                ? tabLabels[_selectedIndex]
                : 'Home',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            if (_isAdmin) // Show admin approval button for admins
              IconButton(
                icon: Icon(Icons.admin_panel_settings, size: 24.sp),
                onPressed: () =>
                    Navigator.pushNamed(context, '/admin-approval'),
                tooltip: 'Pending Approvals',
              ),
            // Show inquiry icon for all authenticated users (admin, editor, viewer)
            IconButton(
              icon: Icon(Icons.help_outline, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/inquiries'),
              tooltip: 'My Inquiries',
            ),
            IconButton(
              icon: Icon(Icons.settings, size: 24.sp),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          children: pages,
          onPageChanged: (page) {
            setState(() {
              _selectedIndex = page;
            });
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: true, //selected item
          showUnselectedLabels: true, //unselected item
          type: BottomNavigationBarType.fixed,
          onTap: _onTappedBar,
          items: _isViewer
              ? const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.category),
                    label: 'Items',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: 'Wishlist',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ]
              : const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt),
                    label: 'List of Items',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.archive),
                    label: 'Archive',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
          currentIndex: _selectedIndex,
        ),
      ),
    );
  }

  void _onTappedBar(int value) {
    setState(() {
      _selectedIndex = value;
    });
    _pageController.jumpToPage(value);
  }
}
