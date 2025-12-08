import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// --- SERVICE/MODEL IMPORTS ---
// Must be provided in the project structure
import 'services/api_service.dart';

// --- Screen Imports ---
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/security_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/registration_screen.dart'; // Assuming this is MinimalistRegistrationScreen
import 'screens/deactivate_account_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/help_center_screen.dart'; // Import for the new screen

void main() {
  // Ensure Flutter is initialized before accessing SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 WRAP THE APP WITH MULTIPROVIDER
  runApp(
    MultiProvider(
      providers: [
        // 🟢 Provider Injection: Makes the ApiService available to all child widgets
        Provider<ApiService>(
          // Creates a singleton instance of the service
          create: (_) => ApiService(),
        ),
      ],
      child: const ChronoNavApp(),
    ),
  );
}

// --- 1. CHRONONAVAPP: Theme Management Root ---

class ChronoNavApp extends StatefulWidget {
  const ChronoNavApp({super.key});

  @override
  State<ChronoNavApp> createState() => _ChronoNavAppState();
}

class _ChronoNavAppState extends State<ChronoNavApp> {
  ThemeMode _themeMode = ThemeMode.system; // Start with system preference

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color chrononaPrimaryColor = Color(0xFF007A5A);

    return MaterialApp(
      title: 'ChronoNav App',
      themeMode: _themeMode,

      // Define Light Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: chrononaPrimaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // Define Dark Theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: chrononaPrimaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      debugShowCheckedModeBanner: false,
      // Pass the theme controls down to AuthWrapper
      home: AuthWrapper(
        currentThemeMode: _themeMode,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

// --- 2. AUTHWRAPPER: State and Navigation Management ---

class AuthWrapper extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final void Function(bool) toggleTheme;

  const AuthWrapper({
    required this.currentThemeMode,
    required this.toggleTheme,
    super.key,
  });

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

enum AuthState { login, register, dashboard, settings }

class _AuthWrapperState extends State<AuthWrapper> {
  AuthState _authState = AuthState.login;

  // ⚠️ FOR TESTING: Use dummy data
  Map<String, dynamic>? _currentUserData = {
    'fullname': 'Chrono User',
    'email': 'keyses@example.com',
    'student_id': '123456',
    'course': 'Computer Science',
    'department': 'N/A',
    'photo_url': null,
    'bio': 'Learning Flutter development.',
  };

  // --- Persistence Methods ---

  // 🟢 Save the user data to local storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = json.encode(
      userData,
    ); // Serialize map to JSON string
    await prefs.setString('chrono_user_profile', userDataString);
    debugPrint('Profile data saved to local storage.');
  }

  // 🟢 Load the user data from local storage
  Future<Map<String, dynamic>?> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('chrono_user_profile');
    if (userDataString != null) {
      debugPrint('Profile data loaded from local storage.');
      // Deserialize the JSON string back into a map
      return json.decode(userDataString) as Map<String, dynamic>;
    }
    debugPrint('No profile data found in local storage.');
    return null;
  }

  // 🟢 Clear user data on logout
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chrono_user_profile');
    debugPrint('Profile data cleared from local storage.');
  }

  // --- Core State Management (AuthState changes) ---
  void _showRegister() {
    setState(() => _authState = AuthState.register);
  }

  // 🎯 MODIFIED: Clear local data on logout
  void _showLogin() {
    setState(() {
      _authState = AuthState.login;
      _currentUserData = null; // Clear user data in memory
      _clearUserData(); // 🟢 Clear local data on logout
      debugPrint('User logged out and local data cleared.');
    });
  }

  void _goBackToDashboard() {
    setState(() => _authState = AuthState.dashboard);
  }

  void _showSettings() {
    setState(() => _authState = AuthState.settings);
  }

  // 🎯 MODIFIED: Check for saved local data on successful login
  void _showDashboard(Map<String, dynamic> userDataFromLogin) async {
    // 🟢 Check if there's saved data from a previous session
    Map<String, dynamic>? savedData = await _loadUserData();

    setState(() {
      // If local data exists, use it (it has the latest profile picture/name)
      // Otherwise, use the data passed from the login process.
      _currentUserData = savedData ?? userDataFromLogin;
      _authState = AuthState.dashboard;
    });
  }

  // 🟢 NEW: Update handler for profile data coming back from ProfileScreen/EditProfileScreen
  void _updateUserProfileData(Map<String, dynamic> newUserData) {
    setState(() {
      _currentUserData = newUserData;
      _saveUserData(newUserData); // Persist the updated data locally
    });
    debugPrint('User profile data updated and saved.');
  }

  void _handleClearCachedData() {
    // ⚠️ IMPORTANT: In a real app, this should clear more than just profile data (e.g., API caches, temporary files)
    _clearUserData();
    // Show a snackbar or dialog to confirm data was cleared.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All local user data and caches have been cleared.'),
      ),
    );
    debugPrint('Clear Cached Data tapped and executed.');
  }

  // 🟢 NEW: Navigation handler for Help Center Screen
  void _handleHelpSupport() {
    _navigateToScreen(const HelpCenterScreen());
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  // Standard pop function to be used for the 'onBack' callbacks
  VoidCallback _onPop() =>
      () => Navigator.of(context).pop();

  void _navigateToSecurity() {
    _navigateToScreen(SecurityScreen(onBackToSettings: _onPop()));
  }

  void _navigateToPrivacy() {
    _navigateToScreen(PrivacyScreen(onBackToSettings: _onPop()));
  }

  void _viewCalendarEventsScreen() {
    setState(() {
      // 🎯 FIX: Change the application state back to the Dashboard/Schedule view.
      _authState = AuthState.dashboard;
    });

    // OPTIONAL: Add debug print for confirmation
    debugPrint('View Calendar Events tapped. Navigating to Dashboard state.');
  }

  // Use the navigation methods directly for the ProfileScreen callbacks
  void _navigateToChangePassword() {
    final userEmail = _currentUserData?['email'] ?? 'default@example.com';
    _navigateToScreen(
      ChangePasswordScreen(onBackToSettings: _onPop(), userEmail: userEmail),
    );
  }

  void _navigateToDeactivateAccount() {
    final userEmail = _currentUserData?['email'] ?? 'default@example.com';
    _navigateToScreen(
      DeactivateAccountScreen(
        onBackToSettings: _onPop(),
        onDeactivationSuccess: _showLogin,
        userEmail: userEmail,
      ),
    );
  }

  void _navigateToProfile() {
    if (_currentUserData == null) return; // Safety check

    _navigateToScreen(
      ProfileScreen(
        onBackToSettings: _onPop(),
        userData: _currentUserData!,
        onUpdateUserData: _updateUserProfileData,
        onChangePasswordTap: _navigateToChangePassword,
        onDeactivateAccountTap: _navigateToDeactivateAccount,
        // 🟢 FIXED: Add the required 'onClearCachedDataTap' argument
        onClearCachedDataTap: _handleClearCachedData,
        onViewCalendarEventsTap:
            _viewCalendarEventsScreen, // Correctly references the state-changing handler
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildDashboard() {
    if (_currentUserData == null) {
      // In case data is unexpectedly null, send user back to login
      WidgetsBinding.instance.addPostFrameCallback((_) => _showLogin());
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DashboardScreen(
      userData: _currentUserData!,
      onSettingsTap: _showSettings,
      onProfileTap: _navigateToProfile,

      // Pass required callbacks:
      onBackToSettings: _onPop(),
      onClearCachedDataTap: _handleClearCachedData,
      onLogout: _showLogin,
      onUpdateUserData: () {
        // This is a no-op function to satisfy the required parameter.
      },
      onChangePasswordTap: _navigateToChangePassword,
      onDeactivateAccountTap: _navigateToDeactivateAccount,
      // 🟢 FIXED: Added the callback that was causing the 'missing_required_argument' error
      onHelpSupportTap: _handleHelpSupport,
    );
  }

  Widget _buildSettings() {
    return SettingsScreen(
      onLogout: _showLogin,
      onBackToDashboard: _goBackToDashboard,
      onProfileTap: _navigateToProfile,
      onSecurityTap: _navigateToSecurity,
      onPrivacyTap: _navigateToPrivacy,
      onChangePasswordTap: _navigateToChangePassword,
      onDeactivateAccountTap: _navigateToDeactivateAccount,
      // Pass Theme Controls
      currentThemeMode: widget.currentThemeMode,
      onToggleDarkMode: widget.toggleTheme,
      // 🟢 Added the callback to support navigation to HelpCenterScreen from Settings
      //onHelpSupportTap: _handleHelpSupport,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_authState) {
      case AuthState.login:
        return LoginScreen(
          onRegisterTap: _showRegister,
          onLoginSuccess: _showDashboard,
        );

      case AuthState.register:
        // Assuming 'registration_screen.dart' defines 'MinimalistRegistrationScreen'
        return MinimalistRegistrationScreen(onLoginTap: _showLogin);

      case AuthState.dashboard:
        return _buildDashboard();

      case AuthState.settings:
        return _buildSettings();
    }
  }
}
