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
import 'mobile/chat_list_screen.dart';
import 'mobile/content_viewer_screen.dart';
import 'mobile/join_class_screen.dart';
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

  // Track the last classId for better navigation
  String? _lastClassId;

  // Track test result data
  Map<String, dynamic>? _lastTestResult;

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
          _currentScreen = ScreenState(ScreenType.profile);
          break;
      }
    });
  }

  void _navigateToScreen(ScreenState screen) {
    setState(() {
      _currentScreen = screen;

      // Save classId for better back navigation
      if (screen.type == ScreenType.classDetail) {
        _lastClassId = screen.params?['classId'];
      }

      // Save test result for result screen
      if (screen.type == ScreenType.mcqResult) {
        _lastTestResult = screen.params?['testResult'];
      }
    });
  }

  void _navigateBack() {
    // Smart back navigation
    switch (_currentScreen.type) {
      case ScreenType.joinClass:
      case ScreenType.classDetail:
        _navigateToScreen(ScreenState(ScreenType.classes));
        setState(() => _selectedIndex = 0);
        break;

      case ScreenType.contentViewer:
      case ScreenType.assessmentMcq:
      case ScreenType.assessmentSegmentation:
      case ScreenType.mcqResult:
      case ScreenType.segmentationResult:
        // Go back to class detail
        if (_lastClassId != null) {
          _navigateToScreen(
            ScreenState(
              ScreenType.classDetail,
              params: {'classId': _lastClassId},
            ),
          );
        } else {
          _navigateToScreen(ScreenState(ScreenType.classes));
          setState(() => _selectedIndex = 0);
        }
        break;

      case ScreenType.chat:
        _navigateToScreen(ScreenState(ScreenType.chatList));
        setState(() => _selectedIndex = 1);
        break;

      case ScreenType.aiReport:
        _navigateToScreen(ScreenState(ScreenType.aiSegmentation));
        setState(() => _selectedIndex = 2);
        break;

      default:
        // For main tabs, just switch to that tab
        break;
    }
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
          onBack: _navigateBack,
          onJoinClass: (classCode) {
            // Backend integration handles this now
            // Just navigate back - classes screen will reload
            _navigateToScreen(ScreenState(ScreenType.classes));
          },
        );

      case ScreenType.classDetail:
        return ClassDetailScreen(
          classId: _currentScreen.params?['classId'] ?? '',
          onBack: _navigateBack,
          onOpenAssessment: (assessmentId, assessmentType) {
            if (assessmentType == 'mcq') {
              _navigateToScreen(
                ScreenState(
                  ScreenType.assessmentMcq,
                  params: {
                    'testId': assessmentId,
                    'assessmentType': assessmentType,
                  },
                ),
              );
            } else {
              _navigateToScreen(
                ScreenState(
                  ScreenType.assessmentSegmentation,
                  params: {
                    'testId': assessmentId,
                    'assessmentType': assessmentType,
                  },
                ),
              );
            }
          },
        );

      case ScreenType.contentViewer:
        return ContentViewerScreen(
          contentId: _currentScreen.params?['contentId'] ?? '',
          contentType: _currentScreen.params?['contentType'] ?? 'video',
          onBack: _navigateBack,
        );

      case ScreenType.assessmentMcq:
        return AssessmentScreen(
          testId: _currentScreen.params?['testId'] ?? '',
          onBack: _navigateBack,
        );

      case ScreenType.assessmentSegmentation:
        return SegmentationAssessmentScreen(
          onBack: _navigateBack,
          onComplete: () {
            _navigateToScreen(ScreenState(ScreenType.segmentationResult));
          },
        );

      case ScreenType.mcqResult:
        // Get test result from params or use cached result
        final testResult =
            _currentScreen.params?['testResult'] as Map<String, dynamic>? ??
            _lastTestResult ??
            {};

        return MCQResultScreen(onBack: _navigateBack, testResult: testResult);

      case ScreenType.segmentationResult:
        return SegmentationResultScreen(onBack: _navigateBack);

      case ScreenType.chatList:
        return ChatListScreen(
          onSelectChat: (teacherId, teacherName, chatId) {
            _navigateToScreen(
              ScreenState(
                ScreenType.chat,
                params: {
                  'teacherId': teacherId,
                  'teacherName': teacherName,
                  'chatId': chatId,
                },
              ),
            );
          },
        );

      case ScreenType.chat:
        return ChatScreen(
          teacherId: _currentScreen.params?['teacherId'] ?? '',
          teacherName: _currentScreen.params?['teacherName'] ?? 'Teacher',
          chatId: _currentScreen.params?['chatId'],
          onBack: _navigateBack,
        );

      case ScreenType.aiSegmentation:
        return AISegmentationScreen(
          onGenerateReport: (Map<String, dynamic> reportData) {
            _navigateToScreen(
              ScreenState(
                ScreenType.aiReport,
                params: {'reportData': reportData},
              ),
            );
          },
          onBack: () {
            _navigateToScreen(ScreenState(ScreenType.classes));
            setState(() => _selectedIndex = 0);
          },
        );

      case ScreenType.aiReport:
        final reportData =
            _currentScreen.params?['reportData'] as Map<String, dynamic>?;

        return AIReportScreen(onBack: _navigateBack, reportData: reportData);

      case ScreenType.profile:
        // ProfileScreen now fetches user data from backend
        return ProfileScreen(onLogout: widget.onLogout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle Android back button
        if (_isMainTab()) {
          // If on main tab, allow exit
          return true;
        } else {
          // Otherwise, navigate back within app
          _navigateBack();
          return false;
        }
      },
      child: Scaffold(
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
                  _buildNavItem(3, Icons.person_outline, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isMainTab() {
    return _currentScreen.type == ScreenType.classes ||
        _currentScreen.type == ScreenType.chatList ||
        _currentScreen.type == ScreenType.aiSegmentation ||
        _currentScreen.type == ScreenType.profile;
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
                color:
                    isSelected
                        ? const Color(0xFF2463EB)
                        : const Color(0xFF64748B),
                size: isSelected ? 24 : 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isSelected
                          ? const Color(0xFF2463EB)
                          : const Color(0xFF64748B),
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
