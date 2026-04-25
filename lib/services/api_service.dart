// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'websocket_service.dart';
import 'dart:io';
import 'dart:typed_data';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // Singleton socket instance
  static final WebSocketService _socketInstance = WebSocketService();
  static WebSocketService get socket => _socketInstance;

  // RAG server base URL helper: many developers run the RAG FastAPI on port 3000.
  // This derives a host from `baseUrl` and switches the port to 3000 so the
  // Flutter client can talk to a separate RAG server without changing the main
  // ApiService.baseUrl constant. Change as needed to point at your machine IP.
  // Implementation is provided below; duplicate removed.

  // RAG server base URL derived from ApiService.baseUrl host but forced to port 3000
  static String get ragBaseUrl {
    try {
      final uri = Uri.parse(baseUrl);
      // Build a RAG base URI on the same scheme/host but port 3000
      final ragUri = Uri(scheme: uri.scheme, host: uri.host, port: 3000);
      return ragUri.toString(); // e.g. http://192.168.1.10:3000
    } catch (e) {
      // Fallback to localhost:3000 if parsing fails
      return 'http://127.0.0.1:3000';
    }
  }

  // Authentications
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      // Debug: log profileImage received on login
      try { debugPrint('ApiService.login response user.profileImage: ${data['user']?['profileImage']}'); } catch (_) {}

      if (data['success'] && data['token'] != null) {
        await _saveAuthData(data['token'], data['user']);
        // Diagnostic: log what the backend returned for the user object and profileImage
        try {
          print('[ApiService] login response user: ${data['user']}');
          final user = data['user'] as Map<String, dynamic>?;
          print('[ApiService] login response profileImage: ${user != null ? user['profileImage'] : 'null'}');
        } catch (e) {
          print('[ApiService] failed to print login user/profileImage: $e');
        }
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String name,
    required String password,
    String? profileImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': name,
          'password': password,
          'role': 'student',
          'profileImage': profileImage,
        }),
      );

      final data = json.decode(response.body);

      if (data['success'] && data['token'] != null) {
        await _saveAuthData(data['token'], data['user']);
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  } static Future<Map<String, dynamic>> forgotPassword({
  required String email,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    return json.decode(response.body); // just return the data, nothing else
  } catch (e) {
    return {
      'success': false,
      'message': 'Network error: ${e.toString()}',
    };
  }
}
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/reset-password/$token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'password': newPassword}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Classes
  static Future<Map<String, dynamic>> getStudentClasses() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/classes/student'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> joinClass({
    required String code,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/classes/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'code': code}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getClassDetails(String classId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/classes/$classId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Posts
  static Future<Map<String, dynamic>> getPosts(String classId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/classes/$classId/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Add a comment to a post
  static Future<Map<String, dynamic>> addPostComment({
    required String classId,
    required String postId,
    required String text,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/classes/$classId/posts/$postId/comments'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': text}),
      );

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Toggle like for a post (backend should respond with { success, liked, likesCount })
  static Future<Map<String, dynamic>> toggleLikePost({
    required String classId,
    required String postId,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/classes/$classId/posts/$postId/like'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Files
  static Future<Map<String, dynamic>> getFiles(String classId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/classes/$classId/files'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> downloadFile(
      String classId, String fileId) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/classes/$classId/files/$fileId/download'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Tests
  static Future<Map<String, dynamic>> getTests(String classId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/tests/class/$classId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getTestDetails(String testId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/tests/$testId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> submitTest({
    required String testId,
    required List<int> answers,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/tests/$testId/submit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'answers': answers}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Performance & Leaderboard
  static Future<Map<String, dynamic>> getLeaderboard(String classId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/classes/$classId/leaderboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      // Debug: print full response and profileImage field so developer can verify
      try {
        debugPrint('ApiService.getUserProfile response: $data');
        debugPrint('ApiService.getUserProfile user.profileImage: ${data['user']?['profileImage']}');
      } catch (_) {}
      // Diagnostic: print the full profile response and profileImage field
      try {
        print('[ApiService] getUserProfile response: $data');
        if (data.containsKey('user')) {
          final user = data['user'];
          print('[ApiService] getUserProfile user.profileImage: ${user is Map ? user['profileImage'] : user}');
        } else {
          print('[ApiService] getUserProfile profileImage: ${data['profileImage']}');
        }
      } catch (e) {
        print('[ApiService] failed to print getUserProfile profileImage: $e');
      }

      return data;
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? profileImage,
  }) async {
    try {
      final token = await getToken();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (profileImage != null) body['profileImage'] = profileImage;

      final response = await http.put(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Status APIs
  static Future<Map<String, dynamic>> updateUserStatus({
    String? message,
    String? availability,
    String? customEmoji,
    int? expiresIn,
  }) async {
    try {
      final token = await getToken();
      final body = <String, dynamic>{};
      if (message != null) body['message'] = message;
      if (availability != null) body['availability'] = availability;
      if (customEmoji != null) body['customEmoji'] = customEmoji;
      if (expiresIn != null) body['expiresIn'] = expiresIn;

      final response = await http.put(
        Uri.parse('$baseUrl/user/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> clearUserStatus() async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/user/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Chat APIs
  static Future<Map<String, dynamic>> getChatList() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> startChat(String teacherId) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/start/$teacherId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getChatMessages(String chatId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
  }) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chat/$chatId/message'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'content': content}),
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUnreadChatCount() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chat/unread/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Notification APIs
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/notifications?page=$page&limit=$limit&unreadOnly=$unreadOnly'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread/count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> markNotificationAsRead(
      String notificationId) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> deleteNotification(
      String notificationId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return json.decode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // ───────── Segmentation APIs ─────────
  static Future<Map<String, dynamic>> getSegmentationTest(String testId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/segmentation-tests/$testId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Uint8List> getSegmentationSlice({required String testId, required int caseIndex}) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/segmentation-tests/$testId/slice/$caseIndex'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) throw Exception('Failed to load CT slice');
    return res.bodyBytes;
  }

  static Future<Uint8List> getSegmentationGroundTruth({required String testId, required int caseIndex}) async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/segmentation-tests/$testId/ground-truth/$caseIndex'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) throw Exception('Failed to load ground truth');
    return res.bodyBytes;
  }

  static Future<Map<String, dynamic>> submitSegmentationCase({
  required String testId,
  required int    caseIndex,
  required File   maskFile,
}) async {
  final token   = await getToken();
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/segmentation-tests/$testId/submit-case/$caseIndex'),
  )
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath(
      'mask',
      maskFile.path,
      filename:    'mask.png',
      contentType: MediaType('image', 'png'),  // ← explicit MIME type
    ));

  final streamed = await request.send();
  final res      = await http.Response.fromStream(streamed);
  return jsonDecode(res.body) as Map<String, dynamic>;
}
  static Future<Map<String, dynamic>> finaliseSegmentationTest({
    required String testId,
    required List<Map<String, dynamic>> caseResults,
  }) async {
    try {
      final token = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/segmentation-tests/$testId/finalise'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'caseResults': caseResults}),
      );
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getSegmentationTests(String classId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/segmentation-tests/class/$classId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        // Return structured error so frontend can handle it gracefully
        return {
          'success': false,
          'status': response.statusCode,
          'message': response.body.isNotEmpty ? response.body : 'Failed to fetch segmentation tests',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // RAG query: text + optional image file
  // ───────── RAG APIs (student-accessible) ─────────

/// POST /api/v1/chat — ask questions against teacher-uploaded documents
// ───────── RAG APIs (student-accessible) ─────────
static Future<Map<String, dynamic>> ragChat({
  required String message,
  List<Map<String, dynamic>>? conversationHistory,
}) async {
  try {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$ragBaseUrl/api/v1/chat'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'question': message,
        'conversation_history': conversationHistory ?? [],
      }),
    );
    return json.decode(res.body) as Map<String, dynamic>;
  } catch (e) {
    return {'success': false, 'message': 'Network error: ${e.toString()}'};
  }
}

static Future<Map<String, dynamic>> ragVisionAnalyze({
  required File imageFile,
  String? text,
}) async {
  try {
    final token = await getToken();
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$ragBaseUrl/api/v1/vision/analyze'),
    );
    if (token != null) req.headers['Authorization'] = 'Bearer $token';

    // 'question' not 'text'
    if (text != null) req.fields['question'] = text;

    final lower = imageFile.path.toLowerCase();
    req.files.add(await http.MultipartFile.fromPath(
      'file',   // 'file' not 'image'
      imageFile.path,
      contentType: MediaType('image', lower.endsWith('.png') ? 'png' : 'jpeg'),
    ));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return json.decode(res.body) as Map<String, dynamic>;
  } catch (e) {
    return {'success': false, 'message': 'Network error: ${e.toString()}'};
  }
}
  // Helper methods
  static Future<void> _saveAuthData(
      String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', json.encode(user));
    // Debug: log saved user profileImage
    try { debugPrint('ApiService._saveAuthData saved user.profileImage: ${user['profileImage']}'); } catch (_) {}
    // Diagnostic: print saved user/profileImage so we can inspect persisted value
    try {
      print('[ApiService] _saveAuthData saved token length: ${token.length}');
      print('[ApiService] _saveAuthData user: $user');
      print('[ApiService] _saveAuthData profileImage: ${user['profileImage']}');
    } catch (e) {
      print('[ApiService] failed to print saved auth data: $e');
    }
  }

  // Debug helper: prints cached user from SharedPreferences so callers can verify stored profileImage
  static Future<void> debugPrintCachedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString == null) {
        print('[ApiService] debug cached user: <none>');
        return;
      }
      final user = json.decode(userString);
      print('[ApiService] debug cached user: $user');
      try {
        print('[ApiService] debug cached profileImage: ${user['profileImage']}');
      } catch (_) {
        print('[ApiService] debug cached profileImage: <not found>');
      }
    } catch (e) {
      print('[ApiService] debugPrintCachedUserProfile failed: $e');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      return json.decode(userString);
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}