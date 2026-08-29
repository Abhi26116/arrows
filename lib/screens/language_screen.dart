import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../audio/sfx.dart';
import '../data/progress_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';

/// The languages the app is translated into.
///
/// Each is written in its own language, not in English. Someone who has landed
/// in a language they cannot read needs to recognise their own on sight, and
/// "Hindi" is no help to a reader who is looking for हिन्दी.
const languages = <({String? code, String name})>[
  (code: null, name: ''), // system default — labelled from the current locale
  (code: 'en', name: 'English'),
  (code: 'hi', name: 'हिन्दी'),
  (code: 'es', name: 'Español'),
  (code: 'pt', name: 'Português'),
  (code: 'id', name: 'Bahasa Indonesia'),
];

/// Language picker, used both as a Settings page and as the first thing an
/// onboarding player sees.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, this.onboarding = false});

  /// In onboarding there is nothing to go back to, and choosing moves the
  /// player forward rather than returning them to Settings.
  final bool onboarding;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppStore.instance;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: onboarding ? l.languageOnboardingTitle : l.languageTitle,
                showBack: !onboarding,
              ),
              if (onboarding)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Text(
                    l.languageOnboardingBody,
                    style: TextStyle(color: AppColors.muted, height: 1.4),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    for (final lang in languages)
                      _LanguageTile(
                        label: lang.code == null ? l.languageSystem : lang.name,
                        selected: store.localeCode == lang.code,
                        onTap: () async {
                          SoundService.instance.play(Sfx.tap);
                          await store.setLocaleCode(lang.code);
                          if (onboarding && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.surfaceHigh,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontVariations: const [FontVariation('wght', 600)],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
