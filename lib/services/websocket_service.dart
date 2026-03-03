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

  // Track active rooms so we can re-join after reconnection
  final Set<String> _activeClassRooms = {};

  final Map<String, List<Function>> _eventListeners = {};

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('🔵 Socket already connected, skipping');
      return;
    }

    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('🔴 Socket: No token available - cannot connect');
      return;
    }    // Use the same base URL as ApiService (without /api)
    const String socketUrl = 'http://10.113.82.41:5000';
    debugPrint('🟡 Socket: Attempting to connect to $socketUrl ...');

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _socket!.connect();
      debugPrint('🟡 Socket: connect() called, waiting for response...');

      _socket!.onConnect((_) {
        debugPrint('🟢 Socket: Connected successfully! ✅');
        _isConnected = true;

        // Re-join all active class rooms after reconnection
        if (_activeClassRooms.isNotEmpty) {
          for (final classId in _activeClassRooms) {
            _socket!.emit('class:join', classId);
            debugPrint('🔄 Socket: Re-joined class room after reconnect: $classId');
          }
        }

        _notifyListeners('connection:status', {'connected': true});
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔴 Socket: Disconnected');
        _isConnected = false;
        _notifyListeners('connection:status', {'connected': false});
      });

      _socket!.onConnectError((data) {
        debugPrint('🔴 Socket: Connection Error: $data');
        _isConnected = false;
      });

      _socket!.onError((data) {
        debugPrint('🔴 Socket: Error: $data');
      });

      // Live class events
      _socket!.on('liveClassStarted', (data) {
        debugPrint('🔥 Socket: liveClassStarted received: $data');
        _notifyListeners('liveClassStarted', data);
      });

      _socket!.on('liveClassEnded', (data) {
        debugPrint('🔥 Socket: liveClassEnded received: $data');
        _notifyListeners('liveClassEnded', data);
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
      debugPrint('🔴 Socket: Exception during connect: $e');
      _isConnected = false;
    }
  }
  void joinClass(String classId) {
    // Backend expects room name with "class_" prefix
    final roomName = 'class_$classId';
    
    // Always track the room regardless of connection state
    _activeClassRooms.add(roomName);

    if (_isConnected && _socket != null) {
      _socket!.emit('class:join', roomName);
      debugPrint('📌 Socket: Joined class room: $roomName');
    } else {
      // Not connected yet — room is saved in _activeClassRooms
      // and will be joined automatically in onConnect
      debugPrint('⚠️ Socket: Not connected yet — class $roomName queued for join on reconnect');
    }
  }

  void leaveClass(String classId) {
    // Backend expects room name with "class_" prefix
    final roomName = 'class_$classId';
    
    // Remove from tracking so we don't re-join after reconnection
    _activeClassRooms.remove(roomName);

    if (_isConnected && _socket != null) {
      _socket!.emit('class:leave', roomName);
      debugPrint('📌 Socket: Left class room: $roomName');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('🔴 Socket: Manually disconnected');
    }
  }

  void joinChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:join', chatId);
      debugPrint('WebSocket: Joined chat $chatId');
    }
  }

  void leaveChat(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:leave', chatId);
      debugPrint('WebSocket: Left chat $chatId');
    }
  }

  void sendTypingIndicator(String chatId, bool isTyping) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:typing', {'chatId': chatId, 'isTyping': isTyping});
    }
  }

  void markChatAsRead(String chatId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('chat:read', {'chatId': chatId});
    }
  }

  void on(String event, Function callback) {
    if (!_eventListeners.containsKey(event)) {
      _eventListeners[event] = [];
    }
    _eventListeners[event]!.add(callback);
  }

  void off(String event, Function callback) {
    if (_eventListeners.containsKey(event)) {
      _eventListeners[event]!.remove(callback);
    }
  }

  void removeAllListeners(String event) {
    _eventListeners.remove(event);
  }

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

  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
}