import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:rizz_mobile/providers/authentication_provider.dart';
import 'package:rizz_mobile/theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class PhotoGalleryPage extends StatefulWidget {
  final List<String> initialImageUrls;

  const PhotoGalleryPage({super.key, required this.initialImageUrls});

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  late List<String> _imageUrls;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
    _getUserId();
  }

  void _getUserId() {
    final authProvider = context.read<AuthenticationProvider>();
    _userId = authProvider.userId;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (_imageUrls.length >= 6) {
        _showSnackBar('Tối đa 6 ảnh được phép');
        return;
      }

      final XFile? pickedImage = await _picker.pickImage(source: source);
      if (pickedImage == null) return;

      setState(() {
        _isLoading = true;
      });

      // Upload to Firebase Storage
      String imageUrl = await _uploadImageToStorage(File(pickedImage.path));

      setState(() {
        _imageUrls.add(imageUrl);
        _hasChanges = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<String> _uploadImageToStorage(File imageFile) async {
    try {
      if (_userId == null) {
        throw Exception('User ID not available');
      }

      final String fileName = '${const Uuid().v4()}.jpg';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child(_userId!)
          .child(fileName);

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(imageFile);

      // Get download URL after upload completes
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<void> _updateFirestore() async {
    try {
      if (_userId == null) {
        throw Exception('User ID not available');
      }

      setState(() => _isLoading = true);

      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'imageUrls': _imageUrls,
      });

      setState(() {
        _hasChanges = false;
        _isLoading = false;
      });

      _showSnackBar('Đã lưu thay đổi');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Lỗi khi cập nhật: $e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
      _hasChanges = true;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final String item = _imageUrls.removeAt(oldIndex);
      _imageUrls.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<bool> _showSaveDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu thay đổi?'),
        content: const Text('Bạn có muốn lưu thay đổi về vị trí ảnh không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Không', style: TextStyle(color: context.onSurface)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: context.primary),
            child: Text('Lưu', style: TextStyle(color: context.onPrimary)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: context.primary),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: context.primary),
                title: const Text('Chọn từ kho ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        if (_hasChanges) {
          final shouldSave = await _showSaveDialog();
          if (shouldSave) {
            await _updateFirestore();
          }
        }
        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý ảnh'),
          centerTitle: true,
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _isLoading ? null : _updateFirestore,
                tooltip: 'Lưu thay đổi',
              ),
          ],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instructions
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ảnh hồ sơ của bạn',
                          style: AppTheme.headline4.copyWith(
                            color: context.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kéo và thả để sắp xếp lại ảnh. Ảnh đầu tiên sẽ là ảnh đại diện.',
                          style: TextStyle(
                            color: context.onSurface.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Tối đa 6 ảnh (${_imageUrls.length}/6)',
                          style: TextStyle(
                            color: context.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reorderable Grid
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Reorderable photo items
                          Expanded(
                            child: ReorderableWrap(
                              spacing: 12,
                              runSpacing: 12,
                              onReorder: _onReorder,
                              children: [
                                for (int i = 0; i < _imageUrls.length; i++)
                                  _buildPhotoItem(i),
                              ],
                            ),
                          ),

                          // Non-draggable "Add Photo" tile
                          if (_imageUrls.length < 6)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                key: const ValueKey('add_photo'),
                                onTap: _showImageSourceBottomSheet,
                                child: Container(
                                  width: double.infinity,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: context.outline.withOpacity(0.5),
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        color: context.primary,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Thêm ảnh',
                                        style: TextStyle(
                                          color: context.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Loading indicator
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    final imageUrl = _imageUrls[index];
    final isProfilePhoto = index == 0;

    return Stack(
      key: ValueKey(imageUrl),
      children: [
        Container(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          height: (MediaQuery.of(context).size.width - 48) / 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isProfilePhoto
                  ? context.primary
                  : context.outline.withOpacity(0.5),
              width: isProfilePhoto ? 2 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: context.primary.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: context.primary.withOpacity(0.1),
                child: Center(child: Icon(Icons.error, color: context.primary)),
              ),
            ),
          ),
        ),

        // Profile photo indicator
        if (isProfilePhoto)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ảnh đại diện',
                style: TextStyle(
                  color: context.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
