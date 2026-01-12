// lib/screens/mobile/join_class_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class JoinClassScreen extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onJoinClass;

  const JoinClassScreen({
    Key? key,
    required this.onBack,
    required this.onJoinClass,
  }) : super(key: key);

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _classCodeController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _classCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final code = _classCodeController.text.trim().toUpperCase();

    if (code.isEmpty || _isLoading) return;

    // Validate code format (should be 8 characters)
    if (code.length != 8) {
      _showError('Class code must be 8 characters');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.joinClass(code: code);

      if (!mounted) return;

      if (result['success'] == true) {
        // Show success message
        final className = result['data']?['name'] ?? 'the class';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Successfully joined $className!')),
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

        // Navigate back to classes screen
        widget.onBack();
      } else {
        _showError(result['message'] ?? 'Failed to join class');
      }
    } catch (e) {
      _showError('Network error. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _isLoading ? null : widget.onBack,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color:
                              _isLoading
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF1E40AF),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Join Class',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      // Icon
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEEFE),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title and Description
                      const Text(
                        'Join a Class',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter the class code provided by your teacher to join',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Form
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Class Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _classCodeController,
                            enabled: !_isLoading,
                            maxLength: 8,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Enter class code',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0,
                                fontWeight: FontWeight.normal,
                              ),
                              filled: true,
                              fillColor:
                                  _isLoading
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFFEFF6FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBFDBFE),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFBFDBFE),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2563EB),
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
                                vertical: 20,
                              ),
                              counterText: '',
                            ),
                            onChanged: (value) {
                              _classCodeController.value = TextEditingValue(
                                text: value.toUpperCase(),
                                selection: _classCodeController.selection,
                              );
                              setState(() {}); // <-- Add this line
                            },
                            onSubmitted: (_) => _handleSubmit(),
                          ),
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Example: ABCD1234',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ||
                                          _classCodeController.text
                                              .trim()
                                              .isEmpty
                                      ? null
                                      : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: const Color(
                                  0xFF2563EB,
                                ).withOpacity(0.5),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Text(
                                        'Join Class',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Info Cards
                      _buildInfoCard(
                        icon: Icons.qr_code,
                        title: 'Get the Code',
                        description:
                            'Ask your teacher for the class code. It\'s usually shared in class or via email.',
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.flash_on,
                        title: 'Instant Access',
                        description:
                            'Once you join, you\'ll have immediate access to all class materials and assessments.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
