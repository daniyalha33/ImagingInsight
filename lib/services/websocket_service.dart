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
  bool _isConnecting = false;

  // Track active rooms so we can re-join after reconnection
  final Set<String> _activeClassRooms = {};

  final Map<String, List<Function>> _eventListeners = {};

  bool get isConnected => _isConnected;
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      debugPrint('🔵 Socket already ${_isConnected ? "connected" : "connecting"}, skipping');
      return;
    }
    _isConnecting = true;

    final token = await ApiService.getToken();
    if (token == null) {
      debugPrint('🔴 Socket: No token available - cannot connect');
      return;
    }    // Derive socket URL from ApiService.baseUrl to prevent IP drift
    final String socketUrl = ApiService.baseUrl.replaceAll('/api', '');
    debugPrint('🟡 Socket: Attempting to connect to $socketUrl ...');

    try {
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );      _socket!.connect();
      debugPrint('🟡 Socket: connect() called, waiting for response...');

      // Catch-all: log EVERY event the socket receives (for debugging)
      _socket!.onAny((event, data) {
        debugPrint('📡 Socket: received event "$event" with data: $data');
      });_socket!.onConnect((_) {
        debugPrint('🟢 Socket: Connected successfully! ✅');
        debugPrint('🟢 Socket: socket.id = ${_socket?.id}');
        _isConnected = true;
        _isConnecting = false;

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
      });      _socket!.onConnectError((data) {
        debugPrint('🔴 Socket: Connection Error: $data');
        _isConnected = false;
        _isConnecting = false;
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
      });    } catch (e) {
      debugPrint('🔴 Socket: Exception during connect: $e');
      _isConnected = false;
      _isConnecting = false;
    }}  void joinClass(String classId) {
    // Backend adds "class_" prefix, so send raw classId
    // The final room name will be "class_${classId}"
    _activeClassRooms.add(classId);

    if (_isConnected && _socket != null) {      // Send raw classId - backend will create room "class_${classId}"
      _socket!.emit('class:join', classId);
      debugPrint('📌 Socket: Sent class:join with classId: $classId (room will be class_$classId)');
    } else {
      debugPrint('⚠️ Socket: Not connected yet — class $classId queued for join on reconnect');
    }
  }

  void leaveClass(String classId) {
    _activeClassRooms.remove(classId);

    if (_isConnected && _socket != null) {
      _socket!.emit('class:leave', classId);
      debugPrint('📌 Socket: Left class room: $classId');
    }
  }
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
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

  /// Debug helper: prints socket state and active rooms
  void printDebugInfo() {
    debugPrint('═══════════ SOCKET DEBUG INFO ═══════════');
    debugPrint('  connected: $_isConnected');
    debugPrint('  socket id: ${_socket?.id}');
    debugPrint('  active class rooms: $_activeClassRooms');
    debugPrint('  event listeners: ${_eventListeners.keys.toList()}');
    for (final key in _eventListeners.keys) {
      debugPrint('    $key → ${_eventListeners[key]!.length} listener(s)');
    }
    debugPrint('═════════════════════════════════════════');
  }
}