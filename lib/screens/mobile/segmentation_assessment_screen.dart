// lib/screens/mobile/segmentation_assessment_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SegmentationAssessmentScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const SegmentationAssessmentScreen({
    Key? key,
    required this.onBack,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<SegmentationAssessmentScreen> createState() =>
      _SegmentationAssessmentScreenState();
}

class _SegmentationAssessmentScreenState
    extends State<SegmentationAssessmentScreen> {
  final List<Offset> _points = [];
  bool _showSliceSelector = true;
  int _selectedSlice = 169;
  int _currentQuestion = 1;
  double _brushSize = 10.0;
  bool _isEraser = false;
  final int _totalQuestions = 3;
  final int _totalSlices = 338;

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
  }

  void _handleSubmit() {
    if (_currentQuestion < _totalQuestions) {
      setState(() {
        _currentQuestion++;
        _points.clear();
      });
    } else {
      widget.onComplete();
    }
  }

  void _showSliceSelectorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Slice - case_001',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose the CT scan slice to start the quiz',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'slice: $_selectedSlice / $_totalSlices',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _selectedSlice.toDouble(),
                      min: 1,
                      max: _totalSlices.toDouble(),
                      divisions: _totalSlices - 1,
                      activeColor: const Color(0xFF2463EB),
                      onChanged: (value) {
                        setState(() {
                          _selectedSlice = value.round();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFF2463EB)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showSliceSelector = false;
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2463EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Start Quiz'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showSliceSelector) {
        _showSliceSelectorDialog();
      }
    });
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
              border: Border(
                bottom: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF1E40AF),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quiz: case_001 - Slice $_selectedSlice',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () {
                        // Show help dialog
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Help'),
                            content: const Text(
                              'Draw on the CT scan to segment the organs. Use the eraser to correct mistakes.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.help_outline),
                      color: const Color(0xFF1E40AF),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // CT Scan Canvas
          Expanded(
            child: Container(
              color: Colors.black,
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(Offset.infinite);
                  });
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CTScanPainter(
                    points: _points,
                    brushSize: _brushSize,
                    isEraser: _isEraser,
                  ),
                ),
              ),
            ),
          ),

          // Drawing Controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Brush Size Slider
                Row(
                  children: [
                    const Icon(
                      Icons.edit,
                      color: Color(0xFF2463EB),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 5,
                        max: 30,
                        divisions: 25,
                        activeColor: const Color(0xFF2463EB),
                        onChanged: (value) {
                          setState(() {
                            _brushSize = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${_brushSize.round()}px',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    // Eraser Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEraser = !_isEraser;
                          });
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Eraser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEraser
                              ? const Color(0xFF2463EB)
                              : const Color(0xFFDCEAFE),
                          foregroundColor: _isEraser
                              ? Colors.white
                              : const Color(0xFF2463EB),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Clear Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearCanvas,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Submit Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleSubmit,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CTScanPainter extends CustomPainter {
  final List<Offset> points;
  final double brushSize;
  final bool isEraser;

  CTScanPainter({
    required this.points,
    required this.brushSize,
    required this.isEraser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw CT scan background
    final paint = Paint()..style = PaintingStyle.fill;

    // Black background
    paint.color = const Color(0xFF000000);
    canvas.drawRect(Offset.zero & size, paint);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Outer body contour
    paint.color = const Color(0xFF505050);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.width * 0.8,
        height: size.height * 0.7,
      ),
      paint,
    );

    // Liver area (larger, more realistic shape)
    final gradient1 = ui.Gradient.radial(
      Offset(centerX - 40, centerY - 30),
      80,
      [const Color(0xFF909090), const Color(0xFF707070)],
      [0.0, 1.0],
    );
    paint.shader = gradient1;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 40, centerY - 30),
        width: size.width * 0.36,
        height: size.height * 0.3,
      ),
      paint,
    );
    paint.shader = null;

    // Kidneys (darker grey)
    paint.color = const Color(0xFF606060);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 80, centerY + 20),
        width: size.width * 0.18,
        height: size.height * 0.24,
      ),
      paint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 70, centerY + 20),
        width: size.width * 0.16,
        height: size.height * 0.22,
      ),
      paint,
    );

    // Spleen
    paint.color = const Color(0xFF757575);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 50, centerY - 10),
        width: size.width * 0.16,
        height: size.height * 0.2,
      ),
      paint,
    );

    // Spine/vertebrae (brightest - bone)
    paint.color = const Color(0xFFD0D0D0);
    canvas.drawCircle(
      Offset(centerX, centerY + 60),
      size.width * 0.06,
      paint,
    );

    // Draw user's segmentation
    final drawPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = brushSize
      ..style = PaintingStyle.stroke;

    if (isEraser) {
      drawPaint.color = Colors.black;
      drawPaint.blendMode = BlendMode.clear;
    } else {
      drawPaint.color = const Color(0xFF3B82F6).withOpacity(0.5);
    }

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].isFinite && points[i + 1].isFinite) {
        canvas.drawLine(points[i], points[i + 1], drawPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CTScanPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.brushSize != brushSize ||
        oldDelegate.isEraser != isEraser;
  }
}