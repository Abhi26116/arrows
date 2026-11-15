// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTagline => 'Esvazie o tabuleiro. A ordem é tudo.';

  @override
  String get statStars => 'estrelas';

  @override
  String get statStreak => 'sequência';

  @override
  String get statCleared => 'concluídos';

  @override
  String actionContinue(int level) {
    return 'Continuar · $level';
  }

  @override
  String get actionStart => 'Começar a jogar';

  @override
  String get navDaily => 'Diário';

  @override
  String navDailyBest(String stars) {
    return 'Diário · $stars';
  }

  @override
  String get navLevels => 'Níveis';

  @override
  String get navThemes => 'Temas';

  @override
  String get navStreak => 'Sequência';

  @override
  String get navHowTo => 'Como jogar';

  @override
  String get tooltipShop => 'Loja';

  @override
  String get tooltipSettings => 'Ajustes';

  @override
  String get tooltipBack => 'Voltar';

  @override
  String get levelsTitle => 'Níveis';

  @override
  String levelsStarsOf(int earned, int total) {
    return '$earned de $total';
  }

  @override
  String get gameTooltipUndo => 'Desfazer';

  @override
  String get gameTooltipHint => 'Dica';

  @override
  String get gameTooltipRestart => 'Reiniciar tabuleiro';

  @override
  String get gameTooltipShowGrid => 'Mostrar grade';

  @override
  String get gameTooltipHideGrid => 'Ocultar grade';

  @override
  String gameLevelNumber(int id) {
    return 'NÍVEL $id';
  }

  @override
  String get gameToday => 'HOJE';

  @override
  String get gameCleared => 'CONCLUÍDO';

  @override
  String get gameDailyClear => 'DIÁRIO CONCLUÍDO';

  @override
  String gameLevelLabel(int id) {
    return 'Nível $id';
  }

  @override
  String gameMissHint(int miss, int hint) {
    return '$miss erros · $hint dicas';
  }

  @override
  String get gameReplay => 'Jogar de novo';

  @override
  String get gameNext => 'Próximo';

  @override
  String get gameDone => 'Pronto';

  @override
  String get gameOutOfHearts => 'SEM CORAÇÕES';

  @override
  String gameArrowsCleared(int cleared, int total) {
    return '$cleared de $total setas limpas';
  }

  @override
  String get gameOverTitle => 'Sem corações';

  @override
  String get gameOverBody =>
      'O tabuleiro reinicia. Assista a um anúncio curto para ganhar mais um coração, ou comece de novo.';

  @override
  String get gameExtraHeart => 'Mais um coração';

  @override
  String get gameRetry => 'Tentar de novo';

  @override
  String get gameQuit => 'Sair';

  @override
  String get gameRestartTitle => 'Reiniciar o tabuleiro?';

  @override
  String get gameRestartBody =>
      'Todas as setas voltam e seus corações são reiniciados.';

  @override
  String get gameRestart => 'Reiniciar';

  @override
  String get gameCancel => 'Cancelar';

  @override
  String get gameLeaveTitle => 'Sair deste tabuleiro?';

  @override
  String get gameLeaveBody => 'Da próxima vez ele começa do início.';

  @override
  String get gameKeepPlaying => 'Continuar jogando';

  @override
  String get gameLeave => 'Sair';

  @override
  String get gameNoAdReady => 'Nenhum anúncio pronto — tente de novo.';

  @override
  String get howToTitle => 'Como jogar';

  @override
  String get howToStep1Title => 'Toque numa seta';

  @override
  String get howToStep1Body =>
      'Ela voa na direção para onde aponta: cima, baixo, esquerda ou direita.';

  @override
  String get howToStep2Title => 'Caminho livre = sai';

  @override
  String get howToStep2Body =>
      'Se nada estiver no caminho reto da ponta até a borda, a seta inteira desliza para fora — com curvas e tudo.';

  @override
  String get howToStep3Title => 'O corpo pode dobrar';

  @override
  String get howToStep3Body =>
      'Uma seta bloqueia todas as casas que ocupa, da ponta à cauda, e alguns corpos viram esquinas. Siga a forma inteira antes de tocar.';

  @override
  String get howToStep4Title => 'Três corações';

  @override
  String get howToStep4Body =>
      'Um toque bloqueado custa um coração. Perdeu os três, o tabuleiro reinicia — e os corações que sobrarem viram suas estrelas.';

  @override
  String get howToStep5Title => 'Limpe tudo';

  @override
  String get howToStep5Body =>
      'Esvazie o tabuleiro para vencer. Toque no botão de grade para ver as casas, ou em Dica quando travar.';

  @override
  String get howToDone => 'Pronto';

  @override
  String get howToGotIt => 'Entendi — Jogar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSound => 'Som';

  @override
  String get settingsSoundSub => 'Avisos ao limpar, bloquear e vencer';

  @override
  String get settingsHaptics => 'Vibração';

  @override
  String get settingsHapticsSub => 'Resposta ao tocar e ao bloquear';

  @override
  String get settingsGrid => 'Grade';

  @override
  String get settingsGridSub => 'Mostrar a grade atrás das setas';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsShop => 'Loja';

  @override
  String get settingsShopSub =>
      'Remover anúncios, pacote de temas, dicas extras';

  @override
  String get settingsThemes => 'Temas';

  @override
  String get settingsThemesSub => 'Seis paletas para o tabuleiro';

  @override
  String get settingsPrivacy => 'Opções de privacidade';

  @override
  String get settingsPrivacySub => 'Altere suas preferências de anúncios';

  @override
  String get settingsReset => 'Zerar progresso';

  @override
  String get settingsResetSub => 'Recomeçar do primeiro tabuleiro';

  @override
  String get settingsResetTitle => 'Zerar o progresso?';

  @override
  String get settingsResetBody =>
      'Os níveis travam de novo e as estrelas voltam a zero. Compras, temas e sua sequência diária são mantidos.';

  @override
  String get settingsResetConfirm => 'Zerar';

  @override
  String get settingsResetDone => 'Progresso zerado';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get settingsStatStars => 'Estrelas';

  @override
  String get settingsStatCleared => 'Concluídos';

  @override
  String get settingsStatReached => 'Alcançado';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get themesTitle => 'Temas';

  @override
  String get themesUnlockInShop => 'Desbloqueie o pacote de temas na Loja';

  @override
  String themesTrialTitle(String name) {
    return 'Experimente $name por um dia';
  }

  @override
  String get themesTrialBody =>
      'Assista a um anúncio curto e jogue com este tema nas próximas 24 horas.';

  @override
  String get themesTrialWatch => 'Ver um anúncio';

  @override
  String themesUnlockAll(String price) {
    return 'Desbloquear todos os temas · $price';
  }

  @override
  String get themesLocked => 'Premium · Pacote de temas';

  @override
  String themesTrialLeft(int hours) {
    return 'Teste · faltam $hours h';
  }

  @override
  String get themesActive => 'Ativo';

  @override
  String get themesPremium => 'Premium';

  @override
  String get themesFree => 'Grátis';

  @override
  String get themesPremiumPack => 'Premium · Pacote de temas';

  @override
  String get shopTitle => 'Loja';

  @override
  String get shopRemoveAds => 'Remover anúncios';

  @override
  String shopRemoveAdsBody(int hints) {
    return 'Sem banners nem anúncios pop-up. Vem com $hints dicas extras.';
  }

  @override
  String get shopThemePack => 'Pacote de temas';

  @override
  String get shopThemePackBody =>
      'Desbloqueie os temas Aurora, Noir e Solar para sempre.';

  @override
  String get shopBonusHint => 'Dica extra';

  @override
  String shopBonusHintWatch(int ready) {
    return 'Assista a um anúncio curto para uma dica extra ($ready prontas).';
  }

  @override
  String get shopWatchAnAd => 'Ver um anúncio';

  @override
  String get shopNonConsumable => 'Compra única';

  @override
  String get shopOwned => 'Adquirido';

  @override
  String get shopBuy => 'Comprar';

  @override
  String get shopWatch => 'Ver';

  @override
  String get shopRestore => 'Restaurar compras';

  @override
  String get shopRestoreNote =>
      'As compras ficam ligadas à sua conta da loja e podem ser restauradas em qualquer aparelho onde você entrar.';

  @override
  String get shopHintAdded => 'Dica extra adicionada';

  @override
  String get shopAdNotReady => 'Anúncio não está pronto — tente daqui a pouco.';

  @override
  String get shopBundle => 'Pacote completo';

  @override
  String shopBundleBody(int hints) {
    return 'Sem banners nem anúncios pop-up, todos os temas e $hints dicas extras.';
  }

  @override
  String get shopBestValue => 'Melhor custo';

  @override
  String shopHintsHeader(int count) {
    return 'Dicas · $count prontas';
  }

  @override
  String shopHintPack(int count) {
    return '$count dicas';
  }

  @override
  String get shopHintPackBody =>
      'Para quando um tabuleiro te travar. Use quando quiser.';

  @override
  String get shopConsumable => 'Pacote de dicas';

  @override
  String get hintOutTitle => 'Sem dicas';

  @override
  String get hintOutBody =>
      'A primeira dica de cada tabuleiro é grátis. Pegue mais para continuar.';

  @override
  String get hintOutWatch => 'Ver um anúncio · +1 dica';

  @override
  String hintOutBuy(int count, String price) {
    return '$count dicas · $price';
  }

  @override
  String get hintOutLater => 'Agora não';

  @override
  String get dailyTitle => 'Diário';

  @override
  String dailyStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'sequência de $days dias',
      one: 'sequência de 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get dailyEmpty => 'Jogue o tabuleiro de hoje e ele aparece aqui.';

  @override
  String get dailyPlayToday => 'Jogar hoje';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSystem => 'Idioma do sistema';

  @override
  String get updateTitle => 'Atualização disponível';

  @override
  String updateBody(String version) {
    return 'A versão $version saiu. Atualize para os tabuleiros e correções mais recentes.';
  }

  @override
  String get updateNow => 'Atualizar';

  @override
  String get updateLater => 'Depois';
}
