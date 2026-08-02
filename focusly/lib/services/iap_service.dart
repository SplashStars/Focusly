import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IAPService extends ChangeNotifier {
  static const String productId = 'focusly_unlock';
  static const String _purchasedKey = 'focusly_purchased';

  bool _isPurchased = false;
  bool _isLoading = false;
  String? _error;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final InAppPurchase _iap = InAppPurchase.instance;

  bool get isPurchased => _isPurchased;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPurchased = prefs.getBool(_purchasedKey) ?? false;
    if (_isPurchased) { notifyListeners(); return; }
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate,
        onError: (e) { _error = e.toString(); notifyListeners(); });
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!await _iap.isAvailable()) {
      _error = 'Store not available'; notifyListeners(); return;
    }
    final r = await _iap.queryProductDetails({productId});
    if (r.error != null) { _error = r.error!.message; }
    else { _products = r.productDetails; }
    notifyListeners();
  }

  Future<void> purchase() async {
    if (_products.isEmpty) await _loadProducts();
    if (_products.isEmpty) { _error = 'Product not available'; notifyListeners(); return; }
    _isLoading = true; _error = null; notifyListeners();
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: _products.first));
  }

  Future<void> restore() async {
    _isLoading = true; _error = null; notifyListeners();
    await _iap.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID == productId) {
        if (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored) {
          _isPurchased = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_purchasedKey, true);
          await _iap.completePurchase(p);
        } else if (p.status == PurchaseStatus.error) {
          _error = p.error?.message ?? 'Purchase failed';
        }
      }
    }
    _isLoading = false; notifyListeners();
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }
}
