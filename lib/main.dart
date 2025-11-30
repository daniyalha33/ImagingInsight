// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import your screens
import 'screens/student_login_screen.dart';
import 'screens/student_signup_screen.dart';
import 'screens/password_recovery_screen.dart';
import 'screens/student_portal.dart';

// Models
enum UserRole { student, teacher, principal }

class UserData {
  final String name;
  final String email;
  final UserRole role;

  UserData({
    required this.name,
    required this.email,
    required this.role,
  });
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
    _startLoadingScreen();
  }

  void _startLoadingScreen() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _currentScreen = AppScreen.studentLogin);
      }
    });
  }

  void _handleSignUp(Map<String, dynamic> data) {
    setState(() {
      _userData = UserData(
        name: data['name'],
        email: data['email'],
        role: UserRole.student,
      );
      _currentScreen = AppScreen.studentPortal;
    });
  }

  void _handleLogin(String email, String password) {
    final name = email.contains('@') ? email.split('@')[0] : email;
    final capitalizedName = name[0].toUpperCase() + name.substring(1);
    final fullEmail = email.contains('@') ? email : '$email@imaginginsight.com';

    setState(() {
      _userData = UserData(
        name: capitalizedName,
        email: fullEmail,
        role: UserRole.student,
      );
      _currentScreen = AppScreen.studentPortal;
    });
  }

  void _handleLogout() {
    setState(() {
      _userData = null;
      _currentScreen = AppScreen.studentLogin;
    });
  }

  Widget _buildScreen() {
    switch (_currentScreen) {
      case AppScreen.loading:
        return const LoadingScreen();

      case AppScreen.studentLogin:
        return StudentLoginScreen(
          onLogin: _handleLogin,
          onNavigateToSignUp: () => setState(() => _currentScreen = AppScreen.studentSignup),
          onNavigateToPasswordRecovery: () => setState(() => _currentScreen = AppScreen.passwordRecovery),
        );

      case AppScreen.studentSignup:
        return StudentSignUpScreen(
          onSignUp: _handleSignUp,
          onNavigateToLogin: () => setState(() => _currentScreen = AppScreen.studentLogin),
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
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}