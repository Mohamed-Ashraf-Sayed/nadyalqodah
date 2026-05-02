import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../data/providers/providers.dart';

/// Helper to resolve a file URL (relative or absolute) and provide
/// auth headers when needed (for /api/files/* protected endpoints).
class AuthImage extends ConsumerWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorWidget;
  final Widget? placeholder;

  const AuthImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullUrl = url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
    final needsAuth = fullUrl.contains('/api/files/');

    return FutureBuilder<Map<String, String>?>(
      future: needsAuth ? _buildHeaders(ref) : Future.value(null),
      builder: (ctx, snap) {
        return CachedNetworkImage(
          imageUrl: fullUrl,
          fit: fit,
          width: width,
          height: height,
          httpHeaders: snap.data,
          placeholder: (_, __) =>
              placeholder ?? Container(color: Colors.grey.shade100),
          errorWidget: (_, __, ___) =>
              errorWidget ?? Container(color: Colors.grey.shade200),
        );
      },
    );
  }

  static Future<Map<String, String>?> _buildHeaders(WidgetRef ref) async {
    final tokens = ref.read(tokenStorageProvider);
    final access = await tokens.getAccess();
    if (access == null) return null;
    return {'Authorization': 'Bearer $access'};
  }
}

/// Helper to get an ImageProvider for use in CircleAvatar / DecorationImage
/// that includes auth headers when needed.
Future<ImageProvider?> buildAuthImageProvider(WidgetRef ref, String url) async {
  final fullUrl = url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url';
  final needsAuth = fullUrl.contains('/api/files/');
  Map<String, String>? headers;
  if (needsAuth) {
    final access = await ref.read(tokenStorageProvider).getAccess();
    if (access != null) headers = {'Authorization': 'Bearer $access'};
  }
  return CachedNetworkImageProvider(fullUrl, headers: headers);
}
