// lib/screens/mobile/assessment_screen.dart
import 'package:flutter/material.dart';

class Question {
  final int id;
  final String question;
  final List<String> options;
  final bool hasImage;

  Question({
    required this.id,
    required this.question,
    required this.options,
    this.hasImage = false,
  });
}

class AssessmentScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onComplete;

  const AssessmentScreen({
    Key? key,
    required this.onBack,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentQuestion = 1;
  String _selectedAnswer = '';
  final int _totalQuestions = 4;

  final List<Question> _questions = [
    Question(
      id: 1,
      question: 'What is Radiology?',
      options: [
        'The study of radiation',
        'Medical imaging for diagnosis',
        'Study of radio waves',
        'Bone structure analysis',
      ],
      hasImage: true,
    ),
    Question(
      id: 2,
      question: 'Which imaging technique uses X-rays?',
      options: [
        'MRI',
        'Ultrasound',
        'CT Scan',
        'PET Scan',
      ],
      hasImage: false,
    ),
    Question(
      id: 3,
      question: 'What does CT stand for?',
      options: [
        'Computed Tomography',
        'Contrast Therapy',
        'Cardiac Testing',
        'Clinical Treatment',
      ],
      hasImage: false,
    ),
    Question(
      id: 4,
      question: 'Which organ is most commonly examined in abdominal imaging?',
      options: [
        'Brain',
        'Heart',
        'Liver',
        'Lungs',
      ],
      hasImage: true,
    ),
  ];

  void _handleNext() {
    if (_currentQuestion < _totalQuestions) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = '';
      });
    } else {
      widget.onComplete();
    }
  }

  void _handlePrevious() {
    if (_currentQuestion > 1) {
      setState(() {
        _currentQuestion--;
        _selectedAnswer = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _questions[_currentQuestion - 1];

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
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF1E40AF),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Radiology',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question number
                  Text(
                    'Quiz $_currentQuestion',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Question Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question text
                        Text(
                          '$_currentQuestion. ${currentQ.question}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image placeholder (if question has image)
                        if (currentQ.hasImage) ...[
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Image',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Options
                        ...currentQ.options.asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;
                          final isSelected = _selectedAnswer == option;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedAnswer = option;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFEFF6FF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF2463EB)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF2463EB)
                                              : const Color(0xFF94A3B8),
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFF2463EB)
                                            : Colors.white,
                                      ),
                                      child: isSelected
                                          ? const Center(
                                              child: Icon(
                                                Icons.circle,
                                                size: 10,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected
                                              ? const Color(0xFF1E40AF)
                                              : const Color(0xFF1E293B),
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navigation Footer
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.blue.shade100),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Previous Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _currentQuestion > 1 ? _handlePrevious : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2463EB),
                          side: const BorderSide(color: Color(0xFF2463EB)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledForegroundColor:
                              const Color(0xFF94A3B8).withOpacity(0.38),
                          disabledBackgroundColor: Colors.transparent,
                        ).copyWith(
                          side: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.disabled)) {
                              return const BorderSide(
                                  color: Color(0xFFCBD5E1));
                            }
                            return const BorderSide(color: Color(0xFF2463EB));
                          }),
                        ),
                        child: const Text('Previous Question'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Next/Submit Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2463EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _currentQuestion < _totalQuestions
                              ? 'Next Question'
                              : 'Submit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}