import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';

enum Sfx { clear, blocked, win, tap, hint }

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setPlayerMode(PlayerMode.lowLatency);
    _ready = true;
  }

  Future<void> play(Sfx sfx) async {
    final store = AppStore.instance;
    if (!store.soundEnabled) return;
    await init();
    final file = switch (sfx) {
      Sfx.clear => 'sounds/clear.wav',
      Sfx.blocked => 'sounds/blocked.wav',
      Sfx.win => 'sounds/win.wav',
      Sfx.tap => 'sounds/tap.wav',
      Sfx.hint => 'sounds/hint.wav',
    };
    try {
      await _player.stop();
      await _player.play(AssetSource(file));
    } catch (_) {
      // Ignore audio failures (missing asset / platform quirks).
    }
  }

  Future<void> hapticLight() async {
    if (!AppStore.instance.hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> hapticMedium() async {
    if (!AppStore.instance.hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> hapticHeavy() async {
    if (!AppStore.instance.hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> hapticSelection() async {
    if (!AppStore.instance.hapticsEnabled) return;
    await HapticFeedback.selectionClick();
  }
}
