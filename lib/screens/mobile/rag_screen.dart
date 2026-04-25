// lib/screens/mobile/rag_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;
  final String? imagePath; // only for user messages with image

  const ChatMessage({
    required this.role,
    required this.content,
    this.imagePath,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class RagScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RagScreen({Key? key, required this.onBack}) : super(key: key);

  @override
  State<RagScreen> createState() => _RagScreenState();
}

class _RagScreenState extends State<RagScreen>
    with SingleTickerProviderStateMixin {
    TabController? _tabController;

  // ── Chat state ──────────────────────────────────────────────────────────────
  final TextEditingController _chatInput = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // UI messages — what the student sees
  final List<ChatMessage> _messages = [];

  // Server-side history — sent with every request for multi-turn context
  final List<Map<String, String>> _conversationHistory = [];

  bool _chatLoading = false;

  // ── Vision state ────────────────────────────────────────────────────────────
  final TextEditingController _visionInput = TextEditingController();
  File? _imageFile;
  String? _imagePreviewPath;
  bool _visionLoading = false;
  String? _visionResult;
  String? _visionError;
  String? _visionDisclaimer;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _chatInput.dispose();
    _visionInput.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll to bottom ────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Chat ────────────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _chatInput.text.trim();
    if (text.isEmpty || _chatLoading) return;

    _chatInput.clear();

    // Add user message to UI immediately
    setState(() {
      _messages.add(ChatMessage(role: MessageRole.user, content: text));
      _chatLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService.ragChat(
        message: text,
        conversationHistory: List.from(_conversationHistory),
      );

      final answer = res['answer']?.toString() ??
          res['response']?.toString() ??
          res['message']?.toString() ??
          'No response received';

      // Add assistant reply to UI
      setState(() {
        _messages.add(ChatMessage(role: MessageRole.assistant, content: answer));
      });

      // Update server-side history for next turn
      _conversationHistory.addAll([
        {'role': 'user',      'content': text},
        {'role': 'assistant', 'content': answer},
      ]);

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: MessageRole.assistant,
          content: 'Error: ${e.toString()}',
        ));
      });
    } finally {
      setState(() => _chatLoading = false);
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _conversationHistory.clear();
    });
  }

  // ── Vision ──────────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() {
        _imageFile = File(picked.path);
        _imagePreviewPath = picked.path;
        _visionResult = null;
        _visionError = null;
      });
    } catch (e) {
      _showSnack('Image pick error: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null || _visionLoading) return;

    setState(() {
      _visionLoading = true;
      _visionResult = null;
      _visionError = null;
      _visionDisclaimer = null;
    });

    try {
      final text = _visionInput.text.trim();
      final res = await ApiService.ragVisionAnalyze(
        imageFile: _imageFile!,
        text: text.isNotEmpty ? text : null,
      );

      // Prefer the documented 'analysis' field; fall back to other possible keys
      final result = res['analysis']?.toString() ??
          res['answer']?.toString() ??
          res['result']?.toString() ??
          res['data']?.toString() ??
          res['message']?.toString() ??
          'No analysis returned';

      final disclaimer = res['disclaimer']?.toString();

      setState(() {
        _visionResult = result;
        _visionDisclaimer = disclaimer;
      });
    } catch (e) {
      setState(() => _visionError = 'Error: ${e.toString()}');
    } finally {
      setState(() => _visionLoading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('AI Assistant'),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: _clearChat,
            ),
        ],
        bottom: TabBar(
          controller: _tabController!,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Ask a Question'),
            Tab(text: 'Analyze Image'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _buildChatTab(),
          _buildVisionTab(),
        ],
      ),
    );
  }

  // ── Chat tab ─────────────────────────────────────────────────────────────────

  Widget _buildChatTab() {
    return Column(
      children: [
        // Message list
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Ask anything about your course material',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
                ),
        ),

        // Typing indicator
        if (_chatLoading)
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: const Text(
              'Thinking...',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

        // Input bar
        _buildChatInputBar(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF2563EB),
              child: const Text('AI',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2563EB)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildChatInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatInput,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask a question...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _chatLoading ? null : _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _chatLoading
                      ? Colors.grey.shade300
                      : const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: _chatLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Vision tab ───────────────────────────────────────────────────────────────

  Widget _buildVisionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image picker area
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _imagePreviewPath != null
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: _imagePreviewPath != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(
                            File(_imagePreviewPath!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8, right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _imageFile = null;
                              _imagePreviewPath = null;
                              _visionResult = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to select a medical image',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Optional prompt
          TextField(
            controller: _visionInput,
            decoration: InputDecoration(
              hintText: 'Optional: what should the AI look for?',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Analyze button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_imageFile == null || _visionLoading)
                  ? null
                  : _analyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _visionLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,
                      ),
                    )
                  : const Text('Analyze Image', style: TextStyle(fontSize: 15)),
            ),
          ),

          // Error
          if (_visionError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _visionError!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
              ),
            ),
          ],

          // Result
          if (_visionResult != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Analysis Result',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _visionResult!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
            ),

            // Disclaimer
            if (_visionDisclaimer != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _visionDisclaimer!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ],
      ),
    );
  }
}