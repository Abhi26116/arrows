import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';
import '../data/progress_store.dart';
import '../theme/theme_controller.dart';
import 'ads_service.dart';
import 'analytics_service.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  /// Resolved on demand. Reading `InAppPurchase.instance` registers the
  /// platform addition and opens a billing connection on Android, which must
  /// not happen merely because something touched this singleton.
  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool available = false;
  List<ProductDetails> products = [];

  /// Bought again and again; never restored.
  static const consumables = {
    AppConfig.iapHints15,
    AppConfig.iapHints60,
  };

  static const productIds = {
    AppConfig.iapRemoveAds,
    AppConfig.iapThemePack,
    AppConfig.iapBundle,
    ...consumables,
  };

  Future<void> init() async {
    available = await _iap.isAvailable();
    if (!available) return;
    _sub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );
    await queryProducts();
    await _iap.restorePurchases();
  }

  Future<void> queryProducts() async {
    if (!available) return;
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
    products = response.productDetails;
  }

  ProductDetails? product(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<bool> buy(String productId) async {
    if (!available) return false;
    var details = product(productId);
    if (details == null) {
      await queryProducts();
      details = product(productId);
      if (details == null) return false;
    }
    Analytics.instance.track('purchase_start', {'product': productId});
    final param = PurchaseParam(productDetails: details);
    return consumables.contains(productId)
        ? _iap.buyConsumable(purchaseParam: param)
        : _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() async {
    if (!available) return;
    await _iap.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;
      if (purchase.status == PurchaseStatus.error) {
        debugPrint('IAP error: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased) {
        // The transaction id guards against a redelivered purchase paying
        // out twice; without one, fall back to trusting the store.
        final id = purchase.purchaseID;
        final fresh = id == null || await AppStore.instance.claimPurchase(id);
        await _deliver(purchase.productID, fresh: fresh);
        if (fresh) {
          Analytics.instance.track('purchase', {'product': purchase.productID});
        }
      } else if (purchase.status == PurchaseStatus.restored) {
        await _deliver(purchase.productID, fresh: false);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Hands over what [productId] buys. Entitlements are set every time —
  /// restores included — but hints only for a [fresh] purchase, and the
  /// non-consumables' bonus hints only once per install.
  Future<void> _deliver(String productId, {required bool fresh}) async {
    final store = AppStore.instance;
    final hints = AppConfig.hintsPerProduct[productId] ?? 0;

    switch (productId) {
      case AppConfig.iapRemoveAds:
        await store.setRemoveAdsOwned(true);
        AdsService.instance.dropInterstitial();
      case AppConfig.iapThemePack:
        await store.setThemePackOwned(true);
        await ThemeController.instance.load();
      case AppConfig.iapBundle:
        await store.setRemoveAdsOwned(true);
        await store.setThemePackOwned(true);
        AdsService.instance.dropInterstitial();
        await ThemeController.instance.load();
    }

    if (!fresh || hints == 0) return;
    if (consumables.contains(productId)) {
      await store.addBonusHints(hints);
    } else if (await store.claimOnce('bonus_hints_$productId')) {
      await store.addBonusHints(hints);
    }
  }

  /// Debug / simulator unlock when store products are not configured.
  Future<void> unlockForTesting(String productId) async {
    await _deliver(productId, fresh: true);
  }

  void dispose() {
    _sub?.cancel();
  }
}
