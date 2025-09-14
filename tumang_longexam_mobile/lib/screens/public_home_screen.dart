import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
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
  bool _isLoggedIn = false;
  Map<String, dynamic> _userData = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load featured items (active items only)
      final res = await _itemService.getAllItem();
      final list = (res['items'] ?? res) as dynamic;
      final List data = list is List ? list : (list['data'] ?? []);

      setState(() {
        _featuredItems = data
            .map((e) => Item.fromJson(e))
            .where((item) => item.isActive.toLowerCase() == 'true')
            .take(6) // Show only 6 featured items
            .toList();
        _isLoading = false;
      });

      // Check if user is logged in
      final userData = await _userService.getUserData();
      setState(() {
        _isLoggedIn = userData['token'] != null && userData['token'].isNotEmpty;
        _userData = userData;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login');
  }

  void _navigateToDetail(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(item: item, isPublicView: true),
      ),
    );
  }

  void _showLoginRequiredDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: Text('Please login to $action'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToLogin();
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/Car_Icon.png',
          height: 70.h,
          fit: BoxFit.contain,
        ),
        backgroundColor: const Color(0xFF202A44),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoggedIn) ...[
            TextButton(
              onPressed: _navigateToLogin,
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                // Navigate to appropriate home based on user type
                final userType = _userData['type']?.toLowerCase() ?? 'viewer';
                if (userType == 'admin' || userType == 'editor') {
                  Navigator.pushNamed(context, '/home');
                } else {
                  Navigator.pushNamed(context, '/viewer-home');
                }
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
                    colors: [const Color(0xFF202A44), const Color(0xFF1A2238)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        textAlign: TextAlign.left,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search cars by name, brand, or model...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF202A44),
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
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

              // Horizontal Scrollable Quick Actions
              SizedBox(
                height: 50.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildHorizontalQuickAction(
                      icon: Icons.directions_car,
                      title: 'Browse Cars',
                      onTap: () {
                        _showAllCars();
                      },
                    ),
                    SizedBox(width: 12.w),
                    _buildHorizontalQuickAction(
                      icon: Icons.favorite_outline,
                      title: 'Wishlist',
                      onTap: () {
                        if (_isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Wishlist functionality coming soon!',
                              ),
                            ),
                          );
                        } else {
                          _showLoginRequiredDialog('save cars to wishlist');
                        }
                      },
                    ),
                    SizedBox(width: 12.w),
                    _buildHorizontalQuickAction(
                      icon: Icons.contact_support,
                      title: 'Inquiry',
                      onTap: () {
                        if (_isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Inquiry functionality coming soon!',
                              ),
                            ),
                          );
                        } else {
                          _showLoginRequiredDialog('submit inquiries');
                        }
                      },
                    ),
                    SizedBox(width: 12.w),
                    _buildHorizontalQuickAction(
                      icon: Icons.schedule,
                      title: 'Test Drive',
                      onTap: () {
                        if (_isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test drive booking coming soon!'),
                            ),
                          );
                        } else {
                          _showLoginRequiredDialog('book test drives');
                        }
                      },
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
                _buildFeaturedCars(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _isLoggedIn
          ? BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF202A44),
              unselectedItemColor: Colors.grey[600],
              currentIndex: 0,
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Already on public home
                    break;
                  case 1:
                    final userType =
                        _userData['type']?.toLowerCase() ?? 'viewer';
                    if (userType == 'admin' || userType == 'editor') {
                      Navigator.pushNamed(context, '/home');
                    } else {
                      Navigator.pushNamed(context, '/viewer-home');
                    }
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/profile');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
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
    List<Item> displayItems = _featuredItems;

    // Filter by search query if provided
    if (_searchQuery.isNotEmpty) {
      displayItems = _featuredItems.where((item) {
        return item.name.toLowerCase().contains(_searchQuery) ||
            item.description.any(
              (desc) => desc.toLowerCase().contains(_searchQuery),
            );
      }).toList();
    }

    if (displayItems.isEmpty) {
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
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
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
                        color: Colors.black87,
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
                          color: Colors.grey[600],
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
                            color: Colors.grey[600],
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

  void _showAllCars() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'All Cars',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: _featuredItems.length,
                  itemBuilder: (context, index) {
                    final item = _featuredItems[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12.h),
                      child: ListTile(
                        leading: _buildCarThumbnail(item),
                        title: Text(item.name),
                        subtitle: item.description.isNotEmpty
                            ? Text(item.description.first)
                            : null,
                        trailing: Text('Qty: ${item.qtyAvailable}'),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToDetail(item);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarThumbnail(Item item) {
    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: item.photoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.directions_car_outlined);
                },
              ),
            )
          : const Icon(Icons.directions_car_outlined),
    );
  }

  Widget _buildHorizontalQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150.w,
        height: 50.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: const Color(0xFF202A44),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.sp, color: Colors.white),
            SizedBox(width: 10.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
