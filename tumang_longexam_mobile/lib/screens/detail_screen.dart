import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item_model.dart';
import '../models/inquiry_model.dart';
import '../services/item_service.dart';
import '../services/user_service.dart';
import '../widgets/modern_loading.dart';
import '../utils/error_handler.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.item,
    this.isFromArchive = false,
    this.isPublicView = false,
  });
  final Item item;
  final bool isFromArchive;
  final bool isPublicView;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _photoCtrl;
  late TextEditingController _qtyTotalCtrl;
  late TextEditingController _qtyAvailableCtrl;
  bool _isSaving = false;
  bool _isActive = false;
  late ItemService _itemService;
  late Item _item;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isWishlisted = false;

  bool get _isItemInactive => _item.isActive.toLowerCase() == 'false';
  bool get _canEdit =>
      !widget.isPublicView && // Can't edit in public view
      !_isItemInactive &&
      _userType !=
          'viewer'; // Only allow editing if item is active and user is not a viewer
  String _userType = 'viewer'; // Default to viewer for safety

  @override
  void initState() {
    _item = widget.item;
    _itemService = ItemService();
    _nameCtrl = TextEditingController(text: _item.name);
    _descCtrl = TextEditingController(text: _item.description.join(','));
    _photoCtrl = TextEditingController(text: _item.photoUrl);
    _qtyTotalCtrl = TextEditingController(text: _item.qtyTotal);
    _qtyAvailableCtrl = TextEditingController(text: _item.qtyAvailable);
    _isActive = _item.isActive.toLowerCase() == 'true';
    _isWishlisted = _item.isWishlisted;

    if (!widget.isPublicView) {
      _loadUserType();
    } else {
      _userType = 'public'; // Set as public for public view
    }

    // Check wishlist status from local storage
    _checkWishlistStatus();
    super.initState();
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

  Future<void> _checkWishlistStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlist = prefs.getStringList('wishlist') ?? [];
      setState(() {
        _isWishlisted = wishlist.contains(_item.iid);
      });
    } catch (e) {
      print('Error checking wishlist status: $e');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _photoCtrl.dispose();
    _qtyTotalCtrl.dispose();
    _qtyAvailableCtrl.dispose();
    super.dispose();
  }

  List<String> _parseDesc(String raw) =>
      raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  int _textEditingController(TextEditingController text, {int? fallback = 0}) =>
      int.tryParse(text.text.trim()) ?? fallback!;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _photoCtrl.text = image.path; // Set the local path
        });
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

  void _showDeveloperModeInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    final urlController = TextEditingController(text: _photoCtrl.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Image URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _photoCtrl.text = urlController.text.trim();
                _selectedImage = null; // Clear local image
              });
              Navigator.pop(context);
            },
            child: const Text('Set URL'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final total = _textEditingController(_qtyTotalCtrl, fallback: 0);
    final available = _textEditingController(_qtyAvailableCtrl, fallback: 0);
    if (available > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Qty Available cannot exceed Qty Total')),
      );
      return;
    }
    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _parseDesc(_descCtrl.text.trim()),
      'photoUrl': _photoCtrl.text.trim(),
      'qtyTotal': total,
      'qtyAvailable': available,
      'isActive': _isActive,
    };
    if (mounted) setState(() => _isSaving = true);
    try {
      await _itemService.updateItem(_item.iid, payload);
      final updatedItem = _item.copyWith(
        name: _nameCtrl.text.trim(),
        description: _parseDesc(_descCtrl.text.trim()),
        photoUrl: _photoCtrl.text.trim(),
        qtyTotal: total.toString(),
        qtyAvailable: available.toString(),
        isActive: _isActive.toString(),
      );
      _item = updatedItem;
      if (mounted) setState(() {});
      ModernSnackBar.success(context, 'Item updated successfully!');
      if (mounted) Navigator.of(context).pop(_item);
    } catch (e) {
      ModernSnackBar.error(context, ErrorHandler.getUserFriendlyMessage(e));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _toggleActiveAndSave(bool newValue) async {
    if (_isSaving) return; // Prevent multiple simultaneous saves

    setState(() {
      _isActive = newValue;
      _isSaving = true;
    });

    final payload = {
      'name': _nameCtrl.text.trim(),
      'description': _parseDesc(_descCtrl.text.trim()),
      'photoUrl': _photoCtrl.text.trim(),
      'qtyTotal': _textEditingController(_qtyTotalCtrl, fallback: 0),
      'qtyAvailable': _textEditingController(_qtyAvailableCtrl, fallback: 0),
      'isActive': newValue,
    };

    try {
      await _itemService.updateItem(_item.iid, payload);
      final updatedItem = _item.copyWith(
        name: _nameCtrl.text.trim(),
        description: _parseDesc(_descCtrl.text.trim()),
        photoUrl: _photoCtrl.text.trim(),
        qtyTotal: _textEditingController(_qtyTotalCtrl, fallback: 0).toString(),
        qtyAvailable: _textEditingController(
          _qtyAvailableCtrl,
          fallback: 0,
        ).toString(),
        isActive: newValue.toString(),
      );
      _item = updatedItem;

      ModernSnackBar.success(
        context,
        'Item ${newValue ? 'activated' : 'deactivated'} successfully!',
      );

      // Navigate back to the previous page
      if (mounted) Navigator.of(context).pop(_item);
    } catch (e) {
      // Revert the toggle if the update failed
      setState(() => _isActive = !newValue);
      ModernSnackBar.error(context, ErrorHandler.getUserFriendlyMessage(e));
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _confirmDelete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 28),
            SizedBox(width: 12.w),
            const Text('Delete Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${_item.name}"?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 8.h),
            Text(
              'This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => _isSaving = true);
    try {
      await _itemService.deleteItem(_item.iid, {});
      if (!mounted) return;
      ModernSnackBar.success(context, 'Item deleted successfully!');
      Navigator.of(context).pop({'deleted': true, 'id': _item.iid});
    } catch (e) {
      if (!mounted) return;
      ModernSnackBar.error(context, ErrorHandler.getUserFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _imagePreview() {
    return GestureDetector(
      onTap: _canEdit ? _showImageSourceDialog : null,
      child: Container(
        height: 160.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            // Image content
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else if (_photoCtrl.text.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _photoCtrl.text.trim(),
                  height: 160.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                ),
              )
            else
              _buildPlaceholder(),

            // Overlay for editing
            if (_canEdit)
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 160.h,
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
            size: 48.sp,
            color: Colors.grey[600],
          ),
          SizedBox(height: 8.h),
          Text(
            _canEdit ? 'Tap to add image' : 'No image',
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodySmall?.color ??
                  Colors.grey[600],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerView() {
    return Scaffold(
      appBar: AppBar(
        title: Text(_item.name.isEmpty ? 'Product Details' : _item.name),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: double.infinity,
                height: 300.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _item.photoUrl.isNotEmpty
                      ? Image.network(
                          _item.photoUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Image loading error: $error');
                            return Container(
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24.h),

              // Product Name with Wishlist Heart
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _item.name.isEmpty ? 'Untitled Product' : _item.name,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).textTheme.headlineSmall?.color ??
                            Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleWishlist,
                    icon: Icon(
                      _isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: _isWishlisted ? Colors.red : Colors.grey,
                      size: 28.sp,
                    ),
                    tooltip: _isWishlisted
                        ? 'Remove from wishlist'
                        : 'Add to wishlist',
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Product Description
              if (_item.description.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).textTheme.titleLarge?.color ??
                            Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...(_item.description.map(
                      (desc) => Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          desc,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color ??
                                Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                      ),
                    )),
                    SizedBox(height: 16.h),
                  ],
                ),

              // Stock Information
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.blue[600], size: 20),
                    SizedBox(width: 8.w),
                    Text(
                      'In Stock: ${_item.qtyAvailable} available',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors
                            .blue[800], // Keep black/dark blue for light blue background
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Inquiry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _makeInquiry,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Make Inquiry'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  void _makeInquiry() {
    // Check if user is logged in
    if (widget.isPublicView) {
      _showLoginRequiredDialog('make inquiries');
      return;
    }

    _showInquiryDialog();
  }

  void _showInquiryDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
            SizedBox(width: 8.w),
            const Text('Make Inquiry'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item: ${_item.name}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Your inquiry message',
                    hintText:
                        'Ask about pricing, availability, specifications, etc.',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitInquiry(messageController.text.trim()),
            child: const Text('Send Inquiry'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitInquiry(String message) async {
    if (message.isEmpty) {
      ModernSnackBar.error(context, 'Please enter your inquiry message');
      return;
    }

    try {
      // Get user data for the inquiry
      final userService = UserService();
      final userData = await userService.getUserData();

      final inquiry = Inquiry(
        itemId: _item.iid,
        itemName: _item.name,
        itemPhotoUrl: _item.photoUrl,
        userId: userData['_id'] ?? '',
        userName: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'
            .trim(),
        message: message,
        createdAt: DateTime.now(),
      );

      await _itemService.createInquiry(inquiry);
      Navigator.pop(context); // Close dialog
      ModernSnackBar.success(context, 'Inquiry sent successfully!');
    } catch (e) {
      ModernSnackBar.error(context, ErrorHandler.getUserFriendlyMessage(e));
    }
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
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleWishlist() async {
    // Check if user is logged in
    if (widget.isPublicView) {
      _showLoginRequiredDialog('add items to wishlist');
      return;
    }

    try {
      if (_isWishlisted) {
        await _itemService.removeFromWishlist(_item.iid);
        ModernSnackBar.success(context, 'Removed from wishlist');
      } else {
        await _itemService.addToWishlist(_item.iid);
        ModernSnackBar.success(context, 'Added to wishlist');
      }
      // Refresh wishlist status
      await _checkWishlistStatus();
    } catch (e) {
      ModernSnackBar.error(context, ErrorHandler.getUserFriendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show different UI for viewers (buyers) vs editors/admins
    if (_userType == 'viewer' || _userType == 'public') {
      return _buildBuyerView();
    }

    return Scaffold(
      appBar: AppBar(title: Text(_item.name.isEmpty ? 'Item' : _item.name)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _imagePreview(),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _photoCtrl,
                  enabled: false, // Always disabled, use image picker instead
                  decoration: InputDecoration(
                    labelText: 'Photo URL/Path',
                    border: const OutlineInputBorder(),
                    suffixIcon: _canEdit
                        ? IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: _showImageSourceDialog,
                          )
                        : const Icon(Icons.lock),
                    hintText: 'Use image picker above to select image',
                  ),
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _nameCtrl,
                  enabled: _canEdit,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    suffixIcon: !_canEdit ? const Icon(Icons.lock) : null,
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Required' : null,
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: _descCtrl,
                  enabled: _canEdit,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Description (one per line or comma-separated)',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    suffixIcon: !_canEdit ? const Icon(Icons.lock) : null,
                  ),
                  validator: (v) => _parseDesc(v ?? '').isEmpty
                      ? 'Add at least one line'
                      : null,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyTotalCtrl,
                        enabled: _canEdit,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qty Total',
                          border: const OutlineInputBorder(),
                          suffixIcon: !_canEdit ? const Icon(Icons.lock) : null,
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
                        controller: _qtyAvailableCtrl,
                        enabled: _canEdit,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qty Available',
                          border: const OutlineInputBorder(),
                          suffixIcon: !_canEdit ? const Icon(Icons.lock) : null,
                        ),
                        validator: (v) {
                          final a = int.tryParse((v ?? '').trim());
                          final t = int.tryParse(_qtyTotalCtrl.text.trim());
                          if (a == null || a < 0) return 'Invalid';
                          if (t != null && a > t) return '> total';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: _isSaving
                      ? null
                      : (_isItemInactive && widget.isFromArchive)
                      ? _toggleActiveAndSave
                      : _canEdit
                      ? _toggleActiveAndSave
                      : null,
                ),
                if (!_canEdit && _isItemInactive) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[600],
                          size: 20,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This item is archived. You can only toggle it to active to edit.',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16.h),
                if (_userType == 'viewer')
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                          size: 20,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'As a viewer, you can browse items but cannot edit them. Contact an admin or editor to make changes.',
                            style: TextStyle(
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color ??
                                  Colors.blue[800],
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (_isSaving || !_canEdit) ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving || !_isItemInactive
                        ? null
                        : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      _isItemInactive
                          ? 'Delete Item'
                          : 'Delete (Archive First)',
                    ),
                  ),
                ),
                if (!_isItemInactive)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Only archived items can be deleted. Please archive this item first.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
