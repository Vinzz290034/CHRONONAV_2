import 'package:flutter/material.dart';
import 'dart:io';
// CRITICAL: Import the image_picker package
import 'package:image_picker/image_picker.dart';
// CRITICAL: Import your ApiService class
// FIX 1 (ASSUMPTION): Change path to match your actual file structure, e.g., '../services/api_service.dart'
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  // initialUserData comes from the ProfileScreen and contains the user's data
  final Map<String, dynamic> initialUserData;

  // FIX: Parameter 'key' converted to super parameter for modern Dart syntax
  const EditProfileScreen({super.key, required this.initialUserData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  // The ApiService class and constructor are now resolved by the fixed import
  final ApiService _apiService = ApiService();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _departmentController;
  late TextEditingController _courseController;

  late String _currentAvatarPath;
  File? _newProfilePhoto;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(
      text: widget.initialUserData['fullname'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialUserData['email'] ?? '',
    );
    _departmentController = TextEditingController(
      text: widget.initialUserData['department'] ?? '',
    );
    _courseController = TextEditingController(
      text: widget.initialUserData['course'] ?? '',
    );

    _currentAvatarPath =
        widget.initialUserData['photo_url'] ??
        'https://placehold.co/150x150/007A5A/FFFFFF/png?text=Avatar';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  bool _isLocalFileSelected() {
    return _newProfilePhoto != null;
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final selectedFile = File(pickedFile.path);
      setState(() {
        _currentAvatarPath = pickedFile.path;
        _newProfilePhoto = selectedFile;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image selected successfully. Click "Save Changes" to upload.',
          ),
          backgroundColor: Colors.blueGrey,
        ),
      );
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUserMap = await _apiService.updateProfile(
        name: _fullNameController.text,
        course: _courseController.text,
        department: _departmentController.text,
        profilePhoto: _newProfilePhoto,
      );

      final newPhotoUrl = updatedUserMap['photo_url'] as String;

      setState(() {
        _newProfilePhoto = null;
        _currentAvatarPath = newPhotoUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(updatedUserMap);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to save profile. Please try again.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      // FIX: Replaced print with debugPrint (or a proper logger)
      debugPrint('Error during profile update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildAvatarSection() {
    ImageProvider? imageProvider;
    Widget placeholderIcon = const Icon(
      Icons.person,
      size: 50,
      color: Color(0xFF007A5A),
    );

    // If a local file is selected, use FileImage
    if (_isLocalFileSelected()) {
      imageProvider = FileImage(_newProfilePhoto!);
    }
    // If the current path is a URL (from server), use NetworkImage
    else if (_currentAvatarPath.startsWith('http')) {
      // Catch potential NetworkImage loading errors silently here, or handle in the image builder
      try {
        imageProvider = NetworkImage(_currentAvatarPath);
      } catch (e) {
        // Fallback to placeholder if URL is malformed or throws an immediate error
        imageProvider = null;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 32.0),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              // FIX: Replaced deprecated .withOpacity with .withAlpha
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((255 * 0.1).round()),
              backgroundImage: imageProvider,
              child: imageProvider == null ? placeholderIcon : null,
            ),
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String labelText,
    required TextEditingController controller,
    required Icon icon,
    String? hintText,
    bool isReadOnly = false,
  }) {
    final bool isEmail = labelText.toLowerCase().contains('email');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: TextFormField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          prefixIcon: icon,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $labelText';
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildAvatarSection(),

                  _buildTextField(
                    labelText: 'Full Name',
                    controller: _fullNameController,
                    icon: const Icon(Icons.person_outline),
                    hintText: 'Enter your full name',
                  ),

                  _buildTextField(
                    labelText: 'Email Address',
                    controller: _emailController,
                    icon: const Icon(Icons.email_outlined),
                    hintText: 'user@example.com',
                    isReadOnly: true,
                  ),

                  _buildTextField(
                    labelText: 'Student ID / Department',
                    controller: _departmentController,
                    icon: const Icon(Icons.badge_outlined),
                    hintText: 'Enter your Student ID or Department',
                  ),

                  _buildTextField(
                    labelText: 'Course/Program',
                    controller: _courseController,
                    icon: const Icon(Icons.school_outlined),
                    hintText: 'Enter your course or program',
                  ),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3.0,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
