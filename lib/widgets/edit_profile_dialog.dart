import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../core/auth_service.dart';

class EditProfileDialog extends StatefulWidget {
  final String? currentUsername;
  final String? currentProfileImage;

  const EditProfileDialog({
    super.key,
    this.currentUsername,
    this.currentProfileImage,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _usernameCtrl;
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  XFile? _selectedImageFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.currentUsername ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  ImageProvider? _buildProfileImageProvider(String imageUrl) {
    // Handle base64 data URL
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    }
    // Handle regular network URL
    return NetworkImage(imageUrl);
  }

  Future<void> _pickImage() async {
    try {
      // Request permission hanya di mobile (Android/iOS)
      // Deteksi platform dengan aman tanpa import dart:io di web
      if (!kIsWeb) {
        try {
          // Try to request permission - only works on mobile/desktop with permission_handler
          final status = await Permission.photos.request();

          if (status.isDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Izin galeri ditolak')),
              );
            }
            return;
          }

          if (status.isPermanentlyDenied) {
            openAppSettings();
            return;
          }
        } catch (e) {
          // Permission handler might not be available on some platforms
          // Just continue with image picker
        }
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImageFile = pickedFile;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error memilih gambar: $e');
      }
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameCtrl.text.trim();

    if (username.isEmpty) {
      setState(() => _errorMessage = 'Username tidak boleh kosong');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('User tidak ditemukan');

      String? profileImageLink = widget.currentProfileImage;

      // Convert image ke base64 jika ada image baru
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final base64String = base64Encode(bytes);
        profileImageLink = 'data:image/jpeg;base64,$base64String';
      }

      // Update profil user
      await _authService.updateUserProfile(
        uid: currentUser.uid,
        username: username,
        profileImage: profileImageLink,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Edit Profil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Foto Profil
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: cs.primary,
                      backgroundImage: _selectedImageFile != null
                          ? NetworkImage(_selectedImageFile!.path)
                          : (widget.currentProfileImage != null
                                ? _buildProfileImageProvider(
                                    widget.currentProfileImage!,
                                  )
                                : null),
                      child:
                          _selectedImageFile == null &&
                              widget.currentProfileImage == null
                          ? Text(
                              (widget.currentUsername?[0] ?? 'A').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Username
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: cs.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 12),

            // Error message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
