import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/modern_loading.dart';
import '../widgets/auth_pagination_widget.dart';
import 'detail_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  final _svc = ItemService();
  final List<Item> _items = [];
  late Future<void> _loadFuture;

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingPage = false;

  // Search state
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadItems();
  }

  Future<void> _loadItems({int page = 1}) async {
    try {
      setState(() {
        if (page == 1) {
          // Initial load
        } else {
          _isLoadingPage = true;
        }
      });

      final res = await _svc.getAllItem(
        page: page,
        limit: 10,
        inactiveOnly: true,
        search: _searchQuery,
      );
      final list = (res['items'] ?? res) as dynamic;
      final List data = list is List ? list : (list['data'] ?? []);

      // Calculate total pages from response
      final totalItems = res['total'] ?? data.length;
      final totalPages = (totalItems / 10).ceil();

      _items
        ..clear()
        ..addAll(
          data
              .map((e) => Item.fromJson(e))
              .toList(), // No need to filter since backend already returns only inactive items
        );

      setState(() {
        _currentPage = page;
        _totalPages = totalPages;
        _isLoadingPage = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPage = false;
      });
    }
  }

  void _onPageChanged(int page) {
    _loadItems(page: page);
  }

  void _performSearch() {
    // Cancel previous timer
    _searchTimer?.cancel();

    // Set a new timer for debounced search
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      _loadItems(page: 1); // Reset to page 1 when searching
    });
  }

  Widget _leadingThumb(Item item) {
    final url = item.photoUrl.trim();
    if (url.isEmpty) {
      return Container(
        width: 72.sp,
        height: 72.sp,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Icon(Icons.inventory_2_outlined),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 72.sp,
        height: 72.sp,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72.sp,
          height: 72.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar - Always visible
          Container(
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                // Trigger search with debounce
                _performSearch();
              },
              decoration: InputDecoration(
                hintText: 'Search archived items by name or description...',
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
          // Content Area
          Expanded(
            child: FutureBuilder<void>(
              future: _loadFuture,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const ModernLoading(
                    message: 'Loading archived items...',
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomText(text: 'Failed to load archived items'),
                    ),
                  );
                }
                if (_items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(36.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.archive_outlined,
                            size: 64.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          CustomText(
                            text: _searchQuery.isNotEmpty
                                ? 'No archived items found for "${_searchQuery}"'
                                : 'No archived items to display',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try adjusting your search terms'
                                : 'Archived items will appear here when items are deactivated',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 20.w,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (_, index) {
                          final item = _items[index];
                          final subtitle = item.description.isNotEmpty
                              ? item.description.first
                              : '-';
                          return Card(
                            child: InkWell(
                              onTap: () async {
                                // TODO: navigate to detail if needed
                                debugPrint('Open item ${item.iid}');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DetailScreen(
                                      item: item,
                                      isFromArchive: true,
                                    ),
                                  ),
                                );
                                if (result is Map &&
                                    result['deleted'] == true) {
                                  final id = result['id'] as String;
                                  setState(() {
                                    _items.removeWhere((e) => e.iid == id);
                                  });
                                }
                                if (result is Item) {
                                  // If the item became active, remove it from the archive list
                                  if (result.isActive.toLowerCase() == 'true') {
                                    setState(() {
                                      _items.removeWhere(
                                        (e) => e.iid == result.iid,
                                      );
                                    });
                                  } else {
                                    // If the item is still inactive, update it in the list
                                    setState(() {
                                      final l = _items.indexWhere(
                                        (e) => e.iid == result.iid,
                                      );
                                      if (l != -1) _items[l] = result;
                                    });
                                  }
                                }
                              },
                              child: ListTile(
                                leading: _leadingThumb(item),
                                title: CustomText(
                                  text: item.name.isEmpty
                                      ? 'Untitled'
                                      : item.name,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 2,
                                ),
                                subtitle: CustomText(
                                  text: subtitle,
                                  maxLines: 2,
                                ),
                                trailing: SizedBox(
                                  height: double.infinity,
                                  child: GestureDetector(
                                    onTap: () => debugPrint('More ${item.iid}'),
                                    child: const Icon(
                                      Icons.keyboard_arrow_right,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }
}
