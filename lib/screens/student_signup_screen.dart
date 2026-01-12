// lib/screens/student_signup_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';

class StudentSignUpScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final Function(Map<String, dynamic>) onSignUpSuccess;

  const StudentSignUpScreen({
    Key? key,
    required this.onNavigateToLogin,
    required this.onSignUpSuccess,
  }) : super(key: key);

  @override
  State<StudentSignUpScreen> createState() => _StudentSignUpScreenState();
}

class _StudentSignUpScreenState extends State<StudentSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_profileImage == null) return null;

    try {
      final bytes = await _profileImage!.readAsBytes();
      final base64String = base64Encode(bytes);
      // Get file extension
      final extension = _profileImage!.path.split('.').last.toLowerCase();
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Error converting image: $e');
      return null;
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert image to base64 if exists
      String? profileImageBase64;
      if (_profileImage != null) {
        profileImageBase64 = await _convertImageToBase64();
      }

      // Call the register API
      final result = await ApiService.register(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        password: _passwordController.text,
        profileImage: profileImageBase64,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success message
        _showSuccessSnackBar(
          result['message'] ?? 'Registration successful!',
        );

        // Wait a bit for user to see the message
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate or callback with user data
        widget.onSignUpSuccess(result);
      } else {
        // Show error message
        _showErrorSnackBar(
          result['message'] ?? 'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Network error. Please check your connection.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2463EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.show_chart,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Name
                const Center(
                  child: Text(
                    'ImagingInsight',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Get Started Text
                const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  'Create your student account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 32),

                // Email Field
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: _isLoading
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2463EB),
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Name Field
                const Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: _isLoading
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2463EB),
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Password Field
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: _isLoading
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2463EB),
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFE2E8F0),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _isLoading
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please create a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Profile Picture (Optional)
                const Text(
                  'Profile Picture (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _isLoading ? null : _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isLoading
                            ? const Color(0xFFE2E8F0)
                            : const Color(0xFFBAE6FD),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _profileImage != null
                              ? Icons.check_circle
                              : Icons.upload_outlined,
                          color: _isLoading
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF2463EB),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _profileImage != null
                                ? 'Image selected ✓'
                                : 'Upload profile picture',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isLoading
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF2463EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2463EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor:
                          const Color(0xFF2463EB).withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading ? null : widget.onNavigateToLogin,
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isLoading
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF2463EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}