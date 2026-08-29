import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config/app_config.dart';
import '../data/progress_store.dart';
import '../theme/theme_controller.dart';
import 'ads_service.dart';

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

  static const productIds = {
    AppConfig.iapRemoveAds,
    AppConfig.iapThemePack,
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
    products = response.productDetails;
  }

  ProductDetails? product(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> buy(String productId) async {
    if (!available) return false;
    final details = product(productId);
    if (details == null) {
      await queryProducts();
      final again = product(productId);
      if (again == null) return false;
      return _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: again),
      );
    }
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
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
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _deliver(purchase.productID);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _deliver(String productId) async {
    if (productId == AppConfig.iapRemoveAds) {
      await AppStore.instance.setRemoveAdsOwned(true);
      AdsService.instance.dispose();
    } else if (productId == AppConfig.iapThemePack) {
      await AppStore.instance.setThemePackOwned(true);
      await ThemeController.instance.load();
    }
  }

  /// Debug / simulator unlock when store products are not configured.
  Future<void> unlockForTesting(String productId) async {
    await _deliver(productId);
  }

  void dispose() {
    _sub?.cancel();
  }
}
