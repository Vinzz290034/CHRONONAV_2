// lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
// Note: You would typically import ApiService for the actual API call here
// import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  // Callback to return to the previous screen (LoginScreen)
  final VoidCallback onBackToLogin;

  const ForgotPasswordScreen({required this.onBackToLogin, super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _message;

  // Use the same brand colors as LoginScreen
  final Color chrononaPrimaryColor = const Color(
    0xFF007A5A,
  ); // Assuming Green primary
  final Color chrononaAccentColor = const Color(0xFF319CFB); // Accent blue

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    // 🎯 TODO: Implement actual API call to send reset email
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _message =
          'Password reset link sent to ${_emailController.text.trim()}. Check your email.';
    });

    // After success, display message and allow user to go back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_message!), backgroundColor: chrononaPrimaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color hintColor = Theme.of(context).hintColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // --- Logo and Title Section ---
              Image.asset('assets/images/chrononav_logo.jpg', height: 70),
              const SizedBox(height: 10),
              Text(
                'Reset your password', //
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // --- Reset Card (Matching Login Screen Style) ---
              Card(
                elevation: 15,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email Field
                        _buildResetInputField(
                          context,
                          controller: _emailController,
                          hintText: 'Enter your email address', //
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              value!.contains('@') && value.isNotEmpty
                              ? null
                              : 'Enter a valid email address.',
                        ),

                        const SizedBox(height: 16),

                        // Action Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                chrononaAccentColor, // Use a distinguishing accent color
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
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
                                  'Send Reset Link', //
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // Back to Login Link
                        GestureDetector(
                          onTap: widget.onBackToLogin,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Back to Login', //
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Helper Text
                        Padding(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: Text(
                            'Enter your email address and we\'ll send you a link to reset your password.', //
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: hintColor),
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
    );
  }

  // Helper function for the modern input field (copied from the login screen logic)
  Widget _buildResetInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Theme.of(context).hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 10,
        ),
      ),
    );
  }
}
