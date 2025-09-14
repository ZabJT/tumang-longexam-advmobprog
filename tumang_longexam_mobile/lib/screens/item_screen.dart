import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../models/item_model.dart';
import '../services/item_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../widgets/modern_loading.dart';
import 'detail_screen.dart';

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final _svc = ItemService();
  final List<Item> _items = [];
  late Future<void> _loadFuture;
  String _userType = 'viewer'; // Default to viewer for safety

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadItems();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    try {
      final userService = UserService();
      final userData = await userService.getUserData();
      setState(() {
        _userType = userData['type']?.toLowerCase() ?? 'viewer';
      });
    } catch (e) {
      // If we can't get user type, default to viewer for safety
      setState(() {
        _userType = 'viewer';
      });
    }
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
            .where((item) => item.isActive.toLowerCase() == 'true'),
      );
  }

  //---- Add Item Dialog ----
  Future<void> _openAddItemDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final photoCtrl = TextEditingController();
    final qtyTotalCtrl = TextEditingController();
    final qtyAvailCtrl = TextEditingController();
    final formkey = GlobalKey<FormState>();
    bool isSaving = false;
    bool isActive = true;
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    List<String> _parseDesc(String raw) => raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    String? _req(String? v) => (v?.trim().isEmpty ?? true) ? 'Required' : null;

    void _showDeveloperModeInstructions() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
              SizedBox(width: 8.w),
              const Text('Enable Developer Mode'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To use image picker, you need to enable Developer Mode:',
              ),
              SizedBox(height: 12.h),
              const Text('1. Press Windows + I to open Settings'),
              const Text('2. Go to Update & Security > For developers'),
              const Text('3. Turn on "Developer Mode"'),
              const Text('4. Restart your computer'),
              const Text('5. Restart the Flutter app'),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'Alternative: Use the URL option to add images from the internet.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
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

    Widget _buildImageSourceOption({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32.sp, color: Theme.of(context).primaryColor),
              SizedBox(height: 8.h),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    void _showUrlInputDialog() {
      final urlController = TextEditingController(text: photoCtrl.text);
      final formKey = GlobalKey<FormState>();

      // URL validation function
      String? validateUrl(String? value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a URL';
        }

        final url = value.trim();
        final uri = Uri.tryParse(url);

        if (uri == null || !uri.hasScheme) {
          return 'Please enter a valid URL (e.g., https://example.com/image.jpg)';
        }

        if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
          return 'URL must start with http:// or https://';
        }

        // Check if it looks like an image URL
        final imageExtensions = [
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.bmp',
        ];
        final hasImageExtension = imageExtensions.any(
          (ext) => url.toLowerCase().contains(ext),
        );

        if (!hasImageExtension) {
          return 'URL should point to an image file (.jpg, .png, .gif, etc.)';
        }

        return null;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Enter Image URL'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/image.jpg',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  validator: validateUrl,
                  autofocus: true,
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supported formats:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        'JPG, PNG, GIF, WebP, BMP',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Update the local state
                  photoCtrl.text = urlController.text.trim();
                  selectedImage = null;
                  Navigator.pop(context);
                  ModernSnackBar.success(
                    context,
                    'Image URL set successfully!',
                  );
                }
              },
              child: const Text('Set URL'),
            ),
          ],
        ),
      );
    }

    Future<void> _pickImage(ImageSource source) async {
      try {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );

        if (image != null) {
          selectedImage = File(image.path);
          photoCtrl.text = image.path;
          ModernSnackBar.success(context, 'Image selected successfully!');
        }
      } catch (e) {
        String errorMessage = 'Unable to access image picker. ';

        if (e.toString().contains('channel-error') ||
            e.toString().contains('symlink')) {
          errorMessage +=
              'Please enable Developer Mode in Windows settings and restart the app.';
          ModernSnackBar.error(context, errorMessage);
          _showDeveloperModeInstructions();
        } else if (e.toString().contains('permission')) {
          errorMessage += 'Please grant camera/photo permissions in settings.';
          ModernSnackBar.error(context, errorMessage);
        } else if (source == ImageSource.camera) {
          errorMessage +=
              'Camera not available. Try selecting from gallery instead.';
          ModernSnackBar.error(context, errorMessage);
        } else {
          errorMessage += 'Please try again or use URL option.';
          ModernSnackBar.error(context, errorMessage);
        }
      }
    }

    void _showImageSourceDialog() {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (context) => Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Select Image Source',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.link,
                    label: 'URL',
                    onTap: () {
                      Navigator.pop(context);
                      _showUrlInputDialog();
                    },
                  ),
                ],
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      );
    }

    Widget _buildPlaceholder() {
      return Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 32.sp,
              color: Colors.grey[600],
            ),
            SizedBox(height: 4.h),
            Text(
              'Tap to add image',
              style: TextStyle(color: Colors.grey[600], fontSize: 10.sp),
            ),
          ],
        ),
      );
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> _save() async {
              if (isSaving) return;
              if (!formkey.currentState!.validate()) return;
              setLocal(() => isSaving = true);
              try {
                final payload = {
                  'name': nameCtrl.text.trim(),
                  'description': _parseDesc(descCtrl.text),
                  'photoUrl': photoCtrl.text.trim(),
                  'qtyTotal': int.tryParse(qtyTotalCtrl.text.trim()) ?? 0,
                  'qtyAvailable': int.tryParse(qtyAvailCtrl.text.trim()) ?? 0,
                  'isActive': isActive,
                };
                final res = await _svc.createItem(payload);
                final created = (res['item'] ?? res);
                final newItem = Item.fromJson(created);
                setState(() => _items.insert(0, newItem));
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ModernSnackBar.success(context, 'Item added successfully!');
                }
              } catch (e) {
                setLocal(() => isSaving = false);
                if (mounted) {
                  ModernSnackBar.error(context, 'Failed to add: $e');
                }
              }
            }

            return AlertDialog(
              title: const Text('Add Item'),
              content: Form(
                key: formkey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image Preview
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 120.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Stack(
                            children: [
                              if (selectedImage != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedImage!,
                                    height: 120.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (photoCtrl.text.trim().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    photoCtrl.text.trim(),
                                    height: 120.h,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildPlaceholder(),
                                  ),
                                )
                              else
                                _buildPlaceholder(),

                              Positioned(
                                top: 8.h,
                                right: 8.w,
                                child: Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: _req,
                      ),
                      SizedBox(height: 10.h),
                      TextFormField(
                        controller: descCtrl,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description (one per line or comma-sep)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) => _parseDesc(v ?? '').isEmpty
                            ? 'Add at least one line'
                            : null,
                      ),
                      SizedBox(height: 10.h),
                      TextFormField(
                        controller: photoCtrl,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Photo URL/Path',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _showImageSourceDialog,
                          ),
                          hintText: 'Use image picker above to select image',
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: qtyTotalCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty Total',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: TextFormField(
                              controller: qtyAvailCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty Available',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final a = int.tryParse((v ?? '').trim());
                                final t = int.tryParse(
                                  qtyTotalCtrl.text.trim(),
                                );
                                if (a == null || a < 0) return 'Invalid';
                                if (t != null && a > t) return '> total';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: isActive,
                        onChanged: (val) => setLocal(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : _save,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSaving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 72.sp,
            height: 72.sp,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 72.sp,
            height: 72.sp,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }

  bool get _canAddItems => _userType == 'admin' || _userType == 'editor';

  Widget _buildBuyerItemCard(Item item, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80.w,
              height: 80.h,
              child: item.photoUrl.isNotEmpty
                  ? Image.network(
                      item.photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
          ),
          SizedBox(width: 12.w),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.isEmpty ? 'Untitled Product' : item.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: 16.sp,
                      color: Colors.green[600],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${item.qtyAvailable} in stock',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow Icon
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue
      floatingActionButton: _canAddItems
          ? FloatingActionButton(
              onPressed: _openAddItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
      body: FutureBuilder<void>(
        future: _loadFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const ModernLoading(message: 'Loading items...');
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CustomText(text: 'Failed to load items'),
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
                      Icons.inventory_2_outlined,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    CustomText(
                      text: 'No items available',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _userType == 'viewer'
                          ? 'Browse our catalog when items are added'
                          : 'Add your first item to get started',
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
                        builder: (_) => DetailScreen(item: item),
                      ),
                    );
                    if (result is Map && result['deleted'] == true) {
                      final id = result['id'] as String;
                      setState(() {
                        _items.removeWhere((e) => e.iid == id);
                      });
                    }
                    if (result is Item) {
                      // If the item became inactive, remove it from the list
                      if (result.isActive.toLowerCase() == 'false') {
                        setState(() {
                          _items.removeWhere((e) => e.iid == result.iid);
                        });
                      } else {
                        // If the item is still active, update it in the list
                        setState(() {
                          final l = _items.indexWhere(
                            (e) => e.iid == result.iid,
                          );
                          if (l != -1) _items[l] = result;
                        });
                      }
                    }
                  },
                  child: _userType == 'viewer'
                      ? _buildBuyerItemCard(item, subtitle)
                      : ListTile(
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
