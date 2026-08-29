import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tells the player when a newer version is on the store.
///
/// The two platforms need different machinery. Play has a proper API for this,
/// so Android gets Google's own flexible update flow — it downloads in the
/// background and never blocks play. Apple has no equivalent, so iOS compares
/// against the version in the public iTunes lookup and offers to open the App
/// Store.
///
/// Nothing here is ever forced. The app is fully playable offline and an
/// update it cannot install is not a reason to lock someone out of a puzzle.
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const _keyLastPrompt = 'update_prompted_at';
  static const _keySkipped = 'update_skipped_version';

  /// Nobody needs to be told twice in a week.
  static const _quietDays = 7;

  /// The version waiting on the App Store, or null if this is the latest, the
  /// check failed, or the platform handles it natively.
  String? available;

  /// Checks quietly in the background. Never throws: no network, a store that
  /// has not published yet, a device with no Play Services — all of it just
  /// means no prompt.
  Future<bool> check() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_keyLastPrompt);
      if (last != null) {
        final since = DateTime.now().millisecondsSinceEpoch - last;
        if (since < const Duration(days: _quietDays).inMilliseconds) {
          return false;
        }
      }

      if (Platform.isAndroid) {
        final info = await InAppUpdate.checkForUpdate();
        return info.updateAvailability == UpdateAvailability.updateAvailable;
      }
      if (!Platform.isIOS) return false;

      final info = await PackageInfo.fromPlatform();
      final latest = await _latestOnAppStore(info.packageName);
      if (latest == null) return false;
      if (!_isNewer(latest, info.version)) return false;
      if (prefs.getString(_keySkipped) == latest) return false;
      available = latest;
      return true;
    } catch (e) {
      debugPrint('Update check failed: $e');
      return false;
    }
  }

  /// Records that the player was offered this version and passed.
  Future<void> declined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPrompt, DateTime.now().millisecondsSinceEpoch);
    final version = available;
    if (version != null) await prefs.setString(_keySkipped, version);
  }

  /// Starts the update: Play's in-app flow on Android, the App Store listing
  /// on iOS.
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastPrompt, DateTime.now().millisecondsSinceEpoch);
    try {
      if (Platform.isAndroid) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }
      final info = await PackageInfo.fromPlatform();
      final id = await _appStoreId(info.packageName);
      if (id == null) return;
      await launchUrl(
        Uri.parse('https://apps.apple.com/app/id$id'),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Update start failed: $e');
    }
  }

  Future<Map<String, dynamic>?> _lookup(String bundleId) async {
    final res = await http
        .get(Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId'))
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;
    return Map<String, dynamic>.from(results.first as Map);
  }

  Future<String?> _latestOnAppStore(String bundleId) async =>
      (await _lookup(bundleId))?['version'] as String?;

  Future<String?> _appStoreId(String bundleId) async =>
      (await _lookup(bundleId))?['trackId']?.toString();

  /// Compares dotted versions a segment at a time. "1.10.0" is newer than
  /// "1.9.0", which a string comparison would get backwards.
  static bool _isNewer(String candidate, String current) {
    final a = candidate.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final b = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
