import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'native_bridge_service.dart';

// ── Gem product IDs → amounts ─────────────────────────────────────────────────

const Map<String, int> kGemProductAmounts = {
  'gems_80':    80,
  'gems_500':   500,
  'gems_1200':  1200,
  'gems_2500':  2500,
  'gems_6500':  6500,
  'gems_14000': 14000,
};

// ── Bundle contents (mirrors deliverPurchase on the Android side) ─────────────

class BundleContent {
  const BundleContent({
    required this.titleAr,
    required this.gems,
    required this.coins,
    this.inv5050 = 0,
    this.invAudience = 0,
    this.invCall = 0,
    required this.savePct,
  });
  final String titleAr;
  final int gems;
  final int coins;
  final int inv5050;
  final int invAudience;
  final int invCall;
  final int savePct;
}

const Map<String, BundleContent> kBundleContents = {
  'pack_starter': BundleContent(
    titleAr: 'حزمة المبتدئ',
    gems: 120, coins: 500, inv5050: 2,
    savePct: 20,
  ),
  'pack_value': BundleContent(
    titleAr: 'حزمة القيمة',
    gems: 600, coins: 2000, inv5050: 3, invAudience: 2,
    savePct: 25,
  ),
  'pack_champion': BundleContent(
    titleAr: 'حزمة البطل',
    gems: 1800, coins: 10000, inv5050: 5, invAudience: 3, invCall: 2,
    savePct: 35,
  ),
};

// ── IapService ────────────────────────────────────────────────────────────────

class IapService extends ChangeNotifier {
  IapService(this._nativeBridge);
  final NativeBridgeService _nativeBridge;

  static final _store = InAppPurchase.instance;

  static const _kAllIds = {
    'gems_80',
    'gems_500',
    'gems_1200',
    'gems_2500',
    'gems_6500',
    'gems_14000',
    'pack_starter',
    'pack_value',
    'pack_champion',
  };

  bool isAvailable = false;
  bool isLoading = true;
  bool isPurchasing = false;
  Map<String, ProductDetails> products = {};
  String? error;

  /// ID of the last successfully delivered product — used for success messages.
  String? lastDeliveredId;

  /// Called after items are credited to the player's account.
  /// Set this in the store screen to refresh the currency display.
  VoidCallback? onItemsDelivered;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> init() async {
    isAvailable = await _store.isAvailable();
    if (!isAvailable) {
      isLoading = false;
      notifyListeners();
      return;
    }

    _sub = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object e) {
        error = e.toString();
        isPurchasing = false;
        notifyListeners();
      },
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      final resp = await _store.queryProductDetails(_kAllIds);
      products = {for (final p in resp.productDetails) p.id: p};
    } catch (_) {
      // Keep products empty; UI will fall back to hardcoded JOD prices.
    }
    isLoading = false;
    notifyListeners();
  }

  /// Initiates a Google Play purchase for [productId].
  Future<void> buy(String productId) async {
    if (!isAvailable) {
      error = 'متجر Google Play غير متاح حالياً';
      notifyListeners();
      return;
    }
    final details = products[productId];
    if (details == null) {
      error = 'المنتج غير متوفر';
      notifyListeners();
      return;
    }

    isPurchasing = true;
    error = null;
    notifyListeners();

    try {
      await _store.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (e) {
      error = e.toString();
      isPurchasing = false;
      notifyListeners();
    }
  }

  void _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        // Credit items to the player via the native bridge.
        await _nativeBridge.deliverPurchase(p.productID);
        lastDeliveredId = p.productID;
        if (p.pendingCompletePurchase) await _store.completePurchase(p);
        onItemsDelivered?.call();
      } else if (p.status == PurchaseStatus.error) {
        error = p.error?.message ?? 'فشلت عملية الشراء';
      }
    }
    isPurchasing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
