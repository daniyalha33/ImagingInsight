// lib/screens/mobile/content_viewer_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class ContentViewerScreen extends StatefulWidget {
  final String contentId;
  final String contentType;
  final VoidCallback onBack;

  const ContentViewerScreen({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ContentViewerScreen> createState() => _ContentViewerScreenState();
}

class _ContentViewerScreenState extends State<ContentViewerScreen>
    with TickerProviderStateMixin {
  bool _isMuted = false;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  Timer? _callTimer;
  int _callSeconds = 323; // 05:23

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    if (widget.contentType == 'interactive') {
      _startCallTimer();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callSeconds++;
      });
    });
  }

  String _formatCallTime() {
    final minutes = _callSeconds ~/ 60;
    final seconds = _callSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: widget.onBack,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF1E40AF),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getHeaderTitle(),
                      style: const TextStyle(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (widget.contentType) {
      case 'video':
        return 'Video Lesson';
      case 'document':
        return 'Document';
      case 'interactive':
        return 'Voice Call';
      default:
        return 'Content';
    }
  }

  Widget _buildContent() {
    switch (widget.contentType) {
      case 'video':
        return _buildVideoContent();
      case 'document':
        return _buildDocumentContent();
      case 'interactive':
        return _buildInteractiveContent();
      default:
        return const SizedBox();
    }
  }

  Widget _buildVideoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Player
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(32),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Video Details
        const Text(
          'CT Scan Fundamentals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Duration: 45 minutes',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Learn the fundamental concepts of CT scanning, including how to interpret different views and identify key anatomical structures in abdominal scans.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF0F172A),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document Preview
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.66,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEEFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Document Details
        const Text(
          'Abdomen Segmentation Guide',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '12 pages • PDF',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Download PDF',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Main Participant
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Avatar
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.05),
                            child: child,
                          );
                        },
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              width: 128,
                              height: 128,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2563EB),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFF2563EB),
                                child: Text(
                                  'SC',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Audio Wave Indicator
                            Positioned(
                              bottom: -8,
                              child: _buildAudioWaveIndicator(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sarah Chen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On call • ${_formatCallTime()}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Your Avatar (Top Right)
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF10B981),
                      child: Text(
                        'You',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Call Info (Bottom Center)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: const [
                      Text(
                        'Interactive Practice Session',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Discussing CT scan segmentation techniques',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Call Controls
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute Button
                _buildCallButton(
                  icon: Icons.mic,
                  isActive: _isMuted,
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                ),
                const SizedBox(width: 24),
                // End Call Button
                _buildEndCallButton(),
                const SizedBox(width: 24),
                // Speaker Button
                _buildCallButton(
                  icon: Icons.volume_up,
                  isActive: false,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioWaveIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final delay = index * 0.1;
              final wave = ((_waveController.value + delay) % 1.0);
              final height = 8.0 + (12.0 * (1 - (wave - 0.5).abs() * 2));
              return Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2563EB) : const Color(0xFFDCEEFE),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF2563EB),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildEndCallButton() {
    return InkWell(
      onTap: widget.onBack,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.call_end,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}