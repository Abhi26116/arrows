import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Circular icon button used for every chrome control in the app — screen
/// headers, board controls, floating actions.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.accent = false,
    this.active = false,
    this.flipped = false,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool accent;
  final bool active;
  final bool flipped;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final highlight = accent || active;
    final fg = accent
        ? AppColors.accentSoft
        : (active ? AppColors.accent : AppColors.ink);

    Widget glyph = Icon(
      icon,
      size: size * 0.44,
      color: enabled ? fg : fg.withOpacity(0.3),
    );
    if (flipped) {
      glyph = Transform.flip(flipX: true, child: glyph);
    }

    Widget button = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: highlight
            ? AppColors.accent.withOpacity(0.14)
            : AppColors.surfaceHigh.withOpacity(0.5),
        shape: CircleBorder(
          side: BorderSide(
            color: highlight
                ? AppColors.accent.withOpacity(0.35)
                : AppColors.ink.withOpacity(0.07),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: glyph),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return Semantics(button: true, label: tooltip, child: button);
  }
}

/// Standard header for every screen below Home: circular back button, title,
/// optional trailing control.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          if (showBack) ...[
            CircleIconButton(
              icon: Icons.play_arrow_rounded,
              flipped: true,
              tooltip: 'Back',
              onTap: onBack ?? () => Navigator.pop(context),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Long titles scale down rather than wrapping under the
                // back button.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontVariations: const [FontVariation('wght', 700)],
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Caps how wide a screen's content may grow and centres what is left.
///
/// Every layout here was drawn for a phone. Left alone on an iPad they stretch
/// to the full 1024pt or more: buttons run the whole width of the screen, text
/// lines get uncomfortably long, and the header controls end up in opposite
/// corners. Phones are narrower than [maxWidth], so nothing about them changes.
///
/// [wide] is for the board, which is square and reads better with more room
/// than a column of text or buttons would.
class ContentBounds extends StatelessWidget {
  const ContentBounds({super.key, required this.child, this.wide = false});

  final Widget child;
  final bool wide;

  /// Roughly a large phone. Wide enough that nothing feels cramped, narrow
  /// enough that a row of buttons still reads as a group.
  static const double narrowMax = 560;

  /// The board can take more, but not so much that a cell becomes a tile the
  /// size of a fist.
  static const double wideMax = 760;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? wideMax : narrowMax),
        child: child,
      ),
    );
  }
}

/// Section label used between groups of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'DMSans',
          fontVariations: const [FontVariation('wght', 700)],
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.muted,
        ),
      ),
    );
  }
}
