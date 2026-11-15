import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Anonymous usage counts, sent to Aptabase.
///
/// What it answers: how far players get, where they give up, which ads and
/// products are seen and used. What it never holds: an identifier. There is
/// no user or device id, only a session id that rolls over after an hour of
/// silence, and Aptabase does not store IP addresses.
///
/// Written against Aptabase's HTTP API rather than its Flutter SDK, which
/// pulls in `device_info_plus` — another native iOS plugin to keep building
/// on this Mac's Xcode 15.2. The wire format is the SDK's own
/// (aptabase_flutter 0.5.0): a JSON array of events POSTed to
/// `/api/v0/events` with the app key in an `App-Key` header.
///
/// Off unless the build passes `--dart-define=APTABASE_KEY=A-EU-…`, so debug
/// runs, tests and screenshot tooling never send anything.
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  static const _appKey = String.fromEnvironment('APTABASE_KEY');
  static const _sdkVersion = 'arrows-http@1';
  static const _hosts = {
    'EU': 'https://eu.aptabase.com',
    'US': 'https://us.aptabase.com',
  };

  /// Aptabase accepts at most this many events per request.
  static const _batch = 25;

  /// Events kept while offline; the oldest go first beyond this.
  static const _maxQueued = 500;

  static const _sessionTimeout = Duration(hours: 1);

  Uri? _endpoint;
  Map<String, Object?> _system = const {};
  final List<Map<String, Object?>> _queue = [];
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _sending = false;
  String _session = _newSessionId();
  DateTime _lastEvent = DateTime.now();

  bool get enabled => _endpoint != null;

  /// Reads the app version and starts the send timer. Local only — nothing
  /// goes over the network until the first flush.
  Future<void> init() async {
    if (_endpoint != null) return;
    final parts = _appKey.split('-');
    final host = parts.length == 3 ? _hosts[parts[1]] : null;
    if (host == null) return;

    var version = '';
    var build = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = info.buildNumber;
    } catch (_) {}

    _system = {
      'isDebug': kDebugMode,
      'osName': Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : ''),
      'osVersion': _osVersion(),
      'locale': Platform.localeName,
      'appVersion': version,
      'appBuildNumber': build,
      'sdkVersion': _sdkVersion,
    };
    _endpoint = Uri.parse('$host/api/v0/events');
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
    _lifecycle = AppLifecycleListener(onInactive: flush, onHide: flush);
  }

  /// Records one event. Property values should be strings or numbers.
  void track(String name, [Map<String, Object?> props = const {}]) {
    if (!enabled) return;
    final now = DateTime.now();
    if (now.difference(_lastEvent) > _sessionTimeout) {
      _session = _newSessionId();
    }
    _lastEvent = now;
    _queue.add({
      'timestamp': now.toUtc().toIso8601String(),
      'sessionId': _session,
      'eventName': name,
      'systemProps': _system,
      'props': props,
    });
    if (_queue.length > _maxQueued) {
      _queue.removeRange(0, _queue.length - _maxQueued);
    }
    if (_queue.length >= _batch) unawaited(flush());
  }

  /// Sends what is queued. Failures keep the events for the next try, except
  /// a 4xx, which no retry would fix.
  Future<void> flush() async {
    final endpoint = _endpoint;
    if (endpoint == null || _sending || _queue.isEmpty) return;
    _sending = true;
    final batch = _queue.take(_batch).toList(growable: false);
    try {
      final response = await http
          .post(
            endpoint,
            headers: {
              'App-Key': _appKey,
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(batch),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 500) _queue.removeRange(0, batch.length);
    } catch (_) {
      // Offline or timed out: keep them for the next tick.
    } finally {
      _sending = false;
    }
  }

  @visibleForTesting
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
  }

  /// "Version 17.2 (Build 21C62)" on iOS. Android's string is the kernel's,
  /// which says nothing useful, so it is left out there.
  static String _osVersion() {
    if (!Platform.isIOS) return '';
    final match =
        RegExp(r'Version ([\d.]+)').firstMatch(Platform.operatingSystemVersion);
    return match?.group(1) ?? '';
  }

  /// Same shape as the SDK's: epoch seconds followed by eight random digits.
  static String _newSessionId() {
    final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final random = Random().nextInt(100000000).toString().padLeft(8, '0');
    return '$seconds$random';
  }
}
