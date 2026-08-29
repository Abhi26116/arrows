import 'package:flutter/material.dart';

import '../audio/sfx.dart';
import '../data/progress_store.dart';
import '../models/direction.dart';
import '../theme/game_themes.dart';
import '../theme/theme_controller.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';
import 'shop_screen.dart';

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  @override
  Widget build(BuildContext context) {
    final owned = AppStore.instance.themePackOwned;
    final active = ThemeController.instance.theme.id;

    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(title: 'Themes'),
              if (!owned)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        SoundService.instance.play(Sfx.tap);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ShopScreen()),
                        );
                        if (mounted) setState(() {});
                      },
                      child: const Text('Unlock Theme Pack in Shop'),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: GameThemes.all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final theme = GameThemes.all[i];
                    final locked = theme.premium && !owned;
                    final selected = theme.id == active;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: locked
                          ? () async {
                              SoundService.instance.play(Sfx.tap);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ShopScreen(),
                                ),
                              );
                              if (mounted) setState(() {});
                            }
                          : () async {
                              SoundService.instance.play(Sfx.tap);
                              await ThemeController.instance.setTheme(theme.id);
                              if (mounted) setState(() {});
                            },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            colors: [theme.bgTop, theme.bgBottom],
                          ),
                          border: Border.all(
                            color: selected ? theme.accent : theme.surfaceHigh,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    theme.name,
                                    style: TextStyle(
                                      fontFamily: 'DMSans',
                                      fontVariations: const [
                                        FontVariation('wght', 700)
                                      ],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                      color: theme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    locked
                                        ? 'Premium · Theme Pack'
                                        : selected
                                            ? 'Active'
                                            : theme.premium
                                                ? 'Premium'
                                                : 'Free',
                                    style: TextStyle(
                                      color: theme.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Preview shows what the board actually looks
                            // like in this theme, not the old dot palette.
                            Container(
                              width: 66,
                              height: 46,
                              decoration: BoxDecoration(
                                color: theme.bgTop,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: theme.surfaceHigh),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ArrowGlyph(
                                    direction: Direction.right,
                                    color: theme.arrowLine,
                                    size: 24,
                                  ),
                                  ArrowGlyph(
                                    direction: Direction.left,
                                    color: theme.arrowLine.withOpacity(0.7),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              locked
                                  ? Icons.lock_rounded
                                  : selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                              color: theme.accentSoft,
                            ),
                          ],
                        ),
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
