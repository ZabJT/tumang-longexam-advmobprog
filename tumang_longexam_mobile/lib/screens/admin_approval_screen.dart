import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/modern_loading.dart';
import '../widgets/auth_pagination_widget.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingPage = false;

  @override
  void initState() {
    super.initState();
    _loadPendingUsers();
  }

  Future<void> _loadPendingUsers({int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          _isLoading = true;
        } else {
          _isLoadingPage = true;
        }
      });

      final response = await _userService.getPendingUsers(
        page: page,
        limit: 10,
      );

      // Calculate total pages from response
      final totalItems = response['total'] ?? 0;
      final totalPages = (totalItems / 10).ceil();

      setState(() {
        _pendingUsers = List<Map<String, dynamic>>.from(
          response['users'] ?? [],
        );
        _currentPage = page;
        _totalPages = totalPages;
        _isLoading = false;
        _isLoadingPage = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
      if (mounted) {
        ModernSnackBar.error(context, 'Failed to load pending users: $e');
      }
    }
  }

  void _onPageChanged(int page) {
    _loadPendingUsers(page: page);
  }

  Future<void> _approveUser(String userId, String userName) async {
    try {
      setState(() => _isProcessing = true);
      await _userService.approveUser(userId);
      await _loadPendingUsers(); // Refresh the list
      if (mounted) {
        ModernSnackBar.success(
          context,
          'User $userName approved successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.error(context, 'Failed to approve user: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectUser(String userId, String userName) async {
    try {
      setState(() => _isProcessing = true);
      await _userService.rejectUser(userId);
      await _loadPendingUsers(); // Refresh the list
      if (mounted) {
        ModernSnackBar.success(
          context,
          'User $userName rejected successfully!',
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.error(context, 'Failed to reject user: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${user['firstName']} ${user['lastName']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Email', user['email']),
            _buildDetailRow('Username', user['username']),
            _buildDetailRow('Type', user['type'].toString().toUpperCase()),
            _buildDetailRow('Age', user['age']),
            _buildDetailRow('Gender', user['gender']),
            _buildDetailRow('Contact', user['contactNumber']),
            _buildDetailRow('Address', user['address']),
            _buildDetailRow(
              'Status',
              user['approvalStatus'].toString().toUpperCase(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: ModernLoading())
          : _pendingUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64.sp,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No pending approvals',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'All user requests have been processed',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadPendingUsers(page: _currentPage),
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: _pendingUsers.length,
                      itemBuilder: (context, index) {
                        final user = _pendingUsers[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                      child: Text(
                                        '${user['firstName'][0]}${user['lastName'][0]}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${user['firstName']} ${user['lastName']}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          Text(
                                            user['email'],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(user['type']),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user['type'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _showUserDetails(user),
                                        icon: const Icon(Icons.info_outline),
                                        label: const Text('View Details'),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _approveUser(
                                                user['_id'],
                                                '${user['firstName']} ${user['lastName']}',
                                              ),
                                        icon: const Icon(Icons.check),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _rejectUser(
                                                user['_id'],
                                                '${user['firstName']} ${user['lastName']}',
                                              ),
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Pagination
                if (_totalPages > 1)
                  AuthPaginationWidget(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    onPageChanged: _onPageChanged,
                    isLoading: _isLoadingPage,
                  ),
              ],
            ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
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
