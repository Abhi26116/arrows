import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sfx.dart';
import 'data/progress_store.dart';
import 'firebase/firebase_bootstrap.dart';
import 'screens/splash_screen.dart';
import 'services/iap_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await AppStore.instance.init();
  await ThemeController.instance.load();
  await SoundService.instance.init();
  await FirebaseBootstrap.init();
  await IapService.instance.init();

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

class ArrowsApp extends StatelessWidget {
  const ArrowsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Arrows',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: const SplashScreen(),
        );
      },
    );
  }
}
