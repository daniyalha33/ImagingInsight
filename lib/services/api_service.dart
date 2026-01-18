// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use your laptop's local IP address for real device testing
  static const String baseUrl = 'http://192.168.100.36:5000/api';

  // Authentication
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
        Uri.parse('$baseUrl/notifications?page=$page&limit=$limit&unreadOnly=$unreadOnly'),
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

  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
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

  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
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

  // Helper methods
  static Future<void> _saveAuthData(
      String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', json.encode(user));
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