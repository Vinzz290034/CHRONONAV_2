// lib/screens/registration_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Adjust path as needed

class MinimalistRegistrationScreen extends StatefulWidget {
  final VoidCallback onLoginTap;

  const MinimalistRegistrationScreen({required this.onLoginTap, super.key});

  @override
  // Corrected State class name
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

  // Color constants
  final Color chrononaPrimaryColor = const Color(0xFF007A5A);
  final Color chrononaAccentColor = const Color(0xFF4CAF50);

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
    if (!_formKey.currentState!.validate()) {
      return; // Stop if the form is invalid
    }
    // Convert role to lowercase for API if needed, but using as-is for now
    String apiRole = _selectedRole?.toLowerCase() ?? '';

    if (apiRole.isEmpty) {
      setState(() => _errorMessage = 'Please select a role.');
      return; // Stop if no role is selected
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
        role: apiRole, // Use lowercase role if your backend expects it
        course: _courseController.text,
        department: _departmentController.text,
      );

      // Registration successful!
      if (mounted) {
        // Show success message and navigate to Login
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
      // Handle the error thrown by ApiService
      if (mounted) {
        setState(() {
          // Display a user-friendly error message
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
          // USE THE CALLBACK FOR THE BACK BUTTON
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
              ),
              _buildMinimalistInputField(
                controller: _emailController,
                label: 'Enter your email',
                hintText: 'name@school.edu',
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.contains('@') ? null : 'Enter a valid email.',
              ),
              _buildMinimalistInputField(
                controller: _passwordController,
                label: 'Create a password',
                hintText: 'Minimum 8 characters',
                isPassword: true,
                validator: (value) => value!.length >= 8
                    ? null
                    : 'Password must be 8+ characters.',
              ),
              const SizedBox(height: 10),

              // Select role (student, faculty) - Dropdown
              _buildMinimalistDropdown(
                label: 'Select Role',
                value: _selectedRole,
                // NOTE: 'user' and 'faculty' might be safer to align with your database enum (image_e6872b.png)
                items: const ['Student', 'Faculty'],
                onChanged: (String? newValue) =>
                    setState(() => _selectedRole = newValue),
                primaryColor: chrononaPrimaryColor,
              ),

              _buildMinimalistInputField(
                controller: _courseController,
                label: 'Your course',
                hintText: 'e.g., BSIT, BSEE',
              ),
              _buildMinimalistInputField(
                controller: _departmentController,
                label: 'Your department',
                hintText: 'e.g., Computer Science',
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
                    // USE THE CALLBACK FOR THE LOGIN HERE LINK
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
            validator:
                validator ??
                (value) => value!.isEmpty ? 'This field is required.' : null,
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
            items: items
                .map(
                  (String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 16)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            validator: (value) =>
                value == null ? 'Please select a role.' : null,
          ),
        ],
      ),
    );
  }
}
