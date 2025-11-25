import 'package:flutter/material.dart';

/// Basic Auth Provider for managing user authentication state.
/// This is required to satisfy the import in add_pdf_screen.dart.
class AuthProvider with ChangeNotifier {
  // Mock values for demonstration
  String? _userId = 'mock_user_123';
  bool _isAuthenticated = true;

  String? get userId => _userId;
  bool get isAuthenticated => _isAuthenticated;

  // Mock sign in/out methods
  void signIn(String id) {
    _userId = id;
    _isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    _userId = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
