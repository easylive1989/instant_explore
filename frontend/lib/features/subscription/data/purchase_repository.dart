import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:context_app/common/config/api_config.dart';
import 'package:context_app/features/subscription/domain/models/pass_type.dart';

/// RevenueCat 購買倉儲
///
/// 使用 RevenueCat SDK 處理應用內購買
class PurchaseRepository {
  final ApiConfig _apiConfig;
  final _purchaseController = StreamController<PurchaseUpdate>.broadcast();

  /// 購買狀態串流
  Stream<PurchaseUpdate> get purchaseStream => _purchaseController.stream;

  PurchaseRepository(this._apiConfig);

  /// 初始化 RevenueCat
  Future<bool> initialize() async {
    final apiKey = _apiConfig.revenueCatApiKey;

    if (apiKey.isEmpty) {
      debugPrint('⚠️ RevenueCat API Key 未設定');
      return false;
    }

    try {
      // 設定 RevenueCat
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);

      // 監聽購買更新
      Purchases.addCustomerInfoUpdateListener(_handleCustomerInfoUpdated);

      debugPrint('✅ RevenueCat 初始化成功');
      return true;
    } catch (e) {
      debugPrint('❌ RevenueCat 初始化失敗: $e');
      return false;
    }
  }

  /// 處理客戶資訊更新
  void _handleCustomerInfoUpdated(CustomerInfo info) {
    debugPrint('📦 CustomerInfo 更新: ${info.entitlements.active.keys}');

    // 檢查是否有 premium_access 權益
    if (info.entitlements.active.containsKey('premium_access')) {
      final entitlement = info.entitlements.active['premium_access']!;
      final passType = PassType.fromProductId(entitlement.productIdentifier);
      if (passType != null) {
        _purchaseController.add(PurchaseUpdate.success(passType));
      }
    }
  }

  /// 設定用戶 ID（關聯 Supabase 用戶）
  Future<void> setUserId(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint('✅ RevenueCat 用戶登入: $userId');
    } catch (e) {
      debugPrint('❌ RevenueCat 用戶登入失敗: $e');
    }
  }

  /// 登出用戶
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      debugPrint('✅ RevenueCat 用戶登出');
    } catch (e) {
      debugPrint('❌ RevenueCat 用戶登出失敗: $e');
    }
  }

  /// 取得可購買的產品列表
  Future<List<StoreProduct>> getProducts() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        debugPrint('⚠️ 沒有可用的 Offerings');
        return [];
      }

      final products = offerings.current!.availablePackages
          .map((p) => p.storeProduct)
          .toList();

      debugPrint('✅ 找到 ${products.length} 個產品');
      return products;
    } catch (e) {
      debugPrint('❌ 取得產品失敗: $e');
      return [];
    }
  }

  /// 取得 Offerings
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('❌ 取得 Offerings 失敗: $e');
      return null;
    }
  }

  /// 購買產品
  Future<bool> purchase(Package package) async {
    try {
      _purchaseController.add(
        PurchaseUpdate.pending(package.storeProduct.identifier),
      );

      // 使用 purchasePackage API (deprecated 但穩定)
      // ignore: deprecated_member_use
      final result = await Purchases.purchasePackage(package);
      final customerInfo = result.customerInfo;

      // 檢查購買是否成功
      if (customerInfo.entitlements.active.containsKey('premium_access')) {
        final entitlement = customerInfo.entitlements.active['premium_access']!;
        final passType = PassType.fromProductId(entitlement.productIdentifier);
        if (passType != null) {
          _purchaseController.add(PurchaseUpdate.success(passType));
          debugPrint('✅ 購買成功: ${package.storeProduct.identifier}');
          return true;
        }
      }

      _purchaseController.add(PurchaseUpdate.error('購買未授予權益'));
      return false;
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        _purchaseController.add(PurchaseUpdate.canceled());
      } else {
        _purchaseController.add(PurchaseUpdate.error('購買失敗: $e'));
      }
      debugPrint('❌ 購買失敗: $e');
      return false;
    } catch (e) {
      _purchaseController.add(PurchaseUpdate.error('購買失敗: $e'));
      debugPrint('❌ 購買失敗: $e');
      return false;
    }
  }

  /// 恢復購買
  Future<CustomerInfo?> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('✅ 恢復購買完成');

      // 檢查是否有權益
      if (customerInfo.entitlements.active.containsKey('premium_access')) {
        final entitlement = customerInfo.entitlements.active['premium_access']!;
        final passType = PassType.fromProductId(entitlement.productIdentifier);
        if (passType != null) {
          _purchaseController.add(PurchaseUpdate.success(passType));
        }
      }

      return customerInfo;
    } catch (e) {
      debugPrint('❌ 恢復購買失敗: $e');
      return null;
    }
  }

  /// 取得客戶資訊
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('❌ 取得客戶資訊失敗: $e');
      return null;
    }
  }

  /// 檢查是否有有效的 premium 權益
  Future<bool> hasActiveEntitlement() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey('premium_access');
    } catch (e) {
      debugPrint('❌ 檢查權益失敗: $e');
      return false;
    }
  }

  /// 釋放資源
  void dispose() {
    _purchaseController.close();
  }
}

/// 購買更新狀態
class PurchaseUpdate {
  final PurchaseUpdateStatus status;
  final PassType? passType;
  final String? productId;
  final String? errorMessage;

  const PurchaseUpdate._({
    required this.status,
    this.passType,
    this.productId,
    this.errorMessage,
  });

  factory PurchaseUpdate.pending(String productId) => PurchaseUpdate._(
    status: PurchaseUpdateStatus.pending,
    productId: productId,
  );

  factory PurchaseUpdate.success(PassType passType) => PurchaseUpdate._(
    status: PurchaseUpdateStatus.success,
    passType: passType,
  );

  factory PurchaseUpdate.error(String message) => PurchaseUpdate._(
    status: PurchaseUpdateStatus.error,
    errorMessage: message,
  );

  factory PurchaseUpdate.canceled() =>
      const PurchaseUpdate._(status: PurchaseUpdateStatus.canceled);
}

/// 購買更新狀態類型
enum PurchaseUpdateStatus { pending, success, error, canceled }
