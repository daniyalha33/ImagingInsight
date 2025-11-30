// lib/screens/mobile/segmentation_result_screen.dart
import 'package:flutter/material.dart';

class SegmentationResultScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SegmentationResultScreen({
    Key? key,
    required this.onBack,
  }) : super(key: key);

  @override
  State<SegmentationResultScreen> createState() =>
      _SegmentationResultScreenState();
}

class _SegmentationResultScreenState extends State<SegmentationResultScreen> {
  bool _showGroundTruth = false;

  final String _grade = 'A';
  final double _matchPercentage = 91.4;
  final double _diceScore = 91.4;
  final double _iou = 84.2;
  final double _precision = 89.5;
  final double _recall = 93.4;

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
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: const Text(
                  'Quiz Results',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Grade Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E5D4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Grade: $_grade',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_matchPercentage% Match',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Metrics Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                    children: [
                      _buildMetricCard(
                        'Dice Score',
                        '$_diceScore%',
                        const Color(0xFF3B82F6),
                        const Color(0xFFDBEAFE),
                        _buildDiceIcon(),
                      ),
                      _buildMetricCard(
                        'IoU',
                        '$_iou%',
                        const Color(0xFFA855F7),
                        const Color(0xFFF3E8FF),
                        _buildIoUIcon(),
                      ),
                      _buildMetricCard(
                        'Precision',
                        '$_precision%',
                        const Color(0xFF22C55E),
                        const Color(0xFFDCFCE7),
                        _buildPrecisionIcon(),
                      ),
                      _buildMetricCard(
                        'Recall',
                        '$_recall%',
                        const Color(0xFFF59E0B),
                        const Color(0xFFFEF3C7),
                        _buildRecallIcon(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Feedback Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chat_bubble,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Feedback',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '• Excellent segmentation! 🎉',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ground Truth Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ground Truth',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Switch(
                              value: _showGroundTruth,
                              onChanged: (value) {
                                setState(() {
                                  _showGroundTruth = value;
                                });
                              },
                              activeColor: const Color(0xFF2463EB),
                            ),
                          ],
                        ),
                        if (_showGroundTruth) ...[
                          const SizedBox(height: 16),
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CustomPaint(
                                painter: GroundTruthPainter(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Action Buttons
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Another'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.home, size: 18),
                    label: const Text('Home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2463EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color valueColor,
    Color bgColor,
    Widget icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: icon,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceIcon() {
    return Center(
      child: CustomPaint(
        size: const Size(24, 24),
        painter: DiceIconPainter(),
      ),
    );
  }

  Widget _buildIoUIcon() {
    return Center(
      child: CustomPaint(
        size: const Size(24, 24),
        painter: IoUIconPainter(),
      ),
    );
  }

  Widget _buildPrecisionIcon() {
    return Center(
      child: CustomPaint(
        size: const Size(24, 24),
        painter: PrecisionIconPainter(),
      ),
    );
  }

  Widget _buildRecallIcon() {
    return const Center(
      child: Icon(
        Icons.check,
        color: Color(0xFFF59E0B),
        size: 28,
      ),
    );
  }
}

// Custom Painters for Icons
class DiceIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.fill;

    // Vertical bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.4, size.height * 0.2, size.width * 0.2,
            size.height * 0.6),
        const Radius.circular(1),
      ),
      paint,
    );

    // Horizontal bar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.2, size.height * 0.4, size.width * 0.6,
            size.height * 0.2),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class IoUIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA855F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Left circle
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.5),
      size.width * 0.3,
      paint,
    );

    // Right circle
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.5),
      size.width * 0.3,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PrecisionIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Outer circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.35,
      paint,
    );

    // Middle circle
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.18,
      paint,
    );

    // Center dot
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.07,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GroundTruthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    // Main liver-like shape
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.cubicTo(
      size.width * 0.7,
      size.height * 0.2,
      size.width * 0.8,
      size.height * 0.3,
      size.width * 0.8,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.55,
      size.width * 0.75,
      size.height * 0.65,
      size.width * 0.65,
      size.height * 0.7,
    );
    path.cubicTo(
      size.width * 0.6,
      size.height * 0.725,
      size.width * 0.55,
      size.height * 0.7375,
      size.width * 0.5,
      size.height * 0.7375,
    );
    path.cubicTo(
      size.width * 0.45,
      size.height * 0.7375,
      size.width * 0.4,
      size.height * 0.725,
      size.width * 0.35,
      size.height * 0.7,
    );
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.65,
      size.width * 0.2,
      size.height * 0.55,
      size.width * 0.2,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.5,
      size.height * 0.2,
    );
    path.close();
    canvas.drawPath(path, paint);

    // Left kidney
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.375, size.height * 0.625),
        width: size.width * 0.15,
        height: size.height * 0.225,
      ),
      paint,
    );

    // Right kidney
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.625, size.height * 0.625),
        width: size.width * 0.14,
        height: size.height * 0.21,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}