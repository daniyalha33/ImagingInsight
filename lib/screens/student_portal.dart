// lib/screens/student_portal.dart
import 'package:flutter/material.dart';
import 'mobile/classes_screen.dart';
import 'mobile/ai_segmentation_screen.dart';
import 'mobile/ai_report_screen.dart';
import 'mobile/segmentation_assessment_screen.dart';
import 'mobile/assessment_screen.dart';
import 'mobile/segmentation_result_screen.dart';
import 'mobile/mcq_result_screen.dart';

import 'mobile/profile_screen.dart';
import 'mobile/chat_screen.dart';
import 'mobile/performance_screen.dart';
import 'mobile/chat_list_screen.dart';
import 'mobile/content_viewer_screen.dart';
import 'mobile/join_class_screen.dart';
// Import your screen files (create these next)
// import 'mobile/classes_screen.dart';
// import 'mobile/chat_list_screen.dart';
// import 'mobile/ai_segmentation_screen.dart';
// import 'mobile/performance_screen.dart';
// import 'mobile/profile_screen.dart';
import 'mobile/class_detail_screen.dart';
class StudentPortal extends StatefulWidget {
  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  const StudentPortal({
    Key? key,
    required this.userName,
    this.userEmail = 'student@imaginginsight.com',
    required this.onLogout,
  }) : super(key: key);

  @override
  State<StudentPortal> createState() => _StudentPortalState();
}

// Screen types for navigation
enum ScreenType {
  classes,
  joinClass,
  classDetail,
  contentViewer,
  assessmentMcq,
  assessmentSegmentation,
  mcqResult,
  segmentationResult,
  chatList,
  chat,
  aiSegmentation,
  aiReport,
  performance,
  profile,
}

class ScreenState {
  final ScreenType type;
  final Map<String, dynamic>? params;

  ScreenState(this.type, {this.params});
}

class _StudentPortalState extends State<StudentPortal> {
  int _selectedIndex = 0;
  ScreenState _currentScreen = ScreenState(ScreenType.classes);

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _currentScreen = ScreenState(ScreenType.classes);
          break;
        case 1:
          _currentScreen = ScreenState(ScreenType.chatList);
          break;
        case 2:
          _currentScreen = ScreenState(ScreenType.aiSegmentation);
          break;
        case 3:
          _currentScreen = ScreenState(ScreenType.performance);
          break;
        case 4:
          _currentScreen = ScreenState(ScreenType.profile);
          break;
      }
    });
  }

  void _navigateToScreen(ScreenState screen) {
    setState(() {
      _currentScreen = screen;
    });
  }

  Widget _buildScreen() {
    switch (_currentScreen.type) {
      case ScreenType.classes:
        return ClassesScreen(
          onSelectClass: (classId) {
            _navigateToScreen(
              ScreenState(ScreenType.classDetail, params: {'classId': classId}),
            );
          },
          onJoinClass: () {
            _navigateToScreen(ScreenState(ScreenType.joinClass));
          },
        );

      case ScreenType.joinClass:
        return JoinClassScreen(
          onBack: () {
            _navigateToScreen(ScreenState(ScreenType.classes));
          },
          onJoinClass: (classCode) {
            // In a real app, make API call to join class
            print('Joining class with code: $classCode');
            _navigateToScreen(ScreenState(ScreenType.classes));
          },
        );

      case ScreenType.classDetail:
        return ClassDetailScreen(
          classId: _currentScreen.params?['classId'] ?? '1',
          onBack: () {
            _navigateToScreen(ScreenState(ScreenType.classes));
          },
          onOpenContent: (contentId, contentType) {
            _navigateToScreen(
              ScreenState(
                ScreenType.contentViewer,
                params: {'contentId': contentId, 'contentType': contentType},
              ),
            );
          },
          onOpenAssessment: (assessmentId, assessmentType) {
            if (assessmentType == 'mcq') {
              _navigateToScreen(
                ScreenState(
                  ScreenType.assessmentMcq,
                  params: {'assessmentId': assessmentId},
                ),
              );
            } else {
              _navigateToScreen(
                ScreenState(
                  ScreenType.assessmentSegmentation,
                  params: {'assessmentId': assessmentId},
                ),
              );
            }
          },
        );

      case ScreenType.contentViewer:
        return ContentViewerScreen(
          contentId: _currentScreen.params?['contentId'] ?? '',
          contentType: _currentScreen.params?['contentType'] ?? 'video',
          onBack: () {
            _navigateToScreen(
              ScreenState(ScreenType.classDetail, params: {'classId': '1'}),
            );
          },
        );

      case ScreenType.assessmentMcq:
        return AssessmentScreen(
          onBack: () {
            _navigateToScreen(
              ScreenState(ScreenType.classDetail, params: {'classId': '1'}),
            );
          },
          onComplete: () {
            _navigateToScreen(ScreenState(ScreenType.mcqResult));
          },
        );

      case ScreenType.assessmentSegmentation:
        return SegmentationAssessmentScreen(
          onBack: () {
            _navigateToScreen(
              ScreenState(ScreenType.classDetail, params: {'classId': '1'}),
            );
          },
          onComplete: () {
            _navigateToScreen(ScreenState(ScreenType.segmentationResult));
          },
        );

      case ScreenType.mcqResult:
        return MCQResultScreen(
          onBack: () {
            _navigateToScreen(
              ScreenState(ScreenType.classDetail, params: {'classId': '1'}),
            );
          },
        );

      case ScreenType.segmentationResult:
        return SegmentationResultScreen(
          onBack: () {
            _navigateToScreen(
              ScreenState(ScreenType.classDetail, params: {'classId': '1'}),
            );
          },
        );

      case ScreenType.chatList:
        return ChatListScreen(
          onSelectChat: (teacherId) {
            final teacherNames = {
              '1': 'Dr. Tahir Mustafa',
              '2': 'Dr. Uzair Iqbal',
            };
            _navigateToScreen(
              ScreenState(
                ScreenType.chat,
                params: {
                  'teacherId': teacherId,
                  'teacherName': teacherNames[teacherId] ?? 'Teacher',
                },
              ),
            );
          },
        );

      case ScreenType.chat:
        return ChatScreen(
          teacherId: _currentScreen.params?['teacherId'] ?? '',
          teacherName: _currentScreen.params?['teacherName'] ?? 'Teacher',
          onBack: () {
            _navigateToScreen(ScreenState(ScreenType.chatList));
          },
        );

   // Replace your aiSegmentation and aiReport cases with these fixed versions:

case ScreenType.aiSegmentation:
  return AISegmentationScreen(
    onGenerateReport: (Map<String, dynamic> reportData) {
      // ✅ DEBUG: Print what we're passing
      print('🔄 StudentPortal: Navigating to report with data');
      print('   Keys: ${reportData.keys.toList()}');
      print('   Organs: ${reportData['organs']?.length}');
      
      // ✅ Pass the entire reportData as params
      _navigateToScreen(
        ScreenState(
          ScreenType.aiReport, 
          params: {'reportData': reportData} // ✅ Wrap in a map
        )
      );
    },
    onBack: () {
      _navigateToScreen(ScreenState(ScreenType.classes));
    },
  );

case ScreenType.aiReport:
  // ✅ FIX: Extract reportData from params
  final reportData = _currentScreen.params?['reportData'] as Map<String, dynamic>?;
  
  // ✅ DEBUG: Verify we received the data
  print('📱 StudentPortal: Building AIReportScreen');
  print('   Current screen params: ${_currentScreen.params?.keys.toList()}');
  print('   Report data null? ${reportData == null}');
  if (reportData != null) {
    print('   Report data keys: ${reportData.keys.toList()}');
    print('   Organs count: ${reportData['organs']?.length}');
  }
  
  return AIReportScreen(
    onBack: () {
      _navigateToScreen(ScreenState(ScreenType.aiSegmentation));
    },
    reportData: reportData, // ✅ Pass the actual data!
  );
      case ScreenType.performance:
        return PerformanceScreen(userName: widget.userName);

      case ScreenType.profile:
        return ProfileScreen(
          userName: widget.userName,
          userEmail: widget.userEmail,
          onLogout: widget.onLogout,
        );

      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF6FF), Colors.white],
          ),
        ),
        child: _buildScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.blue.shade100, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.book_outlined, 'Classes'),
                _buildNavItem(1, Icons.chat_bubble_outline, 'Chat'),
                _buildNavItem(2, Icons.scanner_outlined, 'AI Scan'),
                _buildNavItem(3, Icons.emoji_events_outlined, 'Performance'),
                _buildNavItem(4, Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabChange(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF2463EB) : const Color(0xFF64748B),
                size: isSelected ? 24 : 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? const Color(0xFF2463EB) : const Color(0xFF64748B),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== PLACEHOLDER SCREENS ====================
// Replace these with actual implementations














