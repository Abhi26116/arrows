import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'audio/sfx.dart';
import 'data/progress_store.dart';
import 'firebase/firebase_bootstrap.dart';
import 'screens/splash_screen.dart';
import 'services/iap_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones stay upright — the layouts are columns and there is nothing to gain
  // from landscape on a 6" screen. A tablet is held whichever way its case
  // stands, so refusing to rotate there just reads as a phone app that was
  // dropped onto an iPad.
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final logicalSize = view.physicalSize / view.devicePixelRatio;
  final isTablet = logicalSize.shortestSide >= 600;
  await SystemChrome.setPreferredOrientations(
    isTablet
        ? DeviceOrientation.values
        : const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await AppStore.instance.init();
  await ThemeController.instance.load();
  await SoundService.instance.init();
  await FirebaseBootstrap.init();
  // Deliberately not awaited. init() asks StoreKit whether purchases are
  // available, queries the products and restores past purchases — three
  // network round trips. Awaiting them here holds back runApp, so a slow or
  // unreachable store leaves the launch screen up with nothing behind it, and
  // iOS terminates an app that takes too long to draw its first frame. The
  // Shop reads the products when it opens and shows placeholders until they
  // land; nothing else needs them at startup.
  unawaited(IapService.instance.init());

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgBottom,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ArrowsApp());
}

/// Lays the app out at phone proportions and then enlarges the whole thing on
/// a tablet.
///
/// Capping the content width was only half the job: it stopped the layouts
/// stretching, but left an iPad showing phone-sized type inside a narrow
/// column. Scaling text alone would not have helped either — the padding,
/// icons, badges and corner radii around it would still be phone-sized, and
/// the cards would look starved.
///
/// Laying out against a smaller logical screen and scaling the result grows
/// every one of those together, in one place, without a size constant in
/// thirty files needing a tablet variant.
class TabletScale extends StatelessWidget {
  const TabletScale({super.key, required this.child});

  final Widget child;

  /// 1.0 on phones. On a tablet it grows with the shorter edge, capped so a
  /// 12.9" iPad gets a comfortably larger interface rather than a magnified
  /// one.
  static double scaleFor(Size size) {
    final shortest = size.shortestSide;
    if (shortest < 600) return 1;
    return (shortest / 620).clamp(1.0, 1.4);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = scaleFor(media.size);
    if (scale == 1) return child;

    // The insets have to shrink with the screen: they are measured in real
    // pixels, and everything below is about to be multiplied back up.
    final size = media.size / scale;
    return MediaQuery(
      data: media.copyWith(
        size: size,
        padding: media.padding / scale,
        viewPadding: media.viewPadding / scale,
        viewInsets: media.viewInsets / scale,
      ),
      // The Transform takes the size of its (smaller) child, so without the
      // Align it is centred in the screen first and then scaled out of it from
      // the corner. Pin it to the top left and the scaled result lands exactly
      // on the screen.
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}

class ArrowsApp extends StatelessWidget {
  const ArrowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // The store carries the language choice as well as progress, so both it
      // and the theme have to be able to rebuild the app.
      listenable: Listenable.merge([
        ThemeController.instance,
        AppStore.instance,
      ]),
      builder: (context, _) {
        final code = AppStore.instance.localeCode;
        return MaterialApp(
          title: 'Arrows',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // null means follow the phone, which is what Flutter does by default.
          locale: code == null ? null : Locale(code),
          builder: (context, child) => TabletScale(child: child!),
          home: const SplashScreen(),
        );
      },
    );
  }
}
