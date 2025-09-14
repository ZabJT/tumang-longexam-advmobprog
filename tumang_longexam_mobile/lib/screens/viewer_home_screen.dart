import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ViewerHomeScreen extends StatefulWidget {
  const ViewerHomeScreen({Key? key}) : super(key: key);

  @override
  State<ViewerHomeScreen> createState() => _ViewerHomeScreenState();
}

class _ViewerHomeScreenState extends State<ViewerHomeScreen> {
  String _userName = 'User';
  String _userType = 'viewer';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userService = UserService();
      final userData = await userService.getUserData();
      setState(() {
        _userName = userData['firstName'] ?? 'User';
        _userType = userData['type']?.toLowerCase() ?? 'viewer';
      });
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // TODO: Navigate to cart
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart functionality coming soon!'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
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
                    colors: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
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
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _userName,
                      style: TextStyle(
                        fontSize: 24.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Discover amazing products and great deals!',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Quick Actions
              CustomText(
                text: 'Quick Actions',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.store,
                      title: 'Browse Products',
                      subtitle: 'View all items',
                      onTap: () {
                        Navigator.pushNamed(context, '/items');
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.contact_support,
                      title: 'Inquiry',
                      subtitle: 'Ask questions',
                      onTap: () {
                        _showInquiry();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.favorite_outline,
                      title: 'Wishlist',
                      subtitle: 'Saved items',
                      onTap: () {
                        _showWishlist();
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.schedule,
                      title: 'Test Drive',
                      subtitle: 'Book test drive',
                      onTap: () {
                        _showTestDriveBooking();
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Recent Items Section
              CustomText(
                text: 'Recent Items',
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 16.h),

              Container(
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
                      Icons.inventory_2_outlined,
                      size: 48.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No recent items',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Start browsing to see your recent items here',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/items');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                      ),
                      child: const Text('Browse Products'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey[600],
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/items');
              break;
            case 2:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16.w),
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
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24.sp, color: const Color(0xFF2196F3)),
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showWishlist() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wishlist'),
        content: const Text(
          'Your saved cars will appear here. This feature is coming soon!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInquiry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Inquiry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Have questions about a car? Submit your inquiry and we\'ll get back to you.',
            ),
            SizedBox(height: 16.h),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Your Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Inquiry submitted successfully!'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showTestDriveBooking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Test Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Schedule a test drive for any available car.'),
            SizedBox(height: 16.h),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Preferred Date & Time',
                border: OutlineInputBorder(),
                hintText: 'e.g., Tomorrow 2:00 PM',
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test drive booked successfully!'),
                ),
              );
            },
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}
