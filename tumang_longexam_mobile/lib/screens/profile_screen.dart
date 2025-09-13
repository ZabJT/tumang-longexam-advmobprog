import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Profile Header
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 60.r,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  _userData['firstName']
                                          ?.toString()
                                          .substring(0, 1)
                                          .toUpperCase() ??
                                      'U',
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                '${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 28.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(_userData['type']),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _userData['type']?.toString().toUpperCase() ??
                                      'USER',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // User Information
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CustomText(
                      text: 'User Information',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildInfoCard(
                    'Email',
                    _userData['email'] ?? 'Not available',
                  ),
                  _buildInfoCard(
                    'Username',
                    _userData['username'] ?? 'Not available',
                  ),
                  _buildInfoCard(
                    'Contact Number',
                    _userData['contactNumber'] ?? 'Not available',
                  ),
                  _buildInfoCard('Age', _userData['age'] ?? 'Not available'),
                  _buildInfoCard(
                    'Gender',
                    _userData['gender'] ?? 'Not available',
                  ),
                  _buildInfoCard(
                    'Address',
                    _userData['address'] ?? 'Not available',
                  ),
                  _buildInfoCard(
                    'Account Type',
                    _userData['type'] ?? 'Not available',
                  ),
                  _buildInfoCard(
                    'Status',
                    _userData['isActive'] == true ? 'Active' : 'Inactive',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120.w,
              child: CustomText(
                text: label,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: CustomText(text: value, fontSize: 14.sp),
            ),
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
