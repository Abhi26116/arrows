// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTagline => 'Kosongkan papannya. Urutan menentukan segalanya.';

  @override
  String get statStars => 'bintang';

  @override
  String get statStreak => 'beruntun';

  @override
  String get statCleared => 'selesai';

  @override
  String actionContinue(int level) {
    return 'Lanjut · $level';
  }

  @override
  String get actionStart => 'Mulai main';

  @override
  String get navDaily => 'Harian';

  @override
  String navDailyBest(String stars) {
    return 'Harian · $stars';
  }

  @override
  String get navLevels => 'Level';

  @override
  String get navThemes => 'Tema';

  @override
  String get navStreak => 'Beruntun';

  @override
  String get navHowTo => 'Cara main';

  @override
  String get tooltipShop => 'Toko';

  @override
  String get tooltipSettings => 'Pengaturan';

  @override
  String get tooltipBack => 'Kembali';

  @override
  String get levelsTitle => 'Level';

  @override
  String levelsStarsOf(int earned, int total) {
    return '$earned dari $total';
  }

  @override
  String get gameTooltipUndo => 'Batalkan';

  @override
  String get gameTooltipHint => 'Petunjuk';

  @override
  String get gameTooltipRestart => 'Ulangi papan';

  @override
  String get gameTooltipShowGrid => 'Tampilkan kisi';

  @override
  String get gameTooltipHideGrid => 'Sembunyikan kisi';

  @override
  String gameLevelNumber(int id) {
    return 'LEVEL $id';
  }

  @override
  String get gameToday => 'HARI INI';

  @override
  String get gameCleared => 'SELESAI';

  @override
  String get gameDailyClear => 'HARIAN SELESAI';

  @override
  String gameLevelLabel(int id) {
    return 'Level $id';
  }

  @override
  String gameMissHint(int miss, int hint) {
    return '$miss salah · $hint petunjuk';
  }

  @override
  String get gameReplay => 'Ulangi';

  @override
  String get gameNext => 'Berikutnya';

  @override
  String get gameDone => 'Selesai';

  @override
  String get gameOutOfHearts => 'HATI HABIS';

  @override
  String gameArrowsCleared(int cleared, int total) {
    return '$cleared dari $total panah dibersihkan';
  }

  @override
  String get gameOverTitle => 'Hati habis';

  @override
  String get gameOverBody =>
      'Papan akan diulang. Tonton iklan singkat untuk satu hati lagi, atau mulai dari awal.';

  @override
  String get gameExtraHeart => 'Hati tambahan';

  @override
  String get gameRetry => 'Coba lagi';

  @override
  String get gameQuit => 'Keluar';

  @override
  String get gameRestartTitle => 'Ulangi papan ini?';

  @override
  String get gameRestartBody =>
      'Semua panah kembali dan hati kamu diatur ulang.';

  @override
  String get gameRestart => 'Ulangi';

  @override
  String get gameCancel => 'Batal';

  @override
  String get gameLeaveTitle => 'Keluar dari papan ini?';

  @override
  String get gameLeaveBody => 'Lain kali papannya mulai dari awal lagi.';

  @override
  String get gameKeepPlaying => 'Lanjut main';

  @override
  String get gameLeave => 'Keluar';

  @override
  String get gameNoAdReady => 'Tidak ada iklan siap — coba lagi.';

  @override
  String get gameHintAdHint =>
      'Tonton iklan singkat di Toko untuk petunjuk tambahan, atau coba lagi.';

  @override
  String get howToTitle => 'Cara main';

  @override
  String get howToStep1Title => 'Ketuk sebuah panah';

  @override
  String get howToStep1Body =>
      'Panah melesat ke arah yang ditunjuknya — atas, bawah, kiri, atau kanan.';

  @override
  String get howToStep2Title => 'Jalan kosong = lepas';

  @override
  String get howToStep2Body =>
      'Kalau jalur lurus dari ujungnya sampai tepi kosong, seluruh panah meluncur keluar — berikut semua tikungannya.';

  @override
  String get howToStep3Title => 'Badan panah bisa berbelok';

  @override
  String get howToStep3Body =>
      'Panah menghalangi setiap kotak yang ditempatinya, dari ujung sampai ekor, dan sebagian badannya berbelok. Ikuti seluruh bentuknya sebelum mengetuk.';

  @override
  String get howToStep4Title => 'Tiga hati';

  @override
  String get howToStep4Body =>
      'Ketukan yang terhalang memakan satu hati. Habis ketiganya, papan diulang — dan sisa hati jadi bintang kamu.';

  @override
  String get howToStep5Title => 'Habiskan semuanya';

  @override
  String get howToStep5Body =>
      'Menang dengan mengosongkan papan. Ketuk tombol kisi untuk melihat garis kotak, atau Petunjuk kalau buntu.';

  @override
  String get howToDone => 'Selesai';

  @override
  String get howToGotIt => 'Paham — Main';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get settingsSound => 'Suara';

  @override
  String get settingsSoundSub => 'Bunyi saat lepas, terhalang, dan menang';

  @override
  String get settingsHaptics => 'Getaran';

  @override
  String get settingsHapticsSub => 'Respons saat mengetuk dan terhalang';

  @override
  String get settingsGrid => 'Kisi kotak';

  @override
  String get settingsGridSub => 'Tampilkan kisi di belakang panah';

  @override
  String get settingsLanguage => 'Bahasa';

  @override
  String get settingsShop => 'Toko';

  @override
  String get settingsShopSub => 'Hapus iklan, paket tema, petunjuk tambahan';

  @override
  String get settingsThemes => 'Tema';

  @override
  String get settingsThemesSub => 'Enam palet warna untuk papan';

  @override
  String get settingsPrivacy => 'Opsi privasi';

  @override
  String get settingsPrivacySub => 'Ubah persetujuan iklan kamu';

  @override
  String get settingsReset => 'Atur ulang progres';

  @override
  String get settingsResetSub => 'Mulai lagi dari papan pertama';

  @override
  String get settingsResetTitle => 'Atur ulang progres?';

  @override
  String get settingsResetBody =>
      'Level terkunci lagi dan bintang kembali nol. Pembelian, tema, dan rentetan harian kamu tetap tersimpan.';

  @override
  String get settingsResetConfirm => 'Atur ulang';

  @override
  String get settingsResetDone => 'Progres diatur ulang';

  @override
  String get settingsCancel => 'Batal';

  @override
  String get settingsStatStars => 'Bintang';

  @override
  String get settingsStatCleared => 'Selesai';

  @override
  String get settingsStatReached => 'Tercapai';

  @override
  String get settingsAbout => 'Tentang';

  @override
  String get themesTitle => 'Tema';

  @override
  String get themesUnlockInShop => 'Buka paket tema di Toko';

  @override
  String get themesFree => 'Gratis';

  @override
  String get themesActive => 'Aktif';

  @override
  String get themesPremium => 'Premium';

  @override
  String get themesPremiumPack => 'Premium · Paket tema';

  @override
  String get shopTitle => 'Toko';

  @override
  String get shopRemoveAds => 'Hapus iklan';

  @override
  String get shopRemoveAdsBody =>
      'Tanpa banner atau iklan sela. Petunjuk berhadiah tetap gratis.';

  @override
  String get shopThemePack => 'Paket tema';

  @override
  String get shopThemePackBody =>
      'Buka tema Aurora, Noir, dan Solar selamanya.';

  @override
  String get shopBonusHint => 'Petunjuk tambahan';

  @override
  String shopBonusHintWatch(int ready) {
    return 'Tonton iklan singkat untuk satu petunjuk ($ready siap).';
  }

  @override
  String shopBonusHintFree(int ready) {
    return 'Iklan sudah dihapus, jadi petunjuknya gratis ($ready siap).';
  }

  @override
  String get shopWatchAnAd => 'Tonton iklan';

  @override
  String get shopFree => 'Gratis';

  @override
  String get shopNonConsumable => 'Sekali beli';

  @override
  String get shopOwned => 'Sudah dimiliki';

  @override
  String get shopBuy => 'Beli';

  @override
  String get shopWatch => 'Tonton';

  @override
  String get shopClaim => 'Ambil';

  @override
  String get shopRestore => 'Pulihkan pembelian';

  @override
  String get shopRestoreNote =>
      'Pembelian terhubung ke akun toko kamu dan bisa dipulihkan di perangkat mana pun tempat kamu masuk.';

  @override
  String get shopHintAdded => 'Petunjuk tambahan ditambahkan';

  @override
  String get shopAdNotReady => 'Iklan belum siap — coba sebentar lagi.';

  @override
  String get dailyTitle => 'Harian';

  @override
  String dailyStreakDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'beruntun $days hari',
      one: 'beruntun 1 hari',
    );
    return '$_temp0';
  }

  @override
  String get dailyEmpty => 'Mainkan papan hari ini, nanti muncul di sini.';

  @override
  String get dailyPlayToday => 'Main hari ini';

  @override
  String get languageTitle => 'Bahasa';

  @override
  String get languageSystem => 'Bahasa sistem';

  @override
  String get languageOnboardingTitle => 'Pilih bahasa kamu';

  @override
  String get languageOnboardingBody =>
      'Kamu bisa mengubahnya kapan saja di Pengaturan.';

  @override
  String get languageContinue => 'Lanjut';

  @override
  String get reviewTitle => 'Suka main Arrows?';

  @override
  String get reviewBody =>
      'Rating membantu orang lain menemukan game ini. Cuma sebentar kok.';

  @override
  String get reviewRate => 'Beri rating';

  @override
  String get reviewLater => 'Nanti saja';

  @override
  String get updateTitle => 'Ada pembaruan';

  @override
  String updateBody(String version) {
    return 'Versi $version sudah keluar. Perbarui untuk papan dan perbaikan terbaru.';
  }

  @override
  String get updateNow => 'Perbarui';

  @override
  String get updateLater => 'Nanti';
}
