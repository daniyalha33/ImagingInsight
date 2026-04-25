// lib/widgets/avatar_widget.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';

/// Small reusable avatar widget that prefers a profile image (network or
/// base64) and falls back to initials when no image is available.
class AvatarWidget extends StatelessWidget {
  final String? image; // can be a URL, data URL, or raw base64
  final String initials;
  final double radius;
  final Color backgroundColor;

  const AvatarWidget({
    Key? key,
    required this.initials,
    this.image,
    this.radius = 20.0,
    this.backgroundColor = const Color(0xFF2563EB),
  }) : super(key: key);

  ImageProvider? _imageProvider() {
    if (image == null) return null;
    final raw = image!.trim();
    if (raw.isEmpty) return null;

    // Treat literal strings that represent null/none as absent
    final lowerRaw = raw.toLowerCase();
    if (lowerRaw == 'null' || lowerRaw == '<null>' || lowerRaw == 'none') return null;

    String normalized = raw;
    try {
      // If the backend accidentally returned a JSON-encoded object as a string, try to extract common url fields
      if (normalized.startsWith('{') && normalized.endsWith('}')) {
        try {
          final parsed = json.decode(normalized);
          if (parsed is Map && parsed.containsKey('url')) {
            normalized = parsed['url'].toString();
          } else if (parsed is Map && parsed.containsKey('path')) {
            normalized = parsed['path'].toString();
          }
        } catch (_) {
          // ignore parse errors and continue
        }
      }

      final lower = normalized.toLowerCase();
      // If backend returns a relative path or filename, prefix with backend base URL
      if (!lower.startsWith('http://') && !lower.startsWith('https://') && !lower.startsWith('data:')) {
        final base = ApiService.baseUrl.replaceAll('/api', '');
        normalized = base + (normalized.startsWith('/') ? normalized : '/$normalized');
        debugPrint('AvatarWidget: normalized profile image to $normalized');
      }

      final normalizedLower = normalized.toLowerCase();
      if (normalizedLower.startsWith('http://') || normalizedLower.startsWith('https://')) {
        return NetworkImage(normalized);
      }

      // data URL like "data:image/png;base64,...."; ensure it declares base64
      if (normalizedLower.startsWith('data:')) {
        final comma = normalized.indexOf(',');
        if (comma != -1) {
          final meta = normalized.substring(5, comma); // after 'data:'
          final payload = normalized.substring(comma + 1);
          if (meta.contains('base64')) {
            final bytes = base64Decode(payload);
            return MemoryImage(bytes);
          } else {
            // Not base64 encoded data URL - unable to handle
            debugPrint('AvatarWidget: data URL not base64 encoded (meta=$meta)');
            return null;
          }
        }
        return null;
      }

      // Assume raw base64 bytes (defensive)
      final bytes = base64Decode(normalized);
      return MemoryImage(bytes);
    } catch (e) {
      debugPrint('AvatarWidget: failed to load image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider();
    return CircleAvatar(
      radius: radius,
      backgroundColor: provider == null ? backgroundColor : Colors.transparent,
      backgroundImage: provider,
      child: provider == null
          ? Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.6,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}
