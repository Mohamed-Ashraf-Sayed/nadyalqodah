import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/constants/api_constants.dart';

class VersionInfo {
  VersionInfo({
    required this.minBuild,
    required this.latestBuild,
    required this.latestVersion,
    required this.storeUrl,
    required this.changelogAr,
  });

  final int minBuild;
  final int latestBuild;
  final String latestVersion;
  final String storeUrl;
  final String changelogAr;
}

class VersionCheckResult {
  VersionCheckResult({
    required this.forceUpdate,
    required this.softUpdate,
    required this.info,
    required this.currentBuild,
  });

  final bool forceUpdate;
  final bool softUpdate;
  final VersionInfo? info;
  final int currentBuild;
}

class VersionService {
  Future<VersionCheckResult> check() async {
    final pkg = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(pkg.buildNumber) ?? 0;

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final res = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.apiPath}/version',
      );
      final data = res.data as Map<String, dynamic>;
      final platformKey = Platform.isIOS ? 'ios' : 'android';
      final p = (data[platformKey] as Map?)?.cast<String, dynamic>() ?? {};

      final info = VersionInfo(
        minBuild: (p['minBuild'] as int?) ?? 1,
        latestBuild: (p['latestBuild'] as int?) ?? 1,
        latestVersion: (p['latestVersion'] as String?) ?? '1.0.0',
        storeUrl: (p['storeUrl'] as String?) ?? '',
        changelogAr: (data['changelogAr'] as String?) ?? '',
      );

      return VersionCheckResult(
        forceUpdate: currentBuild < info.minBuild,
        softUpdate: currentBuild < info.latestBuild,
        info: info,
        currentBuild: currentBuild,
      );
    } catch (_) {
      return VersionCheckResult(
        forceUpdate: false,
        softUpdate: false,
        info: null,
        currentBuild: currentBuild,
      );
    }
  }
}

final versionServiceProvider = Provider<VersionService>((_) => VersionService());

final versionCheckProvider = StateProvider<VersionCheckResult?>((_) => null);

Future<void> runVersionCheck(WidgetRef ref) async {
  final result = await ref.read(versionServiceProvider).check();
  ref.read(versionCheckProvider.notifier).state = result;
}
