import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _proProductId = 'pawpass_pro';
const String _premiumProductId = 'pawpass_premium';

class IAPService {
  static final IAPService _instance = IAPService._internal();
  factory IAPService() => _instance;
  IAPService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  final Set<String> _productIds = {_proProductId, _premiumProductId};
  List<ProductDetails> _products = [];

  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return;
    }

    final response = await _iap.queryProductDetails(_productIds);
    _products = response.productDetails;
    if (response.error != null) {
      debugPrint('Error fetching products: ${response.error}');
    }

    _listenToPurchaseUpdated();
  }

  void _listenToPurchaseUpdated() {
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (error) => debugPrint('Purchase stream error: $error'),
    );
  }

  Future<void> _handlePurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchase.error?.message}');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final valid = await _verifyPurchase(purchase);
        if (valid) {
          await _deliverProduct(purchase);
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchase) async {
    final productID = purchase.productID;
    String plan;
    if (productID == _proProductId) {
      plan = 'pro';
    } else if (productID == _premiumProductId) {
      plan = 'premium';
    } else {
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android';
      final receiptKey = platform == 'ios'
          ? 'iap_receipt_ios'
          : 'iap_receipt_android';

      await supabase
          .from('users')
          .update({
            'plan': plan,
            'plan_expires_at': DateTime.now()
                .add(const Duration(days: 30))
                .toIso8601String(),
            receiptKey: purchase.verificationData.serverVerificationData,
          })
          .eq('id', user.id);

      debugPrint('IAP: Plan upgraded to $plan');
    } catch (e) {
      debugPrint('Error delivering product: $e');
    }
  }

  Future<void> buyProduct(String productId) async {
    if (!_isAvailable) {
      throw Exception('IAP not available');
    }

    final product = _products.firstWhere(
      (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      throw Exception('IAP not available');
    }
    await _iap.restorePurchases();
  }

  String getPlanFromProductId(String productId) {
    switch (productId) {
      case _proProductId:
        return 'pro';
      case _premiumProductId:
        return 'premium';
      default:
        return 'free';
    }
  }

  String getProductIdFromPlan(String plan) {
    switch (plan) {
      case 'pro':
        return _proProductId;
      case 'premium':
        return _premiumProductId;
      default:
        return '';
    }
  }

  ProductDetails? getProductDetails(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
