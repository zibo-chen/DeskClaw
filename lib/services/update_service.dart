import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:coraldesk/constants.dart';

/// Result of a version check against GitHub Releases.
class UpdateCheckResult {
  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.releaseUrl,
    this.releaseNotes,
    this.error,
  });

  final bool hasUpdate;
  final String? latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final String? error;

  factory UpdateCheckResult.upToDate() =>
      const UpdateCheckResult(hasUpdate: false);

  factory UpdateCheckResult.available({
    required String version,
    required String url,
    String? notes,
  }) => UpdateCheckResult(
    hasUpdate: true,
    latestVersion: version,
    releaseUrl: url,
    releaseNotes: notes,
  );

  factory UpdateCheckResult.failure(String message) =>
      UpdateCheckResult(hasUpdate: false, error: message);
}

/// Checks GitHub Releases API for the latest published version.
class UpdateService {
  UpdateService._();

  static const _apiBase = 'https://api.github.com';

  /// Fetches the latest non-pre-release from GitHub and compares it
  /// against the current [AppConstants.appVersion].
  static Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final uri = Uri.parse(
        '$_apiBase/repos/${AppConstants.githubOwner}/${AppConstants.githubRepo}/releases/latest',
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/vnd.github+json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 404) {
        // No published release yet
        return UpdateCheckResult.upToDate();
      }

      if (response.statusCode != 200) {
        return UpdateCheckResult.failure(
          'GitHub API returned ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? '';
      final body = data['body'] as String?;

      if (_isNewerVersion(tagName, AppConstants.appVersion)) {
        return UpdateCheckResult.available(
          version: tagName,
          url: htmlUrl,
          notes: body,
        );
      }

      return UpdateCheckResult.upToDate();
    } catch (e) {
      return UpdateCheckResult.failure(e.toString());
    }
  }

  /// Compares two semver-like tags (e.g. `v1.2.3`).
  /// Returns true if [remote] is strictly newer than [local].
  static bool _isNewerVersion(String remote, String local) {
    final rParts = _parseVersion(remote);
    final lParts = _parseVersion(local);
    if (rParts == null || lParts == null) return false;

    for (var i = 0; i < 3; i++) {
      if (rParts[i] > lParts[i]) return true;
      if (rParts[i] < lParts[i]) return false;
    }
    return false;
  }

  /// Extracts major.minor.patch from a tag like `v0.1.0`.
  static List<int>? _parseVersion(String tag) {
    final cleaned = tag.replaceAll(RegExp(r'^v'), '');
    final parts = cleaned.split('.');
    if (parts.length < 3) return null;
    try {
      return [
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2].split(RegExp(r'[^0-9]')).first),
      ];
    } catch (_) {
      return null;
    }
  }
}
