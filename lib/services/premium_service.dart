import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'auth_service.dart';

class PremiumService {
  static final PremiumService instance = PremiumService._();
  PremiumService._();

  static const String _monthlyId = 'premium_monthly';
  static const String _yearlyId = 'premium_yearly';

  final InAppPurchase _iap = InAppPurchase.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  bool _isPremium = false;
  DateTime? _expiresAt;
  final _statusController = StreamController<bool>.broadcast();

  bool get isPremium => _isPremium;
  DateTime? get expiresAt => _expiresAt;
  Stream<bool> get statusStream => _statusController.stream;

  // Feature gates
  bool get canUseFriends => _isPremium;
  bool get canUseChallenge => _isPremium;
  bool get canUseUnlimitedReminders => _isPremium;
  bool get canUseDetailedRisk => _isPremium;
  int get maxHistoryDays => _isPremium ? 365 : 7;
  int get maxDailyReminders => _isPremium ? 99 : 3;

  Future<void> init() async {
    await _checkFirestorePremium();
    _listenToPurchases();
  }

  Future<void> _checkFirestorePremium() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _isPremium = data['isPremium'] == true;
        final exp = data['premiumExpiresAt'];
        if (exp != null) {
          _expiresAt = (exp as Timestamp).toDate();
          if (_expiresAt!.isBefore(DateTime.now())) {
            _isPremium = false;
            await _db.collection('users').doc(uid).update({'isPremium': false});
          }
        }
      }
    } catch (e) {
      debugPrint('Premium check failed: $e');
    }
    _statusController.add(_isPremium);
  }

  void _listenToPurchases() {
    _purchaseSub?.cancel();
    _purchaseSub = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _handlePurchase(purchase);
      }
    });
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      await _activatePremium(purchase.productID);
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _activatePremium(String productId) async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;

    final months = productId == _yearlyId ? 12 : 1;
    final expiry = DateTime.now().add(Duration(days: months * 30));

    try {
      await _db.collection('users').doc(uid).update({
        'isPremium': true,
        'premiumExpiresAt': Timestamp.fromDate(expiry),
        'premiumProductId': productId,
        'premiumActivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    _isPremium = true;
    _expiresAt = expiry;
    _statusController.add(true);
  }

  Future<List<ProductDetails>> getProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];

    final response = await _iap.queryProductDetails({_monthlyId, _yearlyId});
    return response.productDetails;
  }

  Future<bool> purchaseMonthly() async {
    return _purchase(_monthlyId);
  }

  Future<bool> purchaseYearly() async {
    return _purchase(_yearlyId);
  }

  Future<bool> _purchase(String productId) async {
    try {
      final available = await _iap.isAvailable();
      if (!available) return false;

      final response = await _iap.queryProductDetails({productId});
      if (response.productDetails.isEmpty) return false;

      final product = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: product);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  // For testing / development
  Future<void> grantPremiumForTesting() async {
    await _activatePremium(_monthlyId);
  }

  Future<void> revokePremiumForTesting() async {
    final uid = AuthService.instance.currentUserId;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'isPremium': false,
        'premiumExpiresAt': FieldValue.delete(),
      });
    } catch (_) {}
    _isPremium = false;
    _expiresAt = null;
    _statusController.add(false);
  }

  void dispose() {
    _purchaseSub?.cancel();
    _statusController.close();
  }
}
