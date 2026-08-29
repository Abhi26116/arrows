import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../config/app_config.dart';
import '../data/progress_store.dart';
import '../firebase/firebase_bootstrap.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';

/// Not reachable in 1.0 — nothing navigates here. The board it shows is local
/// to the device and seeded with invented players, which is not something to
/// put in front of a store reviewer or a real player. Kept whole so a genuine
/// online board can be wired up for a later release; see [LeaderboardService].
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _future;
  final _nameCtrl = TextEditingController(text: AppStore.instance.displayName);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _future = () async {
      await LeaderboardService.instance.submitScore();
      return LeaderboardService.instance.top();
    }();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _nameCtrl.text = AppStore.instance.displayName;
      return;
    }
    FocusScope.of(context).unfocus();
    await AppStore.instance.setDisplayName(name);
    await LeaderboardService.instance.submitScore();
    SoundService.instance.play(Sfx.tap);
    if (mounted) setState(_refresh);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = FirebaseBootstrap.ready;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(
                title: 'Leaderboard',
                trailing: CircleIconButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: () {
                    SoundService.instance.play(Sfx.tap);
                    setState(_refresh);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceHigh),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        online
                            ? 'Ranked against players worldwide'
                            : 'Scores are kept on this device',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              style: TextStyle(color: AppColors.ink),
                              maxLength: 16,
                              textInputAction: TextInputAction.done,
                              textCapitalization: TextCapitalization.words,
                              onSubmitted: (_) => _saveName(),
                              decoration: InputDecoration(
                                isDense: true,
                                counterText: '',
                                hintText: 'Display name',
                                hintStyle: TextStyle(color: AppColors.muted),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _saveName,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                      if (kDebugMode && !AppConfig.firebaseEnabled) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Debug: set AppConfig.firebaseEnabled = true after '
                          'flutterfire configure to go online.',
                          style:
                              TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<LeaderboardEntry>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          'Could not load leaderboard',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      );
                    }
                    final rows = snap.data ?? [];
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final e = rows[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: e.isYou
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: e.isYou
                                  ? AppColors.accent
                                  : AppColors.surfaceHigh,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontVariations: const [
                                      FontVariation('wght', 700)
                                    ],
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  e.isYou ? '${e.name} (you)' : e.name,
                                  style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    fontVariations: [
                                      FontVariation('wght', 700)
                                    ],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(Icons.star_rounded,
                                  size: 15, color: AppColors.accentSoft),
                              const SizedBox(width: 3),
                              Text(
                                '${e.totalStars}',
                                style: TextStyle(color: AppColors.accentSoft),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${e.cleared}',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
