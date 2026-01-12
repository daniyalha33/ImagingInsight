// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
// Import your screens
import 'screens/student_login_screen.dart';
import 'screens/student_signup_screen.dart';
import 'screens/password_recovery_screen.dart';
import 'screens/student_portal.dart';

// Models
enum UserRole { student, teacher, principal }

class UserData {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImage;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    UserRole role = UserRole.student;
    switch (json['role']) {
      case 'teacher':
        role = UserRole.teacher;
        break;
      case 'principal':
        role = UserRole.principal;
        break;
      default:
        role = UserRole.student;
    }

    return UserData(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: role,
      profileImage: json['profileImage'],
    );
  }
}

// Main App
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImagingInsight',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AppNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Navigator
enum AppScreen {
  loading,
  studentLogin,
  studentSignup,
  passwordRecovery,
  studentPortal,
}

class AppNavigator extends StatefulWidget {
  const AppNavigator({Key? key}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  AppScreen _currentScreen = AppScreen.loading;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Check if user is already logged in
    final isLoggedIn = await ApiService.isLoggedIn();
    
    if (isLoggedIn) {
      // Get saved user data
      final user = await ApiService.getUserData();
      if (user != null && mounted) {
        setState(() {
          _userData = UserData.fromJson(user);
          _currentScreen = AppScreen.studentPortal;
        });
        return;
      }
    }

    // If not logged in, show login screen after delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _currentScreen = AppScreen.studentLogin);
    }
  }

  void _handleSignUpSuccess(Map<String, dynamic> result) {
    // Extract user data from registration result
    if (result['success'] == true && result['user'] != null) {
      setState(() {
        _userData = UserData.fromJson(result['user']);
        _currentScreen = AppScreen.studentPortal;
      });
    } else {
      // If registration failed, stay on signup screen
      // Error message is already shown by the signup screen
      setState(() => _currentScreen = AppScreen.studentSignup);
    }
  }

  void _handleLoginSuccess(Map<String, dynamic> user) {
    setState(() {
      _userData = UserData.fromJson(user);
      _currentScreen = AppScreen.studentPortal;
    });
  }

  Future<void> _handleLogout() async {
    // Clear session data
    await ApiService.logout();
    
    setState(() {
      _userData = null;
      _currentScreen = AppScreen.studentLogin;
    });

    // Show logout message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.logout, color: Colors.white),
              SizedBox(width: 12),
              Text('Logged out successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.loading:
        return const LoadingScreen();

      case AppScreen.studentLogin:
        return StudentLoginScreen(
          onLoginSuccess: _handleLoginSuccess,
          onNavigateToSignUp: () => setState(() => _currentScreen = AppScreen.studentSignup),
          onNavigateToPasswordRecovery: () => setState(() => _currentScreen = AppScreen.passwordRecovery),
        );

      case AppScreen.studentSignup:
        return StudentSignUpScreen(
          onNavigateToLogin: () => setState(() => _currentScreen = AppScreen.studentLogin),
          onSignUpSuccess: _handleSignUpSuccess,
        );

      case AppScreen.passwordRecovery:
        return PasswordRecoveryScreen(
          onBackToLogin: () => setState(() => _currentScreen = AppScreen.studentLogin),
        );

      case AppScreen.studentPortal:
        return _userData != null
            ? StudentPortal(
                userName: _userData!.name,
                userEmail: _userData!.email,
                onLogout: _handleLogout,
              )
            : const LoadingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildScreen();
  }
}

// ==================== LOADING SCREEN ====================
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2463EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.show_chart,
                color: Color(0xFF2463EB),
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ImagingInsight',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}