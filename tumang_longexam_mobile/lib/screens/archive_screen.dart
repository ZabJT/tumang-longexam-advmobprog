import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/modern_loading.dart';
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

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadItems();
  }

  Future<void> _loadItems() async {
    final res = await _svc.getAllItem();
    final list = (res['items'] ?? res) as dynamic;
    final List data = list is List ? list : (list['data'] ?? []);
    _items
      ..clear()
      ..addAll(
        data
            .map((e) => Item.fromJson(e))
            .where((item) => item.isActive.toLowerCase() == 'false'),
      );
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
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const ModernLoading(message: 'Loading archived items...');
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
                child: CustomText(text: 'No archived items to display...'),
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
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
                        builder: (_) =>
                            DetailScreen(item: item, isFromArchive: true),
                      ),
                    );
                    if (result is Map && result['deleted'] == true) {
                      final id = result['id'] as String;
                      setState(() {
                        _items.removeWhere((e) => e.iid == id);
                      });
                    }
                    if (result is Item) {
                      // If the item became active, remove it from the archive list
                      if (result.isActive.toLowerCase() == 'true') {
                        setState(() {
                          _items.removeWhere((e) => e.iid == result.iid);
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
                      text: item.name.isEmpty ? 'Untitled' : item.name,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      maxLines: 2,
                    ),
                    subtitle: CustomText(text: subtitle, maxLines: 2),
                    trailing: SizedBox(
                      height: double.infinity,
                      child: GestureDetector(
                        onTap: () => debugPrint('More ${item.iid}'),
                        child: const Icon(Icons.keyboard_arrow_right),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
