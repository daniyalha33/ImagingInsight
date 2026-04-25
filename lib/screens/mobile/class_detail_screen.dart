// lib/screens/mobile/class_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../widgets/avatar_widget.dart';
import './live_class_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  final VoidCallback onBack;
  final Function(String, String) onOpenAssessment;

  // ✅ REMOVED _onConnectionStatus from here

  const ClassDetailScreen({
    Key? key,
    required this.classId,
    required this.onBack,
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
  String? _error;  late final Function _onLiveClassStarted;
  late final Function _onLiveClassEnded;
  Function? _onConnectionStatus; // Nullable — only assigned if socket not yet connected
   @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClassData();   _onLiveClassStarted = (data) {
  debugPrint('🔥 liveClassStarted received in ClassDetail ✅');
  debugPrint('   data type: ${data.runtimeType}');
  debugPrint('   data: $data');
  debugPrint('   widget.classId: ${widget.classId}');
  if (data is Map) {
    debugPrint('   data[classId]: ${data['classId']}');
    debugPrint('   data[class]: ${data['class']}');
  }
  if (mounted) {
    // Try to match classId from data — server might use different keys
    final incomingClassId = data is Map
        ? (data['classId'] ?? data['class'] ?? '').toString()
        : '';
    if (incomingClassId == widget.classId || incomingClassId.isEmpty) {
      // If classId matches OR server didn't send one (room-scoped = already filtered)
      _showLiveClassBanner(data is Map<String, dynamic> ? data : <String, dynamic>{});
    } else {
      debugPrint('   ⚠️ classId mismatch: incoming=$incomingClassId vs widget=${widget.classId}');
    }
  }
};

    _onLiveClassEnded = (data) {
      if (mounted && data['classId'] == widget.classId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live class has ended'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    };

    ApiService.socket.on('liveClassStarted', _onLiveClassStarted);
    ApiService.socket.on('liveClassEnded', _onLiveClassEnded);   if (ApiService.socket.isConnected) {
  debugPrint('Socket already connected, joining class ${widget.classId}');
  ApiService.socket.joinClass(widget.classId);
  ApiService.socket.printDebugInfo();
} else {
  debugPrint('Socket NOT connected yet, waiting...');
  _onConnectionStatus = (data) {
    if (data['connected'] == true) {
      debugPrint('Socket connected now, joining class ${widget.classId}');
      ApiService.socket.joinClass(widget.classId);
      ApiService.socket.printDebugInfo();
      ApiService.socket.off('connection:status', _onConnectionStatus!);
    }
  };
  ApiService.socket.on('connection:status', _onConnectionStatus!);
}
  }
  @override
  void dispose() {
    _tabController.dispose();
    ApiService.socket.leaveClass(widget.classId);
    ApiService.socket.off('liveClassStarted', _onLiveClassStarted);
    ApiService.socket.off('liveClassEnded', _onLiveClassEnded);
    if (_onConnectionStatus != null) {
      ApiService.socket.off('connection:status', _onConnectionStatus!);
    }
    super.dispose();
  }
  
  void _showLiveClassBanner(Map<String, dynamic> data) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text('Live Class Started!'),
        ],
      ),
      content: Text(
        '${data['teacherName']} has started a live class. Join now?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {                              // ← async
            Navigator.pop(ctx);
            final token = await ApiService.getToken();      // ← await
            final userData = await ApiService.getUserData(); // ← await
            final studentName = userData?['name'] ?? 'Student';
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveClassScreen(
                  classId: widget.classId,
                  studentName: studentName,
                  authToken: token ?? '',
                  apiBaseUrl: ApiService.baseUrl,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
          ),
          child: const Text(
            'Join Now',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

  Future<void> _loadClassData() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    final results = await Future.wait([
      ApiService.getClassDetails(widget.classId),
      ApiService.getPosts(widget.classId),
      ApiService.getFiles(widget.classId),
      ApiService.getTests(widget.classId),
      ApiService.getSegmentationTests(widget.classId),
    ]);

    if (!mounted) return;

    // ✅ Wrap ALL data assignments inside a single setState
    setState(() {
      if (results[0]['success'] == true) _classData = results[0]['data'];
      if (results[1]['success'] == true) {
        final rawPosts = (results[1]['data'] as List<dynamic>?) ?? [];
        _posts = rawPosts.map((p) {
          final Map<String, dynamic> postMap = Map<String, dynamic>.from(p as Map<String, dynamic>);
          // Ensure comments array exists so UI can preview comments
          if (postMap['comments'] == null || postMap['comments'] is! List) {
            postMap['comments'] = <dynamic>[];
          }
          postMap['commentsCount'] = postMap['commentsCount'] ?? (postMap['comments'] as List).length;
          postMap['likesCount'] = postMap['likesCount'] ?? (postMap['likes'] is List ? (postMap['likes'] as List).length : 0);
          postMap['likedByCurrentUser'] = postMap['likedByCurrentUser'] ?? postMap['liked'] ?? false;
          return postMap;
        }).toList();
      }
      if (results[2]['success'] == true) _files = results[2]['data'] ?? [];

      final mcqTests = results[3]['success'] == true
          ? (results[3]['data'] as List<dynamic>? ?? [])
              .map((t) => {...(t as Map<String, dynamic>), 'type': 'mcq'})
              .toList()
          : <Map<String, dynamic>>[];

      final segTests = results[4]['success'] == true
          ? (results[4]['data'] as List<dynamic>? ?? [])
              .map((t) => {...(t as Map<String, dynamic>), 'type': 'segmentation'})
              .toList()
          : <Map<String, dynamic>>[];

      _tests = [...mcqTests, ...segTests];
      _isLoading = false; // ✅ THIS was missing
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
  Future<void> _handleFileDownload(String fileId, String fileName, String fileUrl) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Opening file...'),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await ApiService.downloadFile(widget.classId, fileId);
      print('Attempting to open fileUrl: $fileUrl');

      final uri = Uri.parse(fileUrl);
      bool launched = false;

      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (launched) {
        _loadClassData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open file. Please install a PDF/video viewer app.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Toggle like on a post (optimistic UI)
  Future<void> _toggleLikePostAt(int index) async {
    final dynamic raw = _posts[index];
    if (raw == null || raw is! Map<String, dynamic>) return;
    final post = raw as Map<String, dynamic>;
    final String postId = (post['_id'] ?? post['id'] ?? '').toString();
    if (postId.isEmpty) return;

    final prevLiked = (post['likedByCurrentUser'] ?? post['liked'] ?? false) as bool;
    final prevLikes = (post['likesCount'] ?? (post['likes'] is List ? (post['likes'] as List).length : 0)) as int;

    // Optimistic update
    setState(() {
      post['likedByCurrentUser'] = !prevLiked;
      post['likesCount'] = prevLiked ? (prevLikes - 1) : (prevLikes + 1);
    });

    try {
      final res = await ApiService.toggleLikePost(classId: widget.classId, postId: postId);
      if (res['success'] != true) {
        // revert
        setState(() {
          post['likedByCurrentUser'] = prevLiked;
          post['likesCount'] = prevLikes;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to like post'), backgroundColor: Colors.red),
          );
        }
      } else {
        // sync counts if server returned authoritative value
        if (res.containsKey('likesCount')) {
          setState(() {
            post['likesCount'] = res['likesCount'];
            post['likedByCurrentUser'] = res['liked'] ?? post['likedByCurrentUser'];
          });
        }
      }
    } catch (e) {
      // revert on error
      setState(() {
        post['likedByCurrentUser'] = prevLiked;
        post['likesCount'] = prevLikes;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Show dialog to add a comment
  Future<void> _showCommentDialog(int index) async {
    final dynamic raw = _posts[index];
    if (raw == null || raw is! Map<String, dynamic>) return;
    final post = raw as Map<String, dynamic>;
    final String postId = (post['_id'] ?? post['id'] ?? '').toString();
    if (postId.isEmpty) return;

    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Write your comment...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (result != true) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    // Diagnostic log
    try { debugPrint('[ClassDetail] _showCommentDialog BEFORE index=$index commentsLen=${(post['comments'] is List ? (post['comments'] as List).length : -1)} commentsCount=${post['commentsCount'] ?? 'n/a'}'); } catch (_) {}

    // Optimistic UI: increment comment count
    final prevComments = post['comments'] is List ? (post['comments'] as List).length : (post['commentsCount'] ?? 0);
    setState(() {
      if (post['comments'] is List) {
        // push a lightweight placeholder comment
        (post['comments'] as List).add({
          'author': {'name': 'You'},
          'content': text,   
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        post['commentsCount'] = prevComments + 1;
      }
    });
    try { debugPrint('[ClassDetail] _showCommentDialog AFTER optimistic index=$index commentsLen=${(post['comments'] is List ? (post['comments'] as List).length : -1)} commentsCount=${post['commentsCount'] ?? 'n/a'}'); } catch (_) {}

    try {
      final res = await ApiService.addPostComment(classId: widget.classId, postId: postId, text: text);
      if (res['success'] != true) {
        // revert
        setState(() {
          if (post['comments'] is List) {
            (post['comments'] as List).removeLast();
          } else {
            post['commentsCount'] = prevComments;
          }
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed to add comment'), backgroundColor: Colors.red));
      } else {
        // if server returned full comment, replace the placeholder
        if (res.containsKey('comment')) {
          setState(() {
            if (post['comments'] is List) {
              (post['comments'] as List).removeLast();
              (post['comments'] as List).add(res['comment']);
            } else {
              post['commentsCount'] = (post['commentsCount'] ?? prevComments) + 1;
            }
          });
          try { debugPrint('[ClassDetail] _showCommentDialog SERVER returned comment index=$index commentsLen=${(post['comments'] is List ? (post['comments'] as List).length : -1)}'); } catch (_) {}
        }
      }
    } catch (e) {
      // revert
      setState(() {
        if (post['comments'] is List) {
          (post['comments'] as List).removeLast();
        } else {
          post['commentsCount'] = prevComments;
        }
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  // Show full comments for a post
  Future<void> _showCommentsFull(int index) async {
    if (index < 0 || index >= _posts.length) return;
    final raw = _posts[index];
    if (raw == null || raw is! Map<String, dynamic>) return;
    final post = raw as Map<String, dynamic>;
    final String postId = (post['_id'] ?? post['id'] ?? '').toString();
    if (postId.isEmpty) return;

    // Try to use in-memory comments if present
    List comments = [];
    if (post['comments'] is List) {
      comments = List.from(post['comments']);
    } else {
      // Attempt a lightweight refresh of posts to populate comments
      await _loadClassData();
      final refreshed = _posts.firstWhere((p) => (p['_id'] ?? p['id'] ?? '').toString() == postId, orElse: () => null);
      if (refreshed != null && refreshed is Map && refreshed['comments'] is List) {
        comments = List.from(refreshed['comments']);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Comments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: comments.isEmpty
                        ? Center(
                            child: Text(
                              'No comments yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )                        : ListView.separated(
                            controller: controller,
                            itemBuilder: (c, i) {
                              final cm = comments[i];
                              final author = (cm is Map && cm['author'] != null)
                                  ? (cm['author'] is Map ? (cm['author']['name'] ?? 'Unknown') : cm['author'].toString())
                                  : (cm is Map ? (cm['authorName'] ?? 'Unknown') : 'Unknown');
                              final text = cm is Map ? (cm['content'] ?? cm['text'] ?? '') : cm.toString();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AvatarWidget(
                                      initials: _getInitials(author),
                                      image: (cm is Map && cm['author'] is Map) ? (cm['author']['profileImage'] as String?) : null,
                                      radius: 18,
                                      backgroundColor: const Color(0xFFEDF2FF),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.blue.shade50),
                                        ),
                                        child: Text(
                                          text,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemCount: comments.length,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              // Make tabs evenly take up available width
              isScrollable: false,
              // Remove extra horizontal padding so spacing is exact
              labelPadding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Files'),
                Tab(text: 'Tests'),
                Tab(text: 'Performance'),
              ],
            ),
          ),
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
                          _buildPerformanceTab(),
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

  Widget _buildPerformanceTab() {
    return PerformanceTabContent(classId: widget.classId);
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
          try { debugPrint('[ClassDetail] post index=$index id=${post['_id'] ?? post['id']} commentsListLen=${(post['comments'] is List ? (post['comments'] as List).length : -1)} commentsCount=${post['commentsCount'] ?? 'n/a'}'); } catch (_) {}
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
                    AvatarWidget(
                      initials: _getInitials(authorName),
                      image: author['profileImage'] as String?,
                      radius: 20,
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
                const SizedBox(height: 12),
                // Like / Comment row
                Builder(builder: (context) {
                  final likesCount = post['likesCount'] ?? (post['likes'] is List ? (post['likes'] as List).length : 0);
                  final liked = post['likedByCurrentUser'] ?? post['liked'] ?? false;
                  final commentsCount = post['comments'] is List
                      ? (post['comments'] as List).length
                      : (post['commentsCount'] ?? 0);

                  return Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleLikePostAt(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: liked ? Colors.red : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$likesCount',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => _showCommentDialog(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mode_comment_outlined,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$commentsCount',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),                // Recent comments preview (show up to 3)
                Builder(builder: (context) {
                  final rawComments = post['comments'];
                  final List comments = rawComments is List ? rawComments : [];
                  if (comments.isEmpty) {
                    // If server only provided a count, show a tappable label
                    final count = post['commentsCount'] ?? 0;
                    if (count > 0) {
                      return GestureDetector(
                        onTap: () => _showCommentsFull(index),
                        child: Text(
                          '$count comments',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final toShow = comments.length > 3 ? comments.sublist(0, 3) : comments;
                  return Column(
                    children: toShow.map<Widget>((c) {
                      final text = c is Map ? (c['content'] ?? c['text'] ?? '') : c.toString();
                      final author = (c is Map && c['author'] != null)
                          ? (c['author'] is Map ? c['author']['name'] ?? 'Unknown' : c['author'].toString())
                          : (c is Map ? (c['authorName'] ?? 'Unknown') : 'Unknown');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AvatarWidget(
                              initials: _getInitials(author),
                              image: (c is Map && c['author'] is Map) ? (c['author']['profileImage'] as String?) : null,
                              radius: 14,
                              backgroundColor: const Color(0xFFEDF2FF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  text,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                      ..addAll(comments.length > 3
                          ? [
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _showCommentsFull(index),
                                child: const Text('View all comments', style: TextStyle(color: Color(0xFF2463EB), fontSize: 13)),
                              )
                            ]
                          : []),
                  );
                }),
                const SizedBox(height: 12),
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
          final fileName = file['name'] ?? 'Unnamed File';
          final fileUrl = file['url'] ?? '';
          final fileId = file['_id'] ?? '';

          return InkWell(
            onTap: () => _handleFileDownload(fileId, fileName, fileUrl),
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
                          fileName,
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
                              fileType[0].toUpperCase() + fileType.substring(1),
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
        separatorBuilder: (context, index) => const SizedBox(height: 12),        itemBuilder: (context, index) {
          final test = _tests[index];
          final isMcq = test['type'] == 'mcq';
          final questions = test['questions'] as List<dynamic>? ?? [];
          final segmentationCases = test['segmentationCases'] as List<dynamic>? ?? [];
          final itemCount = isMcq ? questions.length : segmentationCases.length;
          final itemLabel = isMcq ? 'questions' : 'cases';

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
                                isMcq ? 'MCQ' : 'Segmentation',
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
                              '$itemCount $itemLabel',
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

// Performance Tab Widget
class PerformanceTabContent extends StatefulWidget {
  final String classId;

  const PerformanceTabContent({
    Key? key,
    required this.classId,
  }) : super(key: key);

  @override
  State<PerformanceTabContent> createState() => _PerformanceTabContentState();
}

class _PerformanceTabContentState extends State<PerformanceTabContent> {
  List<LeaderboardUser> leaderboard = [];
  bool isLoading = true;
  String? errorMessage;
  int totalScore = 0;
  int testsCompleted = 0;
  double averageScore = 0.0;

  @override
  void initState() {
    super.initState();
    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await ApiService.getLeaderboard(widget.classId);

      if (data['success'] == false) {
        throw Exception(data['message'] ?? 'Failed to load leaderboard');
      }

      final List<dynamic> leaderboardData = data['leaderboard'] ?? [];
      final currentUserData = data['currentUser'];

      setState(() {
        leaderboard = leaderboardData
            .map((user) => LeaderboardUser.fromJson(user))
            .toList();

        if (currentUserData != null) {
          totalScore = currentUserData['score'] ?? 0;
          testsCompleted = currentUserData['testsCompleted'] ?? 0;
          averageScore = testsCompleted > 0 ? (totalScore / testsCompleted) : 0.0;
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2463EB),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading leaderboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: fetchLeaderboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2463EB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchLeaderboard,
      color: const Color(0xFF2463EB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leaderboard Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🏆',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${totalScore}P',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2463EB),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Leaderboard Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: leaderboard.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No leaderboard data available',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: leaderboard.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;
                        final isLast = index == leaderboard.length - 1;

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: user.isCurrentUser
                                ? const Color(0xFFEFF6FF)
                                : Colors.white,
                            border: !isLast
                                ? Border(
                                    bottom: BorderSide(
                                      color: Colors.blue.shade100,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              // Rank
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${user.rank}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: user.rank <= 3
                                        ? const Color(0xFF2463EB)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: user.isCurrentUser
                                      ? const Color(0xFF2463EB)
                                      : const Color(0xFFDBEAFE),
                                  shape: BoxShape.circle,
                                  border: user.isCurrentUser
                                      ? Border.all(
                                          color: const Color(0xFF2463EB),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    user.avatar,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: user.isCurrentUser
                                          ? Colors.white
                                          : const Color(0xFF2463EB),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Name and Badge
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: user.isCurrentUser
                                              ? const Color(0xFF1E40AF)
                                              : const Color(0xFF1E293B),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBEAFE),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'You',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Score
                              Text(
                                '${user.score}P',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2463EB),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 24),

            // Your Stats
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tests Completed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$testsCompleted',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Average Score',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${averageScore.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2463EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Leaderboard User Model
class LeaderboardUser {
  final int rank;
  final String name;
  final String avatar;
  final int score;
  final bool isCurrentUser;
  final int testsCompleted;

  LeaderboardUser({
    required this.rank,
    required this.name,
    required this.avatar,
    required this.score,
    required this.testsCompleted,
    this.isCurrentUser = false,
  });

  factory LeaderboardUser.fromJson(Map<String, dynamic> json) {
    return LeaderboardUser(
      rank: json['rank'] ?? 0,
      name: json['name'] ?? 'Unknown',
      avatar: json['avatar'] ?? 'U',
      score: json['score'] ?? 0,
      testsCompleted: json['testsCompleted'] ?? 0,
      isCurrentUser: json['isCurrentUser'] ?? false,
    );
  }
}