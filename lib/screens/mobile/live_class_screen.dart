// lib/screens/mobile/live_class_screen.dart
//
// SETUP INSTRUCTIONS:
// 1. Add to pubspec.yaml dependencies:
//    agora_rtc_engine: ^6.3.2
//    permission_handler: ^11.3.1
//
// 2. Android: add to android/app/src/main/AndroidManifest.xml inside <manifest>:
//    <uses-permission android:name="android.permission.CAMERA"/>
//    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//    <uses-permission android:name="android.permission.INTERNET"/>
//
// 3. iOS: add to ios/Runner/Info.plist:
//    <key>NSCameraUsageDescription</key>
//    <string>Camera access for live classes</string>
//    <key>NSMicrophoneUsageDescription</key>
//    <string>Microphone access for live classes</string>
//
// USAGE (from ClassDetailScreen or wherever you detect live class):
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => LiveClassScreen(
//       classId: 'abc123',
//       studentName: 'John',
//       authToken: token,
//       apiBaseUrl: 'http://your-backend.com/api',
//     ),
//   ));

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class LiveClassScreen extends StatefulWidget {
  final String classId;
  final String studentName;
  final String authToken;
  final String apiBaseUrl;

  const LiveClassScreen({
    Key? key,
    required this.classId,
    required this.studentName,
    required this.authToken,
    required this.apiBaseUrl,
  }) : super(key: key);

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  RtcEngine? _engine;

  bool _isJoined = false;
  bool _isLoading = true;
  bool _isMicOn = false; // Students start muted by default
  String? _errorMsg;

  // Teacher's remote user ID (we track who published first = teacher)
  int? _teacherUid;
  final List<int> _remoteUids = [];

  @override
  void initState() {
    super.initState();
    _initAndJoin();
  }

  @override
  void dispose() {
    _leaveAndDestroy();
    super.dispose();
  }

  Future<void> _initAndJoin() async {
    try {
      // 1. Request permissions
      await [Permission.microphone, Permission.camera].request();

      // 2. Fetch Agora token from backend
      final channelName = 'class_${widget.classId}';
      final tokenData = await _fetchAgoraToken(channelName);

      // 3. Create engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: tokenData['appId'],
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // 4. Register event handlers
      _engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _isJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) {
            setState(() {
              _teacherUid ??= remoteUid; // First person = teacher
              if (!_remoteUids.contains(remoteUid)) {
                _remoteUids.add(remoteUid);
              }
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) {
            setState(() {
              _remoteUids.remove(remoteUid);
              if (_teacherUid == remoteUid) _teacherUid = null;
            });
          }
        },
        onError: (err, msg) {
          if (mounted) setState(() => _errorMsg = msg);
        },
      ));

      // 5. Set as audience (student watches, doesn't broadcast by default)
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // 6. Enable video
      await _engine!.enableVideo();

      // 7. Join channel
      await _engine!.joinChannel(
        token: tokenData['token'],
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMsg = e.toString();
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchAgoraToken(String channelName) async {
    final res = await http.post(
      Uri.parse('${widget.apiBaseUrl}/live/token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      },
      body: jsonEncode({'channelName': channelName, 'uid': 0}),
    );
    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to get Agora token');
    }
    return data;
  }

  Future<void> _toggleMic() async {
    if (_engine == null) return;
    if (!_isMicOn) {
      // Switch to broadcaster role to speak
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.muteLocalAudioStream(false);
    } else {
      await _engine!.muteLocalAudioStream(true);
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    }
    setState(() => _isMicOn = !_isMicOn);
  }

  Future<void> _leaveAndDestroy() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  void _leaveClass() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Class?'),
        content: const Text('Are you sure you want to leave the live class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? _buildLoading()
            : _errorMsg != null
                ? _buildError()
                : _buildLiveView(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF2563EB)),
          SizedBox(height: 16),
          Text(
            'Joining live class...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Failed to join class',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMsg!,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Go Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() { _isLoading = true; _errorMsg = null; });
                      _initAndJoin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveView() {
    return Column(
      children: [
        // Top bar
        _buildTopBar(),

        // Main video area (teacher)
        Expanded(
          child: Stack(
            children: [
              // Teacher video (full screen)
              _buildTeacherVideo(),

              // "Waiting for teacher" overlay if teacher not yet present
              if (_teacherUid == null)
                _buildWaitingOverlay(),

              // Other remote users (other students with mic on) - small tiles
              if (_remoteUids.length > 1)
                _buildOtherParticipants(),
            ],
          ),
        ),

        // Bottom controls
        _buildControls(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF111827),
      child: Row(
        children: [
          // LIVE badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
                SizedBox(width: 6),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Live Class',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Participant count
          Row(
            children: [
              const Icon(Icons.people_outline, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              Text(
                '${_remoteUids.length + 1}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherVideo() {
    if (_teacherUid == null || _engine == null) {
      return Container(color: const Color(0xFF1F2937));
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: _teacherUid!),
        connection: RtcConnection(channelId: 'class_${widget.classId}'),
      ),
    );
  }

  Widget _buildWaitingOverlay() {
    return Container(
      color: const Color(0xFF111827),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.video_camera_front_outlined, color: Color(0xFF2563EB), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for teacher...',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'The live class will begin shortly',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: const Color(0xFF2563EB).withOpacity(0.6),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherParticipants() {
    // Show other students in small tiles (bottom-right)
    final others = _remoteUids.where((uid) => uid != _teacherUid).take(3).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return Positioned(
      right: 12,
      bottom: 16,
      child: Column(
        children: others.map((uid) {
          return Container(
            width: 100,
            height: 70,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            clipBehavior: Clip.antiAlias,
            child: _engine != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: uid),
                      connection: RtcConnection(channelId: 'class_${widget.classId}'),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: const Color(0xFF111827),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mic toggle (raise hand to speak)
          _ControlButton(
            onTap: _toggleMic,
            isActive: _isMicOn,
            activeColor: const Color(0xFF2563EB),
            inactiveColor: const Color(0xFF374151),
            icon: _isMicOn ? Icons.mic : Icons.mic_off,
            label: _isMicOn ? 'Muted' : 'Speak',
          ),
          const SizedBox(width: 24),
          // Leave button
          GestureDetector(
            onTap: _leaveClass,
            child: Container(
              width: 56,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.call_end, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable control button ────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final IconData icon;
  final String label;

  const _ControlButton({
    required this.onTap,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}