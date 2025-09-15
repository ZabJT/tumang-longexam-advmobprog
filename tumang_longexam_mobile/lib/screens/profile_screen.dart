import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getCurrentUserProfile();
      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        // Check if it's an authentication error
        if (e.toString().contains('Session expired') ||
            e.toString().contains('No authentication token')) {
          // Show dialog and redirect to login
          _showLoginDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load user data: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Your session has expired. Please login again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login screen
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Modern App Bar with gradient
                SliverAppBar(
                  expandedHeight: 180.h,
                  floating: false,
                  pinned: true,
                  automaticallyImplyLeading: false, // Remove back button
                  backgroundColor: Theme.of(context).primaryColor,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 10.h),
                            // Profile Avatar with modern design
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 40.r,
                                backgroundColor: Theme.of(context).cardColor,
                                child: CircleAvatar(
                                  radius: 35.r,
                                  backgroundColor: _getTypeColor(
                                    _userData['type'],
                                  ).withOpacity(0.1),
                                  child: Text(
                                    _userData['firstName']
                                            ?.toString()
                                            .substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: _getTypeColor(_userData['type']),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).cardColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _userData['type']?.toString().toUpperCase() ??
                                    'USER',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                color: Theme.of(context).primaryColor,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color ??
                                    Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // Modern Info Cards
                        _buildModernInfoCard(
                          Icons.email_outlined,
                          'Email Address',
                          _userData['email'] ?? 'Not available',
                          Colors.blue,
                        ),
                        _buildModernInfoCard(
                          Icons.person_outline,
                          'Username',
                          _userData['username'] ?? 'Not available',
                          Colors.purple,
                        ),
                        _buildModernInfoCard(
                          Icons.phone_outlined,
                          'Contact Number',
                          _userData['contactNumber'] ?? 'Not available',
                          Colors.green,
                        ),
                        _buildModernInfoCard(
                          Icons.cake_outlined,
                          'Age',
                          _userData['age'] ?? 'Not available',
                          Colors.orange,
                        ),
                        _buildModernInfoCard(
                          Icons.wc_outlined,
                          'Gender',
                          _userData['gender'] ?? 'Not available',
                          Colors.pink,
                        ),
                        _buildModernInfoCard(
                          Icons.location_on_outlined,
                          'Address',
                          _userData['address'] ?? 'Not available',
                          Colors.red,
                        ),

                        SizedBox(height: 30.h),

                        // Account Information Section
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                Icons.account_circle_outlined,
                                color: Colors.amber[700],
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Account Details',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.color ??
                                    Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        _buildModernInfoCard(
                          Icons.admin_panel_settings_outlined,
                          'Account Type',
                          _userData['type'] ?? 'Not available',
                          _getTypeColor(_userData['type']),
                        ),
                        _buildModernInfoCard(
                          Icons.verified_user_outlined,
                          'Account Status',
                          _userData['isActive'] == true ? 'Active' : 'Inactive',
                          _userData['isActive'] == true
                              ? Colors.green
                              : Colors.red,
                        ),

                        SizedBox(
                          height: 100.h,
                        ), // Add extra bottom padding to prevent overflow
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildModernInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color:
                          Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          Colors.grey[800],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            // Status indicator for account status
            if (label == 'Account Status') ...[
              SizedBox(width: 8.w),
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: _userData['isActive'] == true
                      ? Colors.green
                      : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'editor':
        return Colors.blue;
      case 'viewer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
