import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers/providers.dart';

class MemberAvatar extends ConsumerWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  const MemberAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = name.trim().isNotEmpty ? name.trim()[0] : '؟';
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );

    if (photoUrl == null || photoUrl!.isEmpty) return fallback;

    final fullUrl = photoUrl!.startsWith('http')
        ? photoUrl!
        : '${ApiConstants.baseUrl}$photoUrl';
    final needsAuth = fullUrl.contains('/api/files/');

    return FutureBuilder<Map<String, String>?>(
      future: needsAuth ? _headers(ref) : Future.value(null),
      builder: (_, snap) {
        if (needsAuth && snap.connectionState != ConnectionState.done) {
          return fallback;
        }
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: CachedNetworkImageProvider(
            fullUrl,
            headers: snap.data,
          ),
        );
      },
    );
  }

  static Future<Map<String, String>?> _headers(WidgetRef ref) async {
    final access = await ref.read(tokenStorageProvider).getAccess();
    if (access == null) return null;
    return {'Authorization': 'Bearer $access'};
  }
}
