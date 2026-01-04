import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:context_app/features/subscription/domain/models/pass_type.dart';
import 'package:context_app/features/subscription/data/purchase_repository.dart';
import 'package:context_app/features/subscription/data/pass_type_mapper.dart';
import 'package:context_app/features/subscription/providers.dart';

/// 購買頁面
///
/// 顯示可購買的通行證選項（使用 RevenueCat）
class PurchaseScreen extends ConsumerStatefulWidget {
  const PurchaseScreen({super.key});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen> {
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _listenToPurchaseUpdates();
  }

  void _listenToPurchaseUpdates() {
    ref.listenManual(purchaseUpdateStreamProvider, (_, next) {
      next.whenData((update) {
        switch (update.status) {
          case PurchaseUpdateStatus.pending:
            setState(() => _isPurchasing = true);
            break;

          case PurchaseUpdateStatus.success:
            setState(() => _isPurchasing = false);
            _handlePurchaseSuccess(update.passType!);
            break;

          case PurchaseUpdateStatus.error:
            setState(() => _isPurchasing = false);
            _showErrorSnackBar(update.errorMessage ?? '購買失敗');
            break;

          case PurchaseUpdateStatus.canceled:
            setState(() => _isPurchasing = false);
            break;
        }
      });
    });
  }

  void _handlePurchaseSuccess(PassType passType) async {
    // 啟用通行證
    final entitlementRepository = ref.read(entitlementRepositoryProvider);
    await entitlementRepository.activatePass(passType);

    // 顯示成功訊息
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('subscription.purchase_success'.tr()),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // 返回上一頁
      context.pop();
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _purchase(Package package) async {
    // 先檢查是否已有通行證
    final entitlement = await ref.read(userEntitlementProvider.future);
    if (entitlement.hasActivePass) {
      _showErrorSnackBar('subscription.already_has_pass'.tr());
      return;
    }

    final repository = ref.read(purchaseRepositoryProvider);
    await repository.purchase(package);
  }

  Future<void> _restorePurchases() async {
    final repository = ref.read(purchaseRepositoryProvider);
    await repository.restorePurchases();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('subscription.restore_purchases'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final offeringsAsync = ref.watch(offeringsProvider);
    final entitlementAsync = ref.watch(userEntitlementProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('subscription.purchase_title'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 當前狀態
            entitlementAsync.when(
              data: (entitlement) => _buildCurrentStatus(entitlement),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // 產品列表
            Expanded(
              child: offeringsAsync.when(
                data: (offerings) => entitlementAsync.when(
                  data: (entitlement) =>
                      _buildOfferingsList(offerings, entitlement.hasActivePass),
                  loading: () => _buildOfferingsList(offerings, false),
                  error: (_, __) => _buildOfferingsList(offerings, false),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text('無法載入產品資訊', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(offeringsProvider),
                        child: const Text('重試'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 恢復購買
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _restorePurchases,
                child: Text('subscription.restore_purchases'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(dynamic entitlement) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (entitlement.hasActivePass) {
      final formatter = DateFormat('yyyy/MM/dd HH:mm');
      final expiresText = entitlement.expiresAt != null
          ? formatter.format(entitlement.expiresAt!)
          : '';

      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'subscription.unlimited_access'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (expiresText.isNotEmpty)
                    Text(
                      'subscription.expires_at'.tr(
                        namedArgs: {'date': expiresText},
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 免費用戶狀態
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.token_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'subscription.remaining_usage'.tr(
                    namedArgs: {
                      'remaining': entitlement.remainingFreeUsage.toString(),
                    },
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'subscription.paywall_subtitle'.tr(
                    namedArgs: {'limit': entitlement.dailyFreeLimit.toString()},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferingsList(Offerings? offerings, bool hasActivePass) {
    if (offerings == null || offerings.current == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('目前沒有可購買的產品', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              '請稍後再試',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final packages = offerings.current!.availablePackages;

    // 根據 PassType 排序（Day Pass 在前）
    final sortedPackages = [...packages]
      ..sort((a, b) {
        final aType = PassTypeMapper.fromProductId(a.storeProduct.identifier);
        final bType = PassTypeMapper.fromProductId(b.storeProduct.identifier);
        if (aType == PassType.dayPass) return -1;
        if (bType == PassType.dayPass) return 1;
        return 0;
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedPackages.length,
      itemBuilder: (context, index) {
        final package = sortedPackages[index];
        final passType = PassTypeMapper.fromProductId(
          package.storeProduct.identifier,
        );
        final isRecommended = passType == PassType.tripPass;

        return _buildPackageCard(
          package: package,
          passType: passType,
          isRecommended: isRecommended,
          isDisabled: hasActivePass,
        );
      },
    );
  }

  Widget _buildPackageCard({
    required Package package,
    required PassType? passType,
    bool isRecommended = false,
    bool isDisabled = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final product = package.storeProduct;

    final title = passType == PassType.dayPass
        ? 'subscription.day_pass'.tr()
        : 'subscription.trip_pass'.tr();

    final description = passType == PassType.dayPass
        ? 'subscription.day_pass_description'.tr()
        : 'subscription.trip_pass_description'.tr();

    final icon = passType == PassType.dayPass
        ? Icons.today
        : Icons.flight_takeoff;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 圖示
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: colorScheme.onSurface),
            ),
            const SizedBox(width: 16),

            // 內容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '推薦',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 價格和購買按鈕
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  product.priceString,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: (_isPurchasing || isDisabled)
                      ? null
                      : () => _purchase(package),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('subscription.purchase_button'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
