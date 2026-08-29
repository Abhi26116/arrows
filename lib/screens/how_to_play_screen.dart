import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../data/progress_store.dart';
import '../models/direction.dart';
import '../theme/app_theme.dart';
import '../widgets/app_chrome.dart';
import '../widgets/arrow_glyph.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: AtmosphereBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: l.howToTitle,
                showBack: !fromOnboarding,
              ),
              // The steps and the button are one block, held to the top. On a
              // phone the block is taller than the screen, so the list scrolls
              // and the button sits at the bottom exactly as before; on a
              // tablet the block is shorter, and the button follows the last
              // step rather than stranding itself at the bottom edge. Any
              // room left over falls below the button, so the steps start
              // directly under the header on every device.
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          children: [
                            _Step(
                              number: '1',
                              title: l.howToStep1Title,
                              body: l.howToStep1Body,
                              trailing: ArrowGlyph(
                                direction: Direction.right,
                                color: AppColors.arrowLine,
                                size: 36,
                                glow: true,
                              ),
                            ),
                            _Step(
                              number: '2',
                              title: l.howToStep2Title,
                              body: l.howToStep2Body,
                            ),
                            _Step(
                              number: '3',
                              title: l.howToStep3Title,
                              body: l.howToStep3Body,
                            ),
                            _Step(
                              number: '4',
                              title: l.howToStep4Title,
                              body: l.howToStep4Body,
                            ),
                            _Step(
                              number: '5',
                              title: l.howToStep5Title,
                              body: l.howToStep5Body,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await AppStore.instance.setSeenHowTo(true);
                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: Text(
                                fromOnboarding ? l.howToGotIt : l.howToDone),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.trailing,
  });

  final String number;
  final String title;
  final String body;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceHigh),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                number,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontVariations: const [FontVariation('wght', 700)],
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentSoft,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontVariations: [FontVariation('wght', 700)],
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      color: AppColors.muted,
                      height: 1.4,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
