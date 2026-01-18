// lib/services/websocket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callbacks for different events
  final Map<String, List<Function>> _eventListeners = {};

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('WebSocket: No token available');
      return;
    }

    try {
      _socket = IO.io(
        'http://localhost:5000', // Change to your server URL
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('WebSocket: Connected');
        _isConnected = true;
        _notifyListeners('connection:status', {'connected': true});
      });

      _socket!.onDisconnect((_) {
        debugPrint('WebSocket: Disconnected');
        _isConnected = false;
        _notifyListeners('connection:status', {'connected': false});
      });

      _socket!.onConnectError((data) {
        debugPrint('WebSocket: Connection Error: $data');
        _isConnected = false;
      });

      // Chat events
      _socket!.on('message:new', (data) {
        debugPrint('WebSocket: New message received: $data');
        _notifyListeners('message:new', data);
      });

      _socket!.on('message:received', (data) {
        debugPrint('WebSocket: Message received in chat: $data');
        _notifyListeners('message:received', data);
      });

      _socket!.on('messages:read', (data) {
        debugPrint('WebSocket: Messages marked as read: $data');
        _notifyListeners('messages:read', data);
      });

      _socket!.on('user:typing', (data) {
        debugPrint('WebSocket: User typing: $data');
        _notifyListeners('user:typing', data);
      });

      _socket!.on('chat:new', (data) {
        debugPrint('WebSocket: New chat created: $data');
        _notifyListeners('chat:new', data);
      });

      _socket!.on('chat:deleted', (data) {
        debugPrint('WebSocket: Chat deleted: $data');
        _notifyListeners('chat:deleted', data);
      });

      // Notification events
      _socket!.on('notification:new', (data) {
        debugPrint('WebSocket: New notification: $data');
        _notifyListeners('notification:new', data);
      });

      // User presence events
      _socket!.on('user:online', (data) {
        debugPrint('WebSocket: User online: $data');
        _notifyListeners('user:online', data);
      });

      _socket!.on('user:offline', (data) {
        debugPrint('WebSocket: User offline: $data');
        _notifyListeners('user:offline', data);
      });
    } catch (e) {
      debugPrint('WebSocket: Error connecting: $e');
      _isConnected = false;
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('WebSocket: Manually disconnected');
    }
  }

  // Join a chat room
  void joinChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:join', chatId);
      debugPrint('WebSocket: Joined chat $chatId');
    }
  }

  // Leave a chat room
  void leaveChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:leave', chatId);
      debugPrint('WebSocket: Left chat $chatId');
    }
  }

  // Send typing indicator
  void sendTypingIndicator(String chatId, bool isTyping) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:typing', {'chatId': chatId, 'isTyping': isTyping});
    }
  }

  // Mark chat as read
  void markChatAsRead(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:read', {'chatId': chatId});
    }
  }

  // Register event listener
  void on(String event, Function callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  // Remove event listener
  void off(String event, Function callback) {
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callback);
    }
  }

  // Remove all listeners for an event
  void removeAllListeners(String event) {
    _eventListeners.remove(event);
  }

  // Notify all listeners for an event
  void _notifyListeners(String event, dynamic data) {
    if (_eventListeners.containsKey(event)) {
      for (var callback in _eventListeners[event]!) {
        try {
          callback(data);
        } catch (e) {
          debugPrint('WebSocket: Error in callback for $event: $e');
        }
      }
    }
  }

  // Reconnect
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
}