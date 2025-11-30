// lib/screens/mobile/class_detail_screen.dart
import 'package:flutter/material.dart';

class Post {
  final String id;
  final String author;
  final String authorAvatar;
  final String date;
  final String content;
  final int likes;

  Post({
    required this.id,
    required this.author,
    required this.authorAvatar,
    required this.date,
    required this.content,
    required this.likes,
  });
}

class FileItem {
  final String id;
  final String name;
  final String type; // 'video' or 'document'

  FileItem({
    required this.id,
    required this.name,
    required this.type,
  });
}

class Assessment {
  final String id;
  final String title;
  final String type; // 'mcq' or 'segmentation'
  final int questions;
  final String duration;
  final String dueDate;
  final String status;

  Assessment({
    required this.id,
    required this.title,
    required this.type,
    required this.questions,
    required this.duration,
    required this.dueDate,
    required this.status,
  });
}

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final VoidCallback onBack;
  final Function(String, String) onOpenContent;
  final Function(String, String) onOpenAssessment;

  const ClassDetailScreen({
    Key? key,
    required this.classId,
    required this.onBack,
    required this.onOpenContent,
    required this.onOpenAssessment,
  }) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Post> posts = [
    Post(
      id: '1',
      author: 'Dr. Tahir Mustafa',
      authorAvatar: 'TM',
      date: '18:57, 23 Jun',
      content: 'All notes are provided.',
      likes: 12,
    ),
  ];

  final List<FileItem> files = [
    FileItem(
      id: '1',
      name: 'CT Scan Fundamentals.mp4',
      type: 'video',
    ),
    FileItem(
      id: '2',
      name: 'Abdomen Segmentation Guide.pdf',
      type: 'document',
    ),
  ];

  final List<Assessment> assessments = [
    Assessment(
      id: '1',
      title: 'Radiology Basics Quiz',
      type: 'mcq',
      questions: 10,
      duration: '15 min',
      dueDate: 'Oct 15, 2025',
      status: 'Not Started',
    ),
    Assessment(
      id: '2',
      title: 'Liver Segmentation Task',
      type: 'segmentation',
      questions: 3,
      duration: '20 min',
      dueDate: 'Oct 18, 2025',
      status: 'Not Started',
    ),
    Assessment(
      id: '3',
      title: 'CT Analysis MCQ Test',
      type: 'mcq',
      questions: 15,
      duration: '20 min',
      dueDate: 'Oct 20, 2025',
      status: 'Not Started',
    ),
    Assessment(
      id: '4',
      title: 'Kidney Segmentation Practice',
      type: 'segmentation',
      questions: 5,
      duration: '25 min',
      dueDate: 'Oct 22, 2025',
      status: 'Not Started',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2463EB),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF2463EB),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Files'),
                Tab(text: 'Tests'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPostsTab(),
                _buildFilesTab(),
                _buildAssessmentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFF2463EB),
                    child: Text(
                      post.authorAvatar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          post.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Post Content
              const Text(
                'Announcement:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),

              const SizedBox(height: 12),

              // Actions
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.blue.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likes}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: const [
                          Icon(
                            Icons.message_outlined,
                            size: 18,
                            color: Color(0xFF2463EB),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2463EB),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilesTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final file = files[index];
        return InkWell(
          onTap: () => widget.onOpenContent(file.id, file.type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    size: 20,
                    color: Color(0xFF2463EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        file.type[0].toUpperCase() + file.type.substring(1),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssessmentsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: assessments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final assessment = assessments[index];
        final isMcq = assessment.type == 'mcq';
        
        return InkWell(
          onTap: () => widget.onOpenAssessment(assessment.id, assessment.type),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isMcq
                        ? const Color(0xFFF3E8FF)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isMcq ? Icons.list_alt : Icons.edit_outlined,
                    size: 20,
                    color: isMcq
                        ? const Color(0xFF9333EA)
                        : const Color(0xFF059669),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              assessment.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isMcq
                                  ? const Color(0xFFF3E8FF)
                                  : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isMcq ? 'MCQ' : 'Drawing',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isMcq
                                    ? const Color(0xFF9333EA)
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${assessment.questions} questions',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            assessment.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Due: ${assessment.dueDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              assessment.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFA16207),
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
          ),
        );
      },
    );
  }
}