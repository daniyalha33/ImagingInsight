// lib/screens/mobile/chat_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime timestamp;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    required this.isOwn,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderRole: json['senderRole'],
      text: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isOwn: json['isOwn'] ?? false,
    );
  }

  String get formattedTime {
    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class ChatScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;
  final String? chatId;
  final VoidCallback onBack;

  const ChatScreen({
    Key? key,
    required this.teacherId,
    required this.teacherName,
    this.chatId,
    required this.onBack,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  String? _currentChatId;
  bool _isLoading = true;
  bool _isSending = false;
  String _errorMessage = '';
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_currentChatId != null && !_isSending) {
        _loadMessages(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // If we already have a chatId, use it. Otherwise, create a new chat
      if (widget.chatId != null) {
        _currentChatId = widget.chatId;
      } else {
        final response = await ApiService.startChat(widget.teacherId);
        if (response['success'] == true) {
          _currentChatId = response['chatId'];
        } else {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to start chat';
            _isLoading = false;
          });
          return;
        }
      }

      await _loadMessages();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing chat: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (_currentChatId == null) return;

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await ApiService.getChatMessages(_currentChatId!);
      
      if (response['success'] == true) {
        final chatData = response['chat'];
        final List<dynamic> messagesJson = chatData['messages'] ?? [];
        
        setState(() {
          _messages = messagesJson
              .map((json) => ChatMessage.fromJson(json))
              .toList();
          _isLoading = false;
        });

        // Scroll to bottom after loading messages
        if (showLoading) {
          _scrollToBottom();
        }
      } else {
        if (showLoading) {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load messages';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (showLoading) {
        setState(() {
          _errorMessage = 'Error loading messages: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSend() async {
    if (_messageController.text.trim().isEmpty || _currentChatId == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final response = await ApiService.sendMessage(
        chatId: _currentChatId!,
        content: messageText,
      );

      if (response['success'] == true) {
        // Add the new message to the list
        final newMessage = ChatMessage.fromJson(response['message']);
        setState(() {
          _messages.add(newMessage);
          _isSending = false;
        });
        
        _scrollToBottom();
      } else {
        setState(() {
          _isSending = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
        
        // Restore the message
        _messageController.text = messageText;
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      
      // Restore the message
      _messageController.text = messageText;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
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
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF1E40AF),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2463EB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(widget.teacherName),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.teacherName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const Text(
                            'Online',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      color: const Color(0xFF2463EB),
                      onPressed: () => _loadMessages(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages
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
                              onPressed: _initializeChat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2463EB),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.blue.shade200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue.shade300,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isStudent = message.senderRole == 'student';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: message.isOwn
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: message.isOwn
                                              ? const Color(0xFF2463EB)
                                              : Colors.white,
                                          border: message.isOwn
                                              ? null
                                              : Border.all(color: Colors.blue.shade100),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.text,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: message.isOwn
                                                    ? Colors.white
                                                    : const Color(0xFF1E40AF),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              message.formattedTime,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: message.isOwn
                                                    ? const Color(0xFFBFDBFE)
                                                    : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),

          // Input
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
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFEFF6FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.blue.shade200,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: Colors.blue.shade200,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF2463EB),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isSending
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF2463EB),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : IconButton(
                              onPressed: _handleSend,
                              icon: const Icon(
                                Icons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
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