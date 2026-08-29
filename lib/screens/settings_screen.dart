import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/progress_store.dart';
import '../services/consent_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';
import 'language_screen.dart';
import 'shop_screen.dart';
import 'themes_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _consentFormAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkConsentForm();
  }

  Future<void> _checkConsentForm() async {
    final available = await ConsentService.instance.formAvailable;
    if (mounted) setState(() => _consentFormAvailable = available);
  }

  /// The active language, named in itself. Falls back to the system entry when
  /// nothing has been chosen.
  String _currentLanguageName(BuildContext context) {
    final code = AppStore.instance.localeCode;
    if (code == null) return AppLocalizations.of(context).languageSystem;
    for (final lang in languages) {
      if (lang.code == code) return lang.name;
    }
    return code;
  }

  Future<void> _confirmReset() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.settingsResetTitle,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontVariations: const [FontVariation('wght', 700)],
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          l.settingsResetBody,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.settingsCancel,
                style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.settingsResetConfirm,
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppStore.instance.resetProgress();
    if (!mounted) return;
    SoundService.instance.hapticMedium();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.settingsResetDone)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.instance,
      builder: (context, _) => _buildSettings(context),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final l = AppLocalizations.of(context);
    final store = AppStore.instance;
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeader(title: l.settingsTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    _StatCard(
                      cleared: store.clearedCount,
                      stars: store.totalStars,
                      unlocked: store.maxUnlocked,
                    ),
                    const SizedBox(height: 18),
                    SectionLabel(l.navHowTo),
                    _ToggleTile(
                      icon: Icons.grid_on_rounded,
                      title: l.settingsGrid,
                      subtitle: l.settingsGridSub,
                      value: store.showGrid,
                      onChanged: (v) async {
                        await store.setShowGrid(v);
                        SoundService.instance.hapticSelection();
                      },
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.volume_up_rounded,
                      title: l.settingsSound,
                      subtitle: l.settingsSoundSub,
                      value: store.soundEnabled,
                      onChanged: (v) async {
                        await store.setSoundEnabled(v);
                        if (v) SoundService.instance.play(Sfx.tap);
                      },
                    ),
                    const SizedBox(height: 10),
                    _ToggleTile(
                      icon: Icons.vibration_rounded,
                      title: l.settingsHaptics,
                      subtitle: l.settingsHapticsSub,
                      value: store.hapticsEnabled,
                      onChanged: (v) async {
                        await store.setHapticsEnabled(v);
                        if (v) SoundService.instance.hapticMedium();
                      },
                    ),
                    const SizedBox(height: 22),
                    SectionLabel(l.settingsAbout),
                    _LinkTile(
                      icon: Icons.shopping_bag_outlined,
                      title: l.settingsShop,
                      subtitle: l.settingsShopSub,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ShopScreen()),
                      ).then((_) {
                        if (mounted) setState(() {});
                      }),
                    ),
                    const SizedBox(height: 10),
                    _LinkTile(
                      icon: Icons.palette_outlined,
                      title: l.settingsThemes,
                      subtitle: l.settingsThemesSub,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ThemesScreen()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _LinkTile(
                      icon: Icons.translate_rounded,
                      title: AppLocalizations.of(context).settingsLanguage,
                      // The language currently in use, written in itself, so
                      // it is recognisable to someone who has ended up in a
                      // language they cannot read.
                      subtitle: _currentLanguageName(context),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LanguageScreen()),
                      ),
                    ),
                    if (_consentFormAvailable) ...[
                      const SizedBox(height: 10),
                      _LinkTile(
                        icon: Icons.privacy_tip_outlined,
                        title: l.settingsPrivacy,
                        subtitle: l.settingsPrivacySub,
                        onTap: () => ConsentService.instance.showForm(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _LinkTile(
                      icon: Icons.restart_alt_rounded,
                      title: l.settingsReset,
                      subtitle: l.settingsResetSub,
                      danger: true,
                      onTap: _confirmReset,
                    ),
                    const SizedBox(height: 24),
                    const SectionLabel('About'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceHigh),
                      ),
                      child: Text(
                        'ARROWS is a path-order puzzle. An arrow leaves the '
                        'board only when nothing stands in its way — and it '
                        'blocks along its whole body, not just its head. '
                        'A blocked tap costs a heart, so read the board '
                        'before you commit.',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          color: AppColors.ink.withOpacity(0.9),
                          height: 1.45,
                        ),
                      ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.cleared,
    required this.stars,
    required this.unlocked,
  });

  final int cleared;
  final int stars;
  final int unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: Row(
        children: [
          _Stat(
              label: AppLocalizations.of(context).settingsStatCleared,
              value: '$cleared'),
          _Stat(
              label: AppLocalizations.of(context).settingsStatStars,
              value: '$stars'),
          _Stat(
              label: AppLocalizations.of(context).settingsStatReached,
              value: '$unlocked'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontVariations: const [FontVariation('wght', 700)],
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.accentSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: AppColors.ink),
        title: Text(
          title,
          style: const TextStyle(
              fontFamily: 'DMSans',
              fontVariations: [FontVariation('wght', 700)],
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
        subtitle: Text(subtitle,
            style: TextStyle(color: AppColors.muted, fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceHigh),
          ),
          child: Row(
            children: [
              Icon(icon, color: danger ? AppColors.danger : AppColors.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: danger ? AppColors.danger : AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
