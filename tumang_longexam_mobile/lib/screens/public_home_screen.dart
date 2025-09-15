import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/public_pagination_widget.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import 'detail_screen.dart';

class PublicHomeScreen extends StatefulWidget {
  const PublicHomeScreen({Key? key}) : super(key: key);

  @override
  State<PublicHomeScreen> createState() => _PublicHomeScreenState();
}

class _PublicHomeScreenState extends State<PublicHomeScreen> {
  final _itemService = ItemService();
  final _userService = UserService();
  List<Item> _featuredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isLoggedIn = false;
  Map<String, dynamic> _userData = {};
  final TextEditingController _searchController = TextEditingController();

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingPage = false;

  // Get adaptive brand color based on theme
  Color _getBrandColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF4A5A7A)
        : const Color(0xFF202A44); // Lighter blue for dark mode
  }

  Color _getBrandColorDark(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF3A4A6A)
        : const Color(0xFF1A2238); // Darker shade for dark mode
  }

  // Get adaptive text color - white in dark mode, theme color in light mode
  Color _getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  Color _getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white70
        : Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
  }

  // Get adaptive shadows - no shadows in dark mode
  List<BoxShadow> _getShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ];
  }

  List<BoxShadow> _getCardShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? []
        : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData({int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          _isLoading = true;
        } else {
          _isLoadingPage = true;
        }
      });

      // Load featured items with pagination (active items only)
      final res = await _itemService.getAllItem(
        page: page,
        limit: 10,
        activeOnly: true,
        sortBy: 'createdAt',
        sortOrder: 'desc',
        search: _searchQuery,
      );
      final list = (res['items'] ?? res) as dynamic;
      final List data = list is List ? list : (list['data'] ?? []);

      // Debug: Print first few items to check sorting
      print('Public Home Debug - Received ${data.length} items');
      if (data.isNotEmpty) {
        print(
          'First item: ${data[0]['name']} - createdAt: ${data[0]['createdAt']}',
        );
        if (data.length > 1) {
          print(
            'Second item: ${data[1]['name']} - createdAt: ${data[1]['createdAt']}',
          );
        }
      }

      // Calculate total pages from response
      final totalItems = res['total'] ?? data.length;
      final totalPages = (totalItems / 10).ceil();

      setState(() {
        _featuredItems = data
            .map((e) => Item.fromJson(e))
            .toList(); // No need to filter since backend already returns only active items
        _currentPage = page;
        _totalPages = totalPages;
        _isLoading = false;
        _isLoadingPage = false;
      });

      // Only reset authentication state if this is the initial load (page 1)
      // Don't reset authentication state during pagination
      if (page == 1) {
        // Check authentication state on initial load
        await _checkAuthenticationState();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  void _onPageChanged(int page) {
    _loadData(page: page);
  }

  Timer? _searchTimer;

  void _performSearch() {
    // Cancel previous timer
    _searchTimer?.cancel();

    // Set a new timer for debounced search
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _loadData(page: 1); // Reset to page 1 when searching
    });
  }

  void _navigateToLogin() async {
    final result = await Navigator.pushNamed(context, '/login');
    // Check if login was successful and update authentication state
    if (result == true) {
      await _checkAuthenticationState();
    }
  }

  Future<void> _checkAuthenticationState() async {
    try {
      final userData = await _userService.getUserData();
      final isLoggedIn =
          userData['token'] != null && userData['token'].isNotEmpty;

      print('Public Home Screen - Authentication Check - User Data: $userData');
      print(
        'Public Home Screen - Authentication Check - Is Logged In: $isLoggedIn',
      );
      print(
        'Public Home Screen - Authentication Check - User Type: ${userData['type']}',
      );

      setState(() {
        _isLoggedIn = isLoggedIn;
        _userData = userData;
      });
    } catch (e) {
      print('Error checking authentication state: $e');
      setState(() {
        _isLoggedIn = false;
        _userData = {};
      });
    }
  }

  void _navigateToDetail(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(
          item: item,
          isPublicView: !_isLoggedIn, // Use public view only if not logged in
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/Car_Icon.png',
          height: 70.h,
          fit: BoxFit.contain,
        ),
        backgroundColor: _getBrandColor(context), // Adaptive brand color
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoggedIn) ...[
            TextButton(
              onPressed: _navigateToLogin,
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            // Show inquiry icon for authenticated users
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => Navigator.pushNamed(context, '/inquiries'),
              tooltip: 'My Inquiries',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getBrandColor(context), // Adaptive brand color
                      _getBrandColorDark(context), // Adaptive darker shade
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _getShadows(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoggedIn
                          ? 'Welcome back, ${_userData['firstName'] ?? 'User'}!'
                          : 'Welcome to Z-Customs',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Discover amazing cars and great deals!',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    ),
                    SizedBox(height: 16.h),
                    // Search Section inside welcome card
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlign: TextAlign.left,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                          // Trigger search with debounce
                          _performSearch();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search cars by name, brand, or model...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).primaryColor,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _performSearch();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Featured Cars Section
              CustomText(
                text: 'Featured Cars',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 16.h),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_featuredItems.isEmpty)
                _buildEmptyState()
              else
                Column(
                  children: [
                    _buildFeaturedCars(),
                    SizedBox(height: 16.h),
                    // Pagination
                    PublicPaginationWidget(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPageChanged: _onPageChanged,
                      isLoading: _isLoadingPage,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isLoggedIn
          ? BottomNavigationBar(
              backgroundColor: Theme.of(context).cardColor,
              selectedItemColor: _getBrandColor(
                context,
              ), // Adaptive brand color
              unselectedItemColor: Theme.of(context).unselectedWidgetColor,
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Already on public home
                    break;
                  case 1:
                    // Navigate to wishlist
                    Navigator.pushNamed(context, '/wishlist');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/profile');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Wishlist',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'No cars available',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Check back later for new car listings',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCars() {
    // No need for local filtering since search is now handled by the backend
    if (_featuredItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _getCardShadows(context),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 12.h),
            Text(
              'No cars found',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Try adjusting your search terms',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.82,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _featuredItems.length,
      itemBuilder: (context, index) {
        final item = _featuredItems[index];
        return _buildCarCard(item);
      },
    );
  }

  Widget _buildCarCard(Item item) {
    return InkWell(
      onTap: () => _navigateToDetail(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _getCardShadows(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.r),
                  ),
                  color: Colors.grey[200],
                ),
                child: item.photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(12.r),
                        ),
                        child: Image.network(
                          item.photoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.directions_car_outlined,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.directions_car_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
              ),
            ),
            // Car Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _getTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    if (item.description.isNotEmpty)
                      Text(
                        item.description.first,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: _getSecondaryTextColor(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Qty: ${item.qtyAvailable}',
                          style: TextStyle(
                            fontSize: 9.sp,
                            color: _getSecondaryTextColor(context),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 8.sp,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
