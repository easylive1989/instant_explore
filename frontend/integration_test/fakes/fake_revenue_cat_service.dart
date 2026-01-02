import 'package:context_app/features/subscription/data/revenue_cat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockRevenueCatService extends Mock implements RevenueCatService {}

/// 測試用的 Fake RevenueCatService
class FakeRevenueCatService implements RevenueCatService {
  @override
  Future<CustomerInfo> getCustomerInfo() async {
    // 建立一個空的 CustomerInfo (無付費權益)
    // 由於 CustomerInfo 建構子是私有的或僅供內部使用，我們可能需要 mock 它
    // 或者使用 mocktail

    // 暫時拋出 UnimplementedError 或返回 Mock
    // 但因為我們希望測試能跑通，這裡需要返回一個 "Free" 的狀態
    throw UnimplementedError('應該在具體測試中使用 Mock 覆蓋，或此處回傳 Mock 物件');
  }
}

/// 簡單的 Mock 實作，回傳無權益狀態
class FakeFreeRevenueCatService extends Mock implements RevenueCatService {
  @override
  Future<CustomerInfo> getCustomerInfo() async {
    // Mock CustomerInfo is hard because it has no public constructor easily accessible usually?
    // Actually we can just create a MockCustomerInfo class.
    return MockCustomerInfo();
  }
}

class MockCustomerInfo extends Mock implements CustomerInfo {
  @override
  EntitlementInfos get entitlements => MockEntitlementInfos();
}

class MockEntitlementInfos extends Mock implements EntitlementInfos {
  @override
  Map<String, EntitlementInfo> get active => {};
}
