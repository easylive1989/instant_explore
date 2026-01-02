import 'package:purchases_flutter/purchases_flutter.dart';

/// RevenueCat SDK 的封裝服務
///
/// 用於隔離靜態方法呼叫，方便測試時進行 Mock
class RevenueCatService {
  Future<CustomerInfo> getCustomerInfo() {
    return Purchases.getCustomerInfo();
  }
}
