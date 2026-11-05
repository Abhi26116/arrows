// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTagline => 'Vacía el tablero. El orden lo es todo.';

  @override
  String get statStars => 'estrellas';

  @override
  String get statStreak => 'racha';

  @override
  String get statCleared => 'completados';

  @override
  String actionContinue(int level) {
    return 'Continuar · $level';
  }

  @override
  String get actionStart => 'Empezar a jugar';

  @override
  String get navDaily => 'Diario';

  @override
  String navDailyBest(String stars) {
    return 'Diario · $stars';
  }

  @override
  String get navLevels => 'Niveles';

  @override
  String get navThemes => 'Temas';

  @override
  String get navStreak => 'Racha';

  @override
  String get navHowTo => 'Cómo jugar';

  @override
  String get tooltipShop => 'Tienda';

  @override
  String get tooltipSettings => 'Ajustes';

  @override
  String get tooltipBack => 'Atrás';

  @override
  String get levelsTitle => 'Niveles';

  @override
  String levelsStarsOf(int earned, int total) {
    return '$earned de $total';
  }

  @override
  String get gameTooltipUndo => 'Deshacer';

  @override
  String get gameTooltipHint => 'Pista';

  @override
  String get gameTooltipRestart => 'Reiniciar tablero';

  @override
  String get gameTooltipShowGrid => 'Mostrar cuadrícula';

  @override
  String get gameTooltipHideGrid => 'Ocultar cuadrícula';

  @override
  String gameLevelNumber(int id) {
    return 'NIVEL $id';
  }

  @override
  String get gameToday => 'HOY';

  @override
  String get gameCleared => 'COMPLETADO';

  @override
  String get gameDailyClear => 'DIARIO COMPLETADO';

  @override
  String gameLevelLabel(int id) {
    return 'Nivel $id';
  }

  @override
  String gameMissHint(int miss, int hint) {
    return '$miss fallos · $hint pistas';
  }

  @override
  String get gameReplay => 'Repetir';

  @override
  String get gameNext => 'Siguiente';

  @override
  String get gameDone => 'Listo';

  @override
  String get gameOutOfHearts => 'SIN CORAZONES';

  @override
  String gameArrowsCleared(int cleared, int total) {
    return '$cleared de $total flechas despejadas';
  }

  @override
  String get gameOverTitle => 'Sin corazones';

  @override
  String get gameOverBody =>
      'El tablero se reinicia. Mira un anuncio corto para conseguir otro corazón, o vuelve a empezar.';

  @override
  String get gameExtraHeart => 'Otro corazón';

  @override
  String get gameRetry => 'Reintentar';

  @override
  String get gameQuit => 'Salir';

  @override
  String get gameRestartTitle => '¿Reiniciar el tablero?';

  @override
  String get gameRestartBody =>
      'Todas las flechas vuelven y tus corazones se reinician.';

  @override
  String get gameRestart => 'Reiniciar';

  @override
  String get gameCancel => 'Cancelar';

  @override
  String get gameLeaveTitle => '¿Salir de este tablero?';

  @override
  String get gameLeaveBody => 'La próxima vez empezará desde el principio.';

  @override
  String get gameKeepPlaying => 'Seguir jugando';

  @override
  String get gameLeave => 'Salir';

  @override
  String get gameNoAdReady => 'No hay anuncio disponible — inténtalo de nuevo.';

  @override
  String get gameHintAdHint =>
      'Mira un anuncio corto en la Tienda para conseguir pistas, o inténtalo de nuevo.';

  @override
  String get howToTitle => 'Cómo jugar';

  @override
  String get howToStep1Title => 'Toca una flecha';

  @override
  String get howToStep1Body =>
      'Sale volando en la dirección a la que apunta: arriba, abajo, izquierda o derecha.';

  @override
  String get howToStep2Title => 'Camino libre = fuera';

  @override
  String get howToStep2Body =>
      'Si nada le corta el camino recto desde la punta hasta el borde, la flecha entera se desliza fuera, con curvas y todo.';

  @override
  String get howToStep3Title => 'Los cuerpos pueden doblar';

  @override
  String get howToStep3Body =>
      'Una flecha bloquea todas las casillas que ocupa, de la punta a la cola, y algunos cuerpos giran en esquina. Mira la forma entera antes de tocar.';

  @override
  String get howToStep4Title => 'Tres corazones';

  @override
  String get howToStep4Body =>
      'Un toque bloqueado cuesta un corazón. Si pierdes los tres, el tablero se reinicia — y los corazones que te queden son tus estrellas.';

  @override
  String get howToStep5Title => 'Vacía el tablero';

  @override
  String get howToStep5Body =>
      'Gana dejando el tablero vacío. Toca el botón de cuadrícula para ver las casillas, o Pista si te atascas.';

  @override
  String get howToDone => 'Listo';

  @override
  String get howToGotIt => 'Entendido — Jugar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSound => 'Sonido';

  @override
  String get settingsSoundSub => 'Avisos al despejar, bloquear y ganar';

  @override
  String get settingsHaptics => 'Vibración';

  @override
  String get settingsHapticsSub => 'Respuesta al tocar y al bloquear';

  @override
  String get settingsGrid => 'Cuadrícula';

  @override
  String get settingsGridSub => 'Mostrar la cuadrícula detrás de las flechas';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsShop => 'Tienda';

  @override
  String get settingsShopSub => 'Quitar anuncios, pack de temas, pistas extra';

  @override
  String get settingsThemes => 'Temas';

  @override
  String get settingsThemesSub => 'Seis paletas para el tablero';

  @override
  String get settingsPrivacy => 'Opciones de privacidad';

  @override
  String get settingsPrivacySub => 'Cambia tus preferencias de anuncios';

  @override
  String get settingsReset => 'Reiniciar progreso';

  @override
  String get settingsResetSub => 'Empezar de nuevo desde el primer tablero';

  @override
  String get settingsResetTitle => '¿Reiniciar el progreso?';

  @override
  String get settingsResetBody =>
      'Los niveles se bloquean otra vez y las estrellas vuelven a cero. Las compras, los temas y tu racha diaria se mantienen.';

  @override
  String get settingsResetConfirm => 'Reiniciar';

  @override
  String get settingsResetDone => 'Progreso reiniciado';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsStatStars => 'Estrellas';

  @override
  String get settingsStatCleared => 'Completados';

  @override
  String get settingsStatReached => 'Alcanzado';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get themesTitle => 'Temas';

  @override
  String get themesUnlockInShop => 'Desbloquea el pack de temas en la Tienda';

  @override
  String get themesFree => 'Gratis';

  @override
  String get themesActive => 'Activo';

  @override
  String get themesPremium => 'Premium';

  @override
  String get themesPremiumPack => 'Premium · Pack de temas';

  @override
  String get shopTitle => 'Tienda';

  @override
  String get shopRemoveAds => 'Quitar anuncios';

  @override
  String get shopRemoveAdsBody =>
      'Sin banners ni anuncios entre partidas. Las pistas con recompensa siguen siendo gratis.';

  @override
  String get shopThemePack => 'Pack de temas';

  @override
  String get shopThemePackBody =>
      'Desbloquea los temas Aurora, Noir y Solar para siempre.';

  @override
  String get shopBonusHint => 'Pista extra';

  @override
  String shopBonusHintWatch(int ready) {
    return 'Mira un anuncio corto para una pista extra ($ready disponibles).';
  }

  @override
  String shopBonusHintFree(int ready) {
    return 'Sin anuncios, así que las pistas son gratis ($ready disponibles).';
  }

  @override
  String get shopWatchAnAd => 'Ver un anuncio';

  @override
  String get shopFree => 'Gratis';

  @override
  String get shopNonConsumable => 'Compra única';

  @override
  String get shopOwned => 'Comprado';

  @override
  String get shopBuy => 'Comprar';

  @override
  String get shopWatch => 'Ver';

  @override
  String get shopClaim => 'Conseguir';

  @override
  String get shopRestore => 'Restaurar compras';

  @override
  String get shopRestoreNote =>
      'Las compras están ligadas a tu cuenta de la tienda y puedes restaurarlas en cualquier dispositivo donde inicies sesión.';

  @override
  String get shopHintAdded => 'Pista extra añadida';

  @override
  String get shopAdNotReady =>
      'Anuncio no disponible — inténtalo en un momento.';

  @override
  String get dailyTitle => 'Diario';

  @override
  String dailyStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'racha de $days días',
      one: 'racha de 1 día',
    );
    return '$_temp0';
  }

  @override
  String get dailyEmpty => 'Juega el tablero de hoy y aparecerá aquí.';

  @override
  String get dailyPlayToday => 'Jugar hoy';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Idioma del sistema';

  @override
  String get languageOnboardingTitle => 'Elige tu idioma';

  @override
  String get languageOnboardingBody =>
      'Puedes cambiarlo cuando quieras en Ajustes.';

  @override
  String get languageContinue => 'Continuar';

  @override
  String get reviewTitle => '¿Te gusta Arrows?';

  @override
  String get reviewBody =>
      'Una valoración ayuda a que otros encuentren el juego. Solo lleva un momento.';

  @override
  String get reviewRate => 'Valorar';

  @override
  String get reviewLater => 'Ahora no';

  @override
  String get updateTitle => 'Actualización disponible';

  @override
  String updateBody(String version) {
    return 'Ya está la versión $version. Actualiza para los últimos tableros y mejoras.';
  }

  @override
  String get updateNow => 'Actualizar';

  @override
  String get updateLater => 'Más tarde';
}
