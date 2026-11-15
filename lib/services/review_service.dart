import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store rating at a moment the player is likely to be pleased.
///
/// Ratings are what make a listing look alive in search results, so the app
/// asks early, straight through the store's own sheet, and a few times over
/// the life of an install rather than once:
///
/// * only after a win, never mid-board or after a loss
/// * the first time on a clean three-star win once the tutorial is behind
///   them, or on any win a little later
/// * again at [_laterMilestones], each at least [_gapDays] after the last
///
/// Both stores ration the real sheet themselves — iOS shows it at most three
/// times a year and silently ignores the rest — so a request is never treated
/// as having been seen, and the app never puts its own dialog in front of it.
/// A pre-prompt only loses the people who would have rated.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _keyAskedAt = 'review_asked_at';
  static const _keyAskCount = 'review_ask_count';

  /// Cleared boards before a perfect win may trigger the first ask: the six
  /// tutorial boards plus one of the real ones.
  static const _firstAskPerfect = 7;

  /// Cleared boards after which any win may trigger the first ask.
  static const _firstAskAny = 10;

  /// Cleared-board counts for the second and third asks.
  static const _laterMilestones = [30, 80];

  /// Never two asks closer together than this.
  static const _gapDays = 21;

  /// Whether this win is a good moment to ask. Cheap enough to call on every
  /// win.
  Future<bool> shouldAsk({
    required int totalCleared,
    required int stars,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyAskCount) ?? 0;
    if (count > _laterMilestones.length) return false;

    final asked = prefs.getInt(_keyAskedAt);
    if (asked != null) {
      final since = DateTime.now().millisecondsSinceEpoch - asked;
      if (since < const Duration(days: _gapDays).inMilliseconds) return false;
    }

    if (count == 0) {
      return totalCleared >= _firstAskAny ||
          (totalCleared >= _firstAskPerfect && stars >= 3);
    }
    return totalCleared >= _laterMilestones[count - 1];
  }

  /// Hands over to the store's own rating sheet.
  ///
  /// The store decides whether to show anything and never says what the
  /// player did, so this counts as an ask either way.
  Future<void> request() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAskedAt, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_keyAskCount, (prefs.getInt(_keyAskCount) ?? 0) + 1);
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) await review.requestReview();
    } catch (e) {
      debugPrint('Review request failed: $e');
    }
  }
}
