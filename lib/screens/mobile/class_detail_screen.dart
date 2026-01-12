// lib/screens/mobile/class_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

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

  Map<String, dynamic>? _classData;
  List<dynamic> _posts = [];
  List<dynamic> _files = [];
  List<dynamic> _tests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClassData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load class details, posts, files, and tests in parallel
      final results = await Future.wait([
        ApiService.getClassDetails(widget.classId),
        ApiService.getPosts(widget.classId),
        ApiService.getFiles(widget.classId),
        ApiService.getTests(widget.classId),
      ]);

      if (!mounted) return;

      // Process class details
      if (results[0]['success'] == true) {
        _classData = results[0]['data'];
      }

      // Process posts
      if (results[1]['success'] == true) {
        _posts = results[1]['data'] ?? [];
      }

      // Process files
      if (results[2]['success'] == true) {
        _files = results[2]['data'] ?? [];
      }

      // Process tests
      if (results[3]['success'] == true) {
        _tests = results[3]['data'] ?? [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load class data';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('HH:mm, dd MMM').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
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
                    Expanded(
                      child: Text(
                        _classData?['name'] ?? 'Loading...',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2563EB),
                    ),
                  )
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadClassData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 64,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = _posts[index];
          final author = post['author'] as Map<String, dynamic>? ?? {};
          final authorName = author['name'] ?? 'Unknown';

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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2463EB),
                      child: Text(
                        _getInitials(authorName),
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
                            authorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          Text(
                            _formatDate(post['createdAt'] ?? ''),
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
                Text(
                  post['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilesTab() {
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No files yet',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _files.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final file = _files[index];
          final fileType = file['type'] ?? 'document';

          return InkWell(
            onTap: () => widget.onOpenContent(file['_id'], fileType),
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
                    child: Icon(
                      fileType == 'video'
                          ? Icons.play_circle_outline
                          : Icons.description_outlined,
                      size: 20,
                      color: const Color(0xFF2463EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file['name'] ?? 'Unnamed File',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              fileType[0].toUpperCase() +
                                  fileType.substring(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            if (file['downloads'] != null) ...[
                              const Text(' • ',
                                  style: TextStyle(color: Color(0xFF64748B))),
                              Text(
                                '${file['downloads']} downloads',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
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
      ),
    );
  }

  Widget _buildAssessmentsTab() {
    if (_tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tests yet',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final test = _tests[index];
          final isMcq = test['type'] == 'mcq';
          final questions = test['questions'] as List? ?? [];

          return InkWell(
            onTap: () => widget.onOpenAssessment(test['_id'], test['type']),
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
                                test['title'] ?? 'Unnamed Test',
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
                              '${questions.length} questions',
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
                              '${test['duration'] ?? 0} min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        if (test['dueDate'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Due: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(test['dueDate']))}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}