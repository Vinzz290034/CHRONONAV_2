import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Handles JWT for secure calls

class ChangePasswordScreen extends StatefulWidget {
  final VoidCallback onBackToSettings;
  final String userEmail;

  const ChangePasswordScreen({
    required this.onBackToSettings,
    required this.userEmail,
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State for toggling password visibility
  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isLoading = false;

  // Chronona color - defined outside build for performance
  final Color chrononaPrimaryColor = const Color(0xFF007A5A); // Deep Green/Teal

  // Initialize the API Service for secure token-based communication
  // NOTE: Assuming ApiService is available in the environment.
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : chrononaPrimaryColor, // Use theme error color
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _submitChangePassword() async {
    // Validate all form fields
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (newPassword != confirmPassword) {
        _showSnackbar(
          'New password and confirmation do not match.',
          isError: true,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint(
          'Attempting token-based password change for user: ${widget.userEmail}',
        );

        // Use ApiService to make the secure call
        // NOTE: This call is mocked/assumed to exist in the environment
        await _apiService.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

        // Success handling
        _showSnackbar('Password successfully updated!');

        // Clear inputs
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Navigate back to settings screen
        if (mounted) {
          // Use a small delay to allow the snackbar to be seen
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onBackToSettings();
        }
      } on Exception catch (e) {
        // Error handling for exceptions thrown by ApiService
        debugPrint('API Error during password change: $e');
        String errorMessage = e.toString().replaceFirst('Exception: ', '');

        if (errorMessage.contains('Incorrect current password') ||
            errorMessage.contains('authentication error')) {
          errorMessage = 'Incorrect current password or authentication error.';
        } else if (errorMessage.contains('token is invalid')) {
          errorMessage = 'Authentication session expired. Please log in again.';
        }

        _showSnackbar(errorMessage, isError: true);
      } catch (e) {
        // Catch any other unexpected errors (e.g., parsing, network fail)
        debugPrint('Generic error during password change: $e');
        _showSnackbar(
          'A general error occurred. Please check your network connection.',
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Helper Widget for Password TextFields
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback toggleVisibility,
    FormFieldValidator<String>? validator,
    bool isEnabled = true,
  }) {
    final Color hintColor = Theme.of(context).hintColor;

    // Modernized InputDecoration: Consistent rounded borders, clean focus color
    return TextFormField(
      controller: controller,
      enabled: isEnabled,
      obscureText: !isVisible,
      style: Theme.of(context).textTheme.bodyLarge, // Ensure text is visible
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintColor),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
        // Default border style
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0), // Slightly more rounded
          borderSide: BorderSide(color: hintColor.withAlpha(50)),
        ),
        // Enabled border (default look)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: hintColor.withAlpha(50), width: 1.0),
        ),
        // Focused border (uses primary color)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: chrononaPrimaryColor, // Use the brand color for focus
            width: 2.0,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: hintColor,
          ),
          onPressed: isEnabled ? toggleVisibility : null,
        ),
      ),
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label.';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters.';
            }
            return null;
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color hintColor = Theme.of(context).hintColor;

    return Scaffold(
      // Ensure the background is theme-compliant (usually white/light grey or black/dark grey)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // Modernized back icon
          onPressed: _isLoading ? null : widget.onBackToSettings,
        ),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        // Elevation set to 0 for a modern, flat look
        elevation: 0,
        backgroundColor:
            Colors.transparent, // Use transparent for a unified look
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- Visual Header/Icon ---
              Icon(Icons.lock_reset, size: 80, color: chrononaPrimaryColor),
              const SizedBox(height: 16),
              const Text(
                'Security Update',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new secure one.',
                style: TextStyle(fontSize: 16, color: hintColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- Current Password Field ---
              _buildPasswordField(
                label: 'Current Password',
                controller: _currentPasswordController,
                isEnabled: !_isLoading,
                isVisible: _isCurrentPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 24), // Increased spacing
              // --- New Password Field ---
              _buildPasswordField(
                label: 'New Password',
                controller: _newPasswordController,
                isEnabled: !_isLoading,
                isVisible: _isNewPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
              ),
              const SizedBox(height: 24), // Increased spacing
              // --- Confirm New Password Field ---
              _buildPasswordField(
                label: 'Confirm New Password',
                controller: _confirmPasswordController,
                isEnabled: !_isLoading,
                isVisible: _isConfirmPasswordVisible,
                toggleVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 48), // Increased spacing before button
              // --- Submit Button (Modernized) ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  // Use a slightly softer color or the primary brand color
                  backgroundColor: chrononaPrimaryColor,
                  minimumSize: const Size(double.infinity, 56), // Taller button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // Rounded corners matching input fields
                  ),
                  elevation: _isLoading
                      ? 0
                      : 4, // Subtle elevation when not loading
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors
                                .white, // White always works well on the dark green
                          ),
                          strokeWidth: 3.0,
                        ),
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
