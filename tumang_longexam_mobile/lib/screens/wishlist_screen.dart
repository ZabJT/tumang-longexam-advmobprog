import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import '../widgets/modern_loading.dart';
import '../widgets/auth_pagination_widget.dart';
import '../utils/error_handler.dart';
import 'detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final ItemService _itemService = ItemService();
  List<Item> _wishlistItems = [];
  bool _isLoading = true;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingPage = false;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist({int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          _isLoading = true;
        } else {
          _isLoadingPage = true;
        }
      });

      final response = await _itemService.getWishlist(page: page, limit: 10);

      // Calculate total pages from response
      final totalItems = response['total'] ?? 0;
      final totalPages = (totalItems / 10).ceil();

      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> itemsData = response['data'];
        setState(() {
          _wishlistItems = itemsData
              .map((item) => Item.fromJson(item))
              .toList();
          _currentPage = page;
          _totalPages = totalPages;
        });
      } else {
        // Handle case where response doesn't have expected structure
        setState(() {
          _wishlistItems = [];
          _currentPage = page;
          _totalPages = totalPages;
        });
      }
    } catch (e) {
      print('Error loading wishlist: $e');
      // Don't show error snackbar for empty wishlist, just set empty list
      setState(() {
        _wishlistItems = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  void _onPageChanged(int page) {
    _loadWishlist(page: page);
  }

  Future<void> _removeFromWishlist(String itemId) async {
    try {
      await _itemService.removeFromWishlist(itemId);
      setState(() {
        _wishlistItems.removeWhere((item) => item.iid == itemId);
      });
      ModernSnackBar.success(context, 'Removed from wishlist');
    } catch (e) {
      ModernSnackBar.error(context, ErrorHandler.getUserFriendlyMessage(e));
    }
  }

  void _navigateToItemDetail(Item item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(item: item, isPublicView: false),
      ),
    ).then((_) {
      // Refresh wishlist when returning from detail screen
      _loadWishlist();
    });
  }

  Widget _buildWishlistItem(Item item) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _navigateToItemDetail(item),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Item Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: item.photoUrl.isNotEmpty
                    ? Image.network(
                        item.photoUrl,
                        width: 80.w,
                        height: 80.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80.w,
                            height: 80.h,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 32.sp,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80.w,
                        height: 80.h,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 32.sp,
                        ),
                      ),
              ),
              SizedBox(width: 16.w),

              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).textTheme.titleMedium?.color ??
                            Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    if (item.description.isNotEmpty)
                      Text(
                        item.description.first,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 16.sp,
                          color: Colors.blue[600],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Qty: ${item.qtyAvailable}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color ??
                                Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove from wishlist button
              IconButton(
                onPressed: () => _removeFromWishlist(item.iid),
                icon: Icon(Icons.favorite, color: Colors.red, size: 24.sp),
                tooltip: 'Remove from wishlist',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80.sp, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).textTheme.titleMedium?.color ??
                  Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add items to your wishlist by tapping the heart icon',
            style: TextStyle(
              fontSize: 14.sp,
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  Colors.grey[500],
            ),
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
          'Wishlist',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_wishlistItems.isNotEmpty)
            IconButton(
              onPressed: _loadWishlist,
              icon: Icon(Icons.refresh, size: 24.sp),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wishlistItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadWishlist(page: _currentPage),
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _wishlistItems.length,
                      itemBuilder: (context, index) {
                        return _buildWishlistItem(_wishlistItems[index]);
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
