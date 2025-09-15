import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/inquiry_model.dart';
import '../services/item_service.dart';
import '../services/user_service.dart';
import '../widgets/auth_pagination_widget.dart';

class ReplyBoxWidget extends StatefulWidget {
  final Inquiry inquiry;
  final Function(Inquiry, String, String) onSubmitReply;

  const ReplyBoxWidget({
    super.key,
    required this.inquiry,
    required this.onSubmitReply,
  });

  @override
  State<ReplyBoxWidget> createState() => _ReplyBoxWidgetState();
}

class _ReplyBoxWidgetState extends State<ReplyBoxWidget> {
  late TextEditingController _replyController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reply to Inquiry:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.orange[600],
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _replyController,
          focusNode: _focusNode,
          maxLines: 4,
          minLines: 3,
          decoration: InputDecoration(
            hintText: 'Type your reply here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: Colors.orange[400]!),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onSubmitReply(
                  widget.inquiry,
                  _replyController.text,
                  'approved',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Approve & Reply'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onSubmitReply(
                  widget.inquiry,
                  _replyController.text,
                  'rejected',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('Reject & Reply'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final ItemService _itemService = ItemService();
  final UserService _userService = UserService();
  List<Inquiry> _inquiries = [];
  bool _isLoading = true;
  bool _isAdminOrEditor = false;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingPage = false;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries({int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          _isLoading = true;
        } else {
          _isLoadingPage = true;
        }
      });

      // Check user type
      final userData = await _userService.getUserData();
      final userType = userData['type']?.toString().toLowerCase();
      _isAdminOrEditor = userType == 'admin' || userType == 'editor';

      // Load appropriate inquiries based on user type with pagination
      final response = _isAdminOrEditor
          ? await _itemService.getAllInquiries(page: page, limit: 10)
          : await _itemService.getUserInquiries(page: page, limit: 10);

      // Calculate total pages from response
      final totalItems = response['total'] ?? 0;
      final totalPages = (totalItems / 10).ceil();

      // Handle new API response format
      if (response['inquiries'] != null) {
        final List<dynamic> inquiriesData = response['inquiries'];
        setState(() {
          _inquiries = inquiriesData
              .map((inquiry) => Inquiry.fromJson(inquiry))
              .toList();
          _currentPage = page;
          _totalPages = totalPages;
        });
      } else if (response['data'] != null) {
        // Fallback for old format
        final List<dynamic> inquiriesData = response['data'];
        setState(() {
          _inquiries = inquiriesData
              .map((inquiry) => Inquiry.fromJson(inquiry))
              .toList();
          _currentPage = page;
          _totalPages = totalPages;
        });
      } else {
        setState(() {
          _inquiries = [];
          _currentPage = page;
          _totalPages = totalPages;
        });
      }
    } catch (e) {
      print('Error loading inquiries: $e');
      setState(() {
        _inquiries = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  void _onPageChanged(int page) {
    _loadInquiries(page: page);
  }

  Color _getStatusColorValue(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showInquiryModal(Inquiry inquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildInquiryModal(inquiry),
    );
  }

  Widget _buildInquiryModal(Inquiry inquiry) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Inquiry Details',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    size: 24.sp,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item info
                  _buildItemInfo(inquiry),
                  SizedBox(height: 20.h),

                  // Sender info
                  _buildSenderInfo(inquiry),
                  SizedBox(height: 20.h),

                  // Inquiry message
                  _buildInquiryMessage(inquiry),
                  SizedBox(height: 20.h),

                  // Admin reply (if exists)
                  if (inquiry.adminReply.isNotEmpty) ...[
                    _buildAdminReply(inquiry),
                    SizedBox(height: 20.h),
                  ],

                  // Reply box (for admin/editor only)
                  if (_isAdminOrEditor && inquiry.status == 'pending') ...[
                    _buildReplyBox(inquiry),
                    SizedBox(height: 20.h),
                  ],

                  // Status info
                  _buildStatusInfo(inquiry),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo(Inquiry inquiry) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: inquiry.itemPhotoUrl.isNotEmpty
                ? Image.network(
                    inquiry.itemPhotoUrl,
                    width: 60.w,
                    height: 60.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60.w,
                        height: 60.h,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey[400],
                          size: 24.sp,
                        ),
                      );
                    },
                  )
                : Container(
                    width: 60.w,
                    height: 60.h,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 24.sp,
                    ),
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inquiry.itemName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).textTheme.titleMedium?.color ??
                        Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColorValue(
                      inquiry.status,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColorValue(
                        inquiry.status,
                      ).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    inquiry.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColorValue(inquiry.status),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderInfo(Inquiry inquiry) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.blue[600], size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${inquiry.userName}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
                Text(
                  'Inquired on ${_formatDate(inquiry.createdAt)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors
                        .grey[600], // Keep dark text for contrast on light blue background
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryMessage(Inquiry inquiry) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inquiry Message:',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color:
                  Theme.of(context).textTheme.titleMedium?.color ??
                  Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            inquiry.message,
            style: TextStyle(
              fontSize: 14.sp,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  Colors.grey[700],
              height: 1.4,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminReply(Inquiry inquiry) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                size: 16.sp,
                color: Colors.green[600],
              ),
              SizedBox(width: 6.w),
              Text(
                'Reply from Z-Customs',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            inquiry.adminReply,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors
                  .grey[700], // Keep dark text for contrast on light green background
              height: 1.4,
            ),
            overflow: TextOverflow.visible,
            softWrap: true,
          ),
          if (inquiry.repliedAt != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Replied on ${_formatDate(inquiry.repliedAt!)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors
                    .grey[500], // Keep dark text for contrast on light green background
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyBox(Inquiry inquiry) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: ReplyBoxWidget(inquiry: inquiry, onSubmitReply: _submitReply),
    );
  }

  Widget _buildStatusInfo(Inquiry inquiry) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Status: ${inquiry.status.toUpperCase()}',
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    Theme.of(context).textTheme.bodyMedium?.color ??
                    Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply(
    Inquiry inquiry,
    String reply,
    String status,
  ) async {
    if (reply.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a reply message')));
      return;
    }

    try {
      await _itemService.replyToInquiry(inquiry.inquiryId, reply, status);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reply submitted successfully')));

      Navigator.pop(context); // Close modal
      _loadInquiries(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit reply: $e')));
    }
  }

  Widget _buildInquiryItem(Inquiry inquiry) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showInquiryModal(inquiry),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with item info and status
              Row(
                children: [
                  // Item Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: inquiry.itemPhotoUrl.isNotEmpty
                        ? Image.network(
                            inquiry.itemPhotoUrl,
                            width: 60.w,
                            height: 60.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60.w,
                                height: 60.h,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 24.sp,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 60.w,
                            height: 60.h,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 24.sp,
                            ),
                          ),
                  ),
                  SizedBox(width: 12.w),

                  // Item name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inquiry.itemName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(
                                  context,
                                ).textTheme.titleMedium?.color ??
                                Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColorValue(
                              inquiry.status,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _getStatusColorValue(
                                inquiry.status,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            inquiry.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColorValue(inquiry.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // User inquiry message
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  inquiry.message,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),

              // Admin reply (if exists)
              if (inquiry.adminReply.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16.sp,
                            color: Colors.blue[600],
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Admin Reply',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        inquiry.adminReply,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 8.h),

              // Date and time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'Inquired on ${_formatDate(inquiry.createdAt)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (inquiry.repliedAt != null) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(Icons.reply, size: 14.sp, color: Colors.grey[500]),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            'Replied on ${_formatDate(inquiry.repliedAt!)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help_outline, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No inquiries yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Make inquiries about items you\'re interested in',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inquiries',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inquiries.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadInquiries(page: _currentPage),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _inquiries.length,
                      itemBuilder: (context, index) {
                        return _buildInquiryItem(_inquiries[index]);
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
}
