// ─────────────────────────────────────────────────────────────────────────────
// IAP Service — one-time $2.99 unlock (product id: focusly_unlock)
//
// Non-consumable: bought once, restored for free on reinstall or a new device.
// NOTE: this NEVER blocks the app at launch. It is only reached after the
// 90-day trial, and even then the user can choose adverts instead.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const String kUnlockProductId = 'focusly_unlock';

enum PurchaseUiState { idle, loading, pending, success, error }

class IAPService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  ProductDetails? _product;
  PurchaseUiState _uiState = PurchaseUiState.idle;
  String? _error;

  /// Set by the app so a successful purchase can persist the entitlement.
  Future<void> Function()? onUnlocked;

  bool get isAvailable => _available;
  ProductDetails? get product => _product;
  PurchaseUiState get uiState => _uiState;
  String? get error => _error;

  /// Displayed price from the Play Store, falling back to a sensible default.
  String get priceLabel => _product?.price ?? '\$2.99';

  Future<void> initialize() async {
    _available = await _iap.isAvailable();
    if (!_available) {
      notifyListeners();
      return;
    }

    _sub = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: () => _sub?.cancel(),
      onError: (Object e) {
        _uiState = PurchaseUiState.error;
        _error = e.toString();
        notifyListeners();
      },
    );

    final response = await _iap.queryProductDetails({kUnlockProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    }
    notifyListeners();
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
          _uiState = PurchaseUiState.pending;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (p.productID == kUnlockProductId) {
            await onUnlocked?.call();
            _uiState = PurchaseUiState.success;
            notifyListeners();
          }
          break;

        case PurchaseStatus.error:
          _uiState = PurchaseUiState.error;
          _error = p.error?.message ?? 'Purchase failed. Please try again.';
          notifyListeners();
          break;

        case PurchaseStatus.canceled:
          _uiState = PurchaseUiState.idle;
          notifyListeners();
          break;
      }

      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// Start the Google Play purchase flow.
  Future<void> buy() async {
    if (!_available || _product == null) {
      _uiState = PurchaseUiState.error;
      _error = 'The store is unavailable right now. Please try again later.';
      notifyListeners();
      return;
    }
    _uiState = PurchaseUiState.loading;
    _error = null;
    notifyListeners();

    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _product!),
      );
    } catch (e) {
      _uiState = PurchaseUiState.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Restore a previous purchase (reinstall / new device).
  Future<void> restore() async {
    if (!_available) return;
    _uiState = PurchaseUiState.loading;
    _error = null;
    notifyListeners();
    try {
      await _iap.restorePurchases();
      if (_uiState == PurchaseUiState.loading) {
        _uiState = PurchaseUiState.idle;
        notifyListeners();
      }
    } catch (e) {
      _uiState = PurchaseUiState.error;
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    _uiState = PurchaseUiState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
