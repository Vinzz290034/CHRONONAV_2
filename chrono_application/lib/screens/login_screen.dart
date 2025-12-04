import 'package:flutter/material.dart';
// Assuming your ApiService file is in the 'services' directory one level up
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisterTap;
  final void Function(Map<String, dynamic> userData) onLoginSuccess;

  const LoginScreen({
    required this.onRegisterTap,
    required this.onLoginSuccess,
    super.key,
  });

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  // Define brand colors consistent with the registration screen (These are constants, not theme-dependent)
  final Color chrononaPrimaryColor = const Color.fromARGB(255, 51, 153, 243);
  final Color chrononaAccentColor = const Color.fromARGB(255, 49, 156, 251);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userData = await _apiService.loginUser(
        // CRITICAL FIX: Ensure email is trimmed to prevent database lookup errors
        // caused by trailing spaces from web registration.
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // 🎯 FIX 1: Access the correct user data key, which is 'name' from the database.
        final String greetingName =
            (userData['name'] as String?)?.split(' ').first ?? 'User';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome, $greetingName! Login successful.'),
            backgroundColor: chrononaPrimaryColor,
          ),
        );

        widget.onLoginSuccess(userData);
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
    // FIX 1: Replace deprecated onBackground/background with onSurface/surface
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    // FIX 2: Use .withOpacity() replacement for opacity control
    final Color secondaryTextColor = Theme.of(
      context,
      // ignore: deprecated_member_use
    ).colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      // FIX 3: Replace deprecated background with surface
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),

              // --- 1. Logo and Title ---
              Image.asset('assets/images/chrononav_logo.jpg', height: 80),
              const SizedBox(height: 20),
              Text(
                'ChronoNav',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Navigate your campus with ease.',
                style: TextStyle(fontSize: 16, color: secondaryTextColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              // --- 2. Login Fields ---
              _buildMinimalistInputField(
                context,
                controller: _emailController,
                label: 'Email Address',
                hintText: 'Enter your email address',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.contains('@')
                    ? null
                    : 'Enter a valid email address.',
              ),

              _buildMinimalistInputField(
                context,
                controller: _passwordController,
                label: 'Password',
                hintText: 'Enter your password',
                isPassword: true,
                validator: (value) =>
                    value!.isEmpty ? 'Password is required.' : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    debugPrint('Forgot Password clicked');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: chrononaAccentColor, fontSize: 14),
                  ),
                ),
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

              // --- 3. Login Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
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
                        'Log In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // --- 4. Register Link ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    // ignore: deprecated_member_use
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                  GestureDetector(
                    onTap: widget.onRegisterTap,
                    child: Text(
                      'Register here',
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

  // --- REUSABLE INPUT FIELD WIDGET ---
  Widget _buildMinimalistInputField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    // FIX 4: Use onSurface instead of deprecated onBackground
    final Color textColor = Theme.of(context).colorScheme.onSurface;

    final Color hintColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[600]!
        : Colors.grey[400]!;
    final Color dividerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[300]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            obscureText: isPassword,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 16, color: textColor),
            validator:
                validator ??
                (value) => value!.isEmpty ? 'This field is required.' : null,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 15,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: dividerColor, width: 1.0),
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
}
