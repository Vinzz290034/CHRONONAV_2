// lib/screens/deactivate_account_screen.dart

import 'package:flutter/material.dart';
// 1. ✅ Import ApiService and remove unused imports
import '../services/api_service.dart';
// import 'package:http/http.dart' as http; // Removed
// import 'dart:convert'; // Removed

class DeactivateAccountScreen extends StatefulWidget {
  final VoidCallback onBackToSettings;
  final VoidCallback onDeactivationSuccess;
  final String userEmail;

  const DeactivateAccountScreen({
    required this.onBackToSettings,
    required this.onDeactivationSuccess,
    required this.userEmail,
    super.key,
  });

  @override
  State<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState extends State<DeactivateAccountScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final Color chrononaPrimaryColor = const Color(0xFF007A5A);

  // 2. ✅ Initialize ApiService
  final ApiService _apiService = ApiService();

  // NOTE: Remove the unused _apiUrl string here.

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : chrononaPrimaryColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleDeactivation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentPassword = _passwordController.text;

      // 3. ✅ FIX: Use the secure ApiService method
      await _apiService.deactivateAccount(currentPassword: currentPassword);

      // Success handling
      _showSnackbar(
        'Account successfully deactivated. You are now logged out.',
        isError: false,
      );

      // CRITICAL: Call the success callback to force the AuthWrapper back to login state
      if (mounted) {
        widget.onDeactivationSuccess();
      }
    } on Exception catch (e) {
      // 4. ✅ Handle exceptions thrown by the ApiService
      debugPrint('API Error during deactivation: $e');
      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (errorMessage.contains('Incorrect current password')) {
        errorMessage = 'Incorrect current password.';
      } else if (errorMessage.contains('Authentication token is missing') ||
          errorMessage.contains('token is invalid')) {
        errorMessage = 'Session expired. Please log in again.';
      }

      _showSnackbar(errorMessage, isError: true);
    } catch (e) {
      debugPrint('Generic error during deactivation: $e');
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

  @override
  Widget build(BuildContext context) {
    // UI code remains the same as it was already well-structured
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _isLoading ? null : widget.onBackToSettings,
        ),
        title: const Text('Deactivate Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'WARNING: Account Deactivation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This action is permanent and will prevent you from logging in again with this account (${widget.userEmail}).\n\nTo confirm deactivation, please enter your current password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[700]),
              ),
              const SizedBox(height: 30),

              // --- Password Confirmation Field ---
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password to confirm.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // --- Deactivate Button ---
              ElevatedButton(
                onPressed: _isLoading ? null : _handleDeactivation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3.0,
                        ),
                      )
                    : const Text(
                        'Deactivate Account',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              // --- Cancel Button ---
              TextButton(
                onPressed: _isLoading ? null : widget.onBackToSettings,
                child: Text(
                  'Cancel',
                  style: TextStyle(color: chrononaPrimaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
