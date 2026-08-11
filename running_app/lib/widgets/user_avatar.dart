import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double size;
  final double iconSize;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.size = 64,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim() ?? '';

    // 1. Emoji Preset
    if (url.startsWith('preset:')) {
      final emoji = url.replaceFirst('preset:', '');
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.5),
          ),
        ),
      );
    }

    // 2. Base64 Data URI (รูปจากคลัง)
    if (url.startsWith('data:image/')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return _imageCircle(MemoryImage(Uint8List.fromList(bytes)));
      } catch (_) {
        return _defaultAvatar();
      }
    }

    // 3. Network Image URL
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return _imageCircle(NetworkImage(url));
    }

    // 4. Fallback default gradient avatar
    return _defaultAvatar();
  }

  Widget _imageCircle(ImageProvider image) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.person_rounded, color: Colors.white, size: iconSize),
    );
  }
}
