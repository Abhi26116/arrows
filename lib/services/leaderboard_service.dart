import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/progress_store.dart';
import '../firebase/firebase_bootstrap.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.totalStars,
    required this.cleared,
    this.isYou = false,
  });

  final String uid;
  final String name;
  final int totalStars;
  final int cleared;
  final bool isYou;
}

class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  static const _localKey = 'local_leaderboard_cache';

  // Firebase is disabled, so the board is always local. See EXTRAS.md to go online.
  bool get isOnline => FirebaseBootstrap.ready;

  Future<void> ensureSignedIn() async {}

  Future<void> submitScore() async {
    final store = AppStore.instance;
    await _upsertLocal(
      uid: 'local',
      name: store.displayName,
      stars: store.totalStars,
      cleared: store.clearedCount,
    );
  }

  Future<List<LeaderboardEntry>> top({int limit = 25}) async {
    final store = AppStore.instance;
    final local = await _localEntries();
    final you = LeaderboardEntry(
      uid: 'local',
      name: store.displayName,
      totalStars: store.totalStars,
      cleared: store.clearedCount,
      isYou: true,
    );
    final merged = <LeaderboardEntry>[
      ...local.where((e) => e.uid != 'local'),
      you,
    ];
    merged.sort((a, b) {
      final byStars = b.totalStars.compareTo(a.totalStars);
      if (byStars != 0) return byStars;
      return b.cleared.compareTo(a.cleared);
    });
    return merged.take(limit).toList();
  }

  Future<void> _upsertLocal({
    required String uid,
    required String name,
    required int stars,
    required int cleared,
  }) async {
    final existing = await _localEntries();
    if (existing.isEmpty) {
      existing.addAll(const [
        LeaderboardEntry(
            uid: 'bot1', name: 'Nova', totalStars: 42, cleared: 18),
        LeaderboardEntry(uid: 'bot2', name: 'Kai', totalStars: 28, cleared: 12),
        LeaderboardEntry(uid: 'bot3', name: 'Mira', totalStars: 15, cleared: 7),
      ]);
    }
    existing.removeWhere((e) => e.uid == uid);
    existing.add(
      LeaderboardEntry(
          uid: uid, name: name, totalStars: stars, cleared: cleared),
    );
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      existing
          .map((e) => {
                'uid': e.uid,
                'name': e.name,
                'totalStars': e.totalStars,
                'cleared': e.cleared,
              })
          .toList(),
    );
    await prefs.setString(_localKey, encoded);
  }

  Future<List<LeaderboardEntry>> _localEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return LeaderboardEntry(
          uid: m['uid'] as String,
          name: m['name'] as String,
          totalStars: m['totalStars'] as int,
          cleared: m['cleared'] as int,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
