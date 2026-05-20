import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final String? avatarUrl;
  final bool isAnonymous;
  final double size;

  const AvatarWidget({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.isAnonymous = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnonymous) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock, color: AppColors.primary, size: size * 0.4),
      );
    }

    if (avatarUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsAvatar(),
          errorWidget: (_, __, ___) => _initialsAvatar(),
        ),
      );
    }

    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }
}
