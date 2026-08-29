import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Google's User Messaging Platform flow.
///
/// AdMob will not serve ads to users in the EEA or UK without a certified
/// consent message, so this runs before the ads SDK starts. Everywhere else
/// the SDK reports "not required" and the whole thing is a no-op.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// The launch-time flow, kept so later callers can wait on it instead of
  /// racing it. Null until [gather] first runs.
  Future<void>? _gathering;

  /// Widget tests have no ads SDK to answer these calls, so the flow would sit
  /// on its timeout timer and fail the test with a pending timer.
  static final bool _inTest = Platform.environment.containsKey('FLUTTER_TEST');

  /// Asks for consent if the user's region requires it, then for tracking
  /// permission on iOS. Safe to call on every launch — both answers are cached
  /// by the OS and the SDK.
  ///
  /// Order matters: Google's consent message is meant to be shown before the
  /// system tracking prompt, and both before the ads SDK starts.
  Future<void> gather() {
    if (_inTest) return Future<void>.value();
    return _gathering ??= _gather();
  }

  Future<void> _gather() async {
    try {
      await _requestUpdate();
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status == ConsentStatus.required &&
          await ConsentInformation.instance.isConsentFormAvailable()) {
        await showForm();
      }
    } catch (e) {
      // Never let the consent flow stop the app from starting.
      debugPrint('Consent flow failed: $e');
    }
    await _requestTracking();
  }

  /// iOS only. Without this the ads are non-personalised, which pays far less;
  /// Android has no equivalent prompt and the call is a no-op there.
  Future<void> _requestTracking() async {
    if (!Platform.isIOS) return;
    try {
      final status =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('Tracking prompt failed: $e');
    }
  }

  /// Whether a form exists for this user — drives the Settings entry, which
  /// regulators expect to be reachable after the first prompt.
  Future<bool> get formAvailable async {
    if (_inTest) return false;
    // Settings can be opened before the launch flow has answered; asking the
    // SDK first would get a premature false and hide the row for the session.
    await _gathering;
    try {
      return await ConsentInformation.instance.isConsentFormAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Re-opens the consent form so the user can change their mind.
  Future<void> showForm() async {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      ConsentForm.loadConsentForm(
        (form) => form.show((error) {
          if (error != null) debugPrint('Consent form dismissed: ${_describe(error)}');
          finish();
        }),
        (error) {
          debugPrint('Consent form failed to load: ${_describe(error)}');
          finish();
        },
      );
    } catch (e) {
      debugPrint('Consent form failed: $e');
      finish();
    }

    // A stuck form must not hold ads (or the Settings screen) hostage.
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
  }

  static String _describe(FormError error) =>
      'code ${error.errorCode} — ${error.message}';

  /// Normally empty parameters. With `--dart-define=CONSENT_TEST_EEA=true` the
  /// listed devices are told they are in the EEA, so the form appears from
  /// anywhere — the only way to exercise this flow outside Europe.
  ConsentRequestParameters _params() {
    if (!AppConfig.consentTestEea) return ConsentRequestParameters();
    return ConsentRequestParameters(
      consentDebugSettings: ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: AppConfig.consentTestDeviceIds,
      ),
    );
  }

  /// Forgets the cached answer so the next [gather] shows the form again.
  /// Testing only — the consent choice is meant to persist for real users.
  Future<void> resetForTesting() async {
    try {
      await ConsentInformation.instance.reset();
      _gathering = null;
    } catch (e) {
      debugPrint('Consent reset failed: $e');
    }
  }

  Future<void> _requestUpdate() async {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      _params(),
      finish,
      (error) {
        debugPrint('Consent info update failed: ${_describe(error)}');
        finish();
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }
}
