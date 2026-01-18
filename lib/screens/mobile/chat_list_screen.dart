// lib/screens/mobile/chat_list_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class Teacher {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool hasChat;
  final String? chatId;

  Teacher({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.hasChat = false,
    this.chatId,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['teacherId'],
      name: json['teacherName'] ?? 'Teacher',
      avatar: _getInitials(json['teacherName'] ?? 'T'),
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      hasChat: json['hasChat'] ?? false,
      chatId: json['chatId'],
    );
  }

  static String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  String get statusText {
    if (!hasChat) return 'Start a conversation';
    if (lastMessageTime == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime!);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}

class ChatListScreen extends StatefulWidget {
  final Function(String teacherId, String teacherName, String? chatId) onSelectChat;

  const ChatListScreen({
    Key? key,
    required this.onSelectChat,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Teacher> _allTeachers = [];
  List<Teacher> _filteredTeachers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadChatList();
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChatList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getChatList();
      
      if (response['success'] == true) {
        final List<dynamic> chatsJson = response['chats'] ?? [];
        setState(() {
          _allTeachers = chatsJson.map((json) => Teacher.fromJson(json)).toList();
          _filteredTeachers = _allTeachers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load chats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading chats: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTeachers = _allTeachers;
      } else {
        _filteredTeachers = _allTeachers
            .where((teacher) => teacher.name.toLowerCase().contains(query))
            .toList();
      }
    });
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
                child: Column(
                  children: [
                    // Title Row
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2463EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Chat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: const Color(0xFF2463EB),
                          onPressed: _loadChatList,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search teachers...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF64748B),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Teachers List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2463EB),
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadChatList,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2463EB),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredTeachers.isEmpty
                        ? const Center(
                            child: Text(
                              'No teachers found',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 16,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadChatList,
                            color: const Color(0xFF2463EB),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredTeachers.length,
                              itemBuilder: (context, index) {
                                final teacher = _filteredTeachers[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildTeacherCard(teacher),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherCard(Teacher teacher) {
    return InkWell(
      onTap: () => widget.onSelectChat(teacher.id, teacher.name, teacher.chatId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2463EB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      teacher.avatar,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (teacher.unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        teacher.unreadCount > 9 ? '9+' : '${teacher.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Teacher info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teacher.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacher.hasChat ? teacher.lastMessage : teacher.statusText,
                    style: TextStyle(
                      fontSize: 14,
                      color: teacher.hasChat
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                      fontStyle: teacher.hasChat ? FontStyle.normal : FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (teacher.hasChat && teacher.statusText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        teacher.statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!teacher.hasChat)
              const Icon(
                Icons.chat_bubble_outline,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}