/// Firebase is currently disabled (packages removed — see pubspec.yaml / EXTRAS.md).
/// This stub keeps the rest of the app compiling; the leaderboard runs locally.
/// When you re-add the firebase_* packages, restore the real initializer.
class FirebaseBootstrap {
  static bool ready = false;

  static Future<bool> init() async {
    ready = false;
    return false;
  }
}
