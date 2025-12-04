// lib/screens/registration_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Adjust path as needed

class MinimalistRegistrationScreen extends StatefulWidget {
  final VoidCallback onLoginTap;

  const MinimalistRegistrationScreen({required this.onLoginTap, super.key});

  @override
  State<MinimalistRegistrationScreen> createState() =>
      _MinimalistRegistrationScreenState();
}

class _MinimalistRegistrationScreenState
    extends State<MinimalistRegistrationScreen> {
  // --- Controllers for form input ---
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();

  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  String? _selectedRole;
  bool _isLoading = false;
  String? _errorMessage;

  // Constants
  final Color chrononaPrimaryColor = const Color(0xFF007A5A);
  final Color chrononaAccentColor = const Color(0xFF4CAF50);
  final int maxInputLength = 100; // Matches server's varchar(100)

  // Explicitly defining roles to match server ENUM
  final List<String> displayRoles = [
    'User',
    'Faculty',
    'Admin',
  ]; // Roles for display

  // Maps display role to the lowercase value expected by the backend
  String? get apiRole => _selectedRole?.toLowerCase();

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _courseController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  // --- Registration Logic ---
  void _handleRegistration() async {
    // 1. Client-Side Validation (uses all the new validators)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional check for role selection (covered by validator, but safe to check)
    if (apiRole == null || apiRole!.isEmpty) {
      setState(() => _errorMessage = 'Please select a role.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    try {
      await _apiService.registerUser(
        fullname: _fullnameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: apiRole!, // Guaranteed non-null by validation
        course: _courseController.text,
        department: _departmentController.text,
      );

      // Registration successful!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful! You can now log in.'),
            backgroundColor: chrononaPrimaryColor,
          ),
        );

        // NAVIGATE TO LOGIN
        widget.onLoginTap();
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          // Display a user-friendly error message from the server response
          _errorMessage = e.toString().replaceFirst(
            'Exception: ',
            'Registration Failed: ',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: widget.onLoginTap,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey, // Use the form key for validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),

              // --- Logo and Title ---
              Image.asset('assets/images/chrononav_logo.jpg', height: 60),
              const SizedBox(height: 10),
              const Text(
                'Create Your ChronoNav Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Start navigating your schedule.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Registration Fields ---
              _buildMinimalistInputField(
                controller: _fullnameController,
                label: 'Your full name',
                hintText: 'Enter your name',
                // Added Length Validation
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Full Name is required.';
                  }
                  // FIX 1: Removed unnecessary braces around maxInputLength
                  if (value.length > maxInputLength) {
                    return 'Max $maxInputLength characters allowed.';
                  }
                  return null;
                },
              ),
              _buildMinimalistInputField(
                controller: _emailController,
                label: 'Enter your email',
                hintText: 'name@school.edu',
                keyboardType: TextInputType.emailAddress,
                // Enhanced Email Validation
                validator: (value) {
                  const pattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$';
                  final regex = RegExp(pattern);
                  if (value == null || !regex.hasMatch(value)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              _buildMinimalistInputField(
                controller: _passwordController,
                label: 'Create a password',
                hintText: 'Minimum 8 characters',
                isPassword: true,
                // Enhanced Password Validation (Min 8 chars)
                validator: (value) => value != null && value.length >= 8
                    ? null
                    : 'Password must be 8+ characters.',
              ),
              const SizedBox(height: 10),

              // Select role (Dropdown with validated options)
              _buildMinimalistDropdown(
                label: 'Select Role',
                value: _selectedRole,
                items: displayRoles, // Uses the strictly defined roles
                onChanged: (String? newValue) =>
                    setState(() => _selectedRole = newValue),
                primaryColor: chrononaPrimaryColor,
              ),

              _buildMinimalistInputField(
                controller: _courseController,
                label: 'Your course',
                hintText: 'e.g., BSIT, BSEE',
                // Added Length Validation
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Course is required.';
                  }
                  // FIX 2: Removed unnecessary braces around maxInputLength
                  if (value.length > maxInputLength) {
                    return 'Max $maxInputLength characters allowed.';
                  }
                  return null;
                },
              ),
              _buildMinimalistInputField(
                controller: _departmentController,
                label: 'Your department',
                hintText: 'e.g., Computer Science',
                // Added Length Validation
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Department is required.';
                  }
                  // FIX 3: Removed unnecessary braces around maxInputLength
                  if (value.length > maxInputLength) {
                    return 'Max $maxInputLength characters allowed.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // --- Error Message Display ---
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // --- Register Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: chrononaPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  elevation: 3,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 25),

              // --- Login Link ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  GestureDetector(
                    onTap: widget.onLoginTap,
                    child: Text(
                      'Login here',
                      style: TextStyle(
                        color: chrononaAccentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable Input Field Widget ---
  Widget _buildMinimalistInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 16),
            validator: validator, // Use provided or default validator
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400]),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 15,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: chrononaPrimaryColor, width: 2.0),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable Dropdown Field Widget ---
  Widget _buildMinimalistDropdown({
    required String label,
    String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 15,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 2.0),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
              focusedErrorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
            ),
            hint: const Text('Select your role'),
            isExpanded: true,
            // Maps the display role (e.g., 'User') to the DropdownMenuItem
            items: items
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 16)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            // Ensures a role is selected (prevents blank role in API call)
            validator: (value) =>
                value == null ? 'Please select a role.' : null,
          ),
        ],
      ),
    );
  }
}
