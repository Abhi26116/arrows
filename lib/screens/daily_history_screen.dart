import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../data/progress_store.dart';
import '../logic/daily_challenge.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';
import 'game_screen.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// '2026-08-28' -> 'Fri 28 Aug'. Falls back to the raw key if it ever changes.
String _prettyDate(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return isoDate;
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

bool _isToday(String isoDate) {
  final d = DateTime.tryParse(isoDate);
  if (d == null) return false;
  final now = DateTime.now();
  return d.year == now.year && d.month == now.month && d.day == now.day;
}

class DailyHistoryScreen extends StatelessWidget {
  const DailyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Streak and history change as soon as today's board is cleared.
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final history = AppStore.instance.dailyHistory;
    final streak = AppStore.instance.dailyStreak;
    final today = AppStore.instance.dailyBestStars;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Daily'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceHigh),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Streak',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                            Text(
                              '$streak day${streak == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontVariations: [FontVariation('wght', 700)],
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  today == null
                                      ? 'Today is still open'
                                      : 'Today cleared · $today',
                                  style: TextStyle(
                                    color: today == null
                                        ? AppColors.muted
                                        : AppColors.accentSoft,
                                    fontSize: 11,
                                  ),
                                ),
                                if (today != null)
                                  Icon(Icons.star_rounded,
                                      size: 12, color: AppColors.accentSoft),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          SoundService.instance.play(Sfx.tap);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameScreen(
                                customLevel: DailyChallenge.levelForToday(),
                                isDaily: true,
                              ),
                            ),
                          );
                        },
                        child: Text(today == null ? 'Play today' : 'Replay'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          'No dailies cleared yet.\nPlay today’s challenge!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted, height: 1.4),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final r = history[i];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.surfaceHigh),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        _prettyDate(r.date),
                                        style: const TextStyle(
                                          fontFamily: 'DMSans',
                                          fontVariations: [
                                            FontVariation('wght', 700)
                                          ],
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (_isToday(r.date)) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withOpacity(0.16),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'Today',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.accentSoft,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(3, (s) {
                                    return Icon(
                                      s < r.stars
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 18,
                                      color: s < r.stars
                                          ? AppColors.accent
                                          : AppColors.muted,
                                    );
                                  }),
                                ),
                              ],
                            ),
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
