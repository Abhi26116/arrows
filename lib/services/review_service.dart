import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks for a store rating, at a moment the player is likely to be pleased and
/// rarely enough that it never becomes a nuisance.
///
/// Both stores ration the real prompt themselves — iOS shows it at most three
/// times a year and silently ignores the rest — so the app must never treat a
/// request as having been seen, and must never make the moment feel owed. The
/// rules here are deliberately stricter than the stores':
///
/// * only after a win, never mid-board or after a loss
/// * not before the player has cleared enough to have an opinion
/// * once per install unless they actively decline, then not for months
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  static const _keyAsked = 'review_asked_at';
  static const _keyDone = 'review_done';

  /// Enough boards that the player knows whether they like it.
  static const _winsBeforeAsking = 8;

  /// If they said "not now", leave them alone for a good while.
  static const _quietDays = 60;

  final InAppReview _review = InAppReview.instance;

  /// Whether this is a good moment to ask. Cheap enough to call after a win.
  Future<bool> shouldAsk(int totalCleared) async {
    if (totalCleared < _winsBeforeAsking) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyDone) ?? false) return false;
    final asked = prefs.getInt(_keyAsked);
    if (asked != null) {
      final since = DateTime.now().millisecondsSinceEpoch - asked;
      if (since < const Duration(days: _quietDays).inMilliseconds) return false;
    }
    return true;
  }

  /// Records that the player was asked and chose not to rate now.
  Future<void> declined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyAsked, DateTime.now().millisecondsSinceEpoch);
  }

  /// Hands over to the store's own rating sheet.
  ///
  /// The store decides whether to actually show anything, and never tells us
  /// what the player did — so this counts as done either way. Asking again
  /// because we could not observe a rating is exactly the nagging the quotas
  /// exist to prevent.
  Future<void> accepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDone, true);
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
      } else {
        await _review.openStoreListing();
      }
    } catch (e) {
      debugPrint('Review request failed: $e');
    }
  }
}
