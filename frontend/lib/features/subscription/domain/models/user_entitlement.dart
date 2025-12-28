import 'package:context_app/features/subscription/domain/models/pass_type.dart';

/// 用戶權益模型
///
/// 代表用戶目前的付費狀態和使用權限
class UserEntitlement {
  /// 是否有有效的通行證
  final bool hasActivePass;

  /// 當前啟用的通行證類型
  final PassType? activePassType;

  /// 通行證過期時間
  final DateTime? expiresAt;

  /// 今日剩餘免費使用次數
  final int remainingFreeUsage;

  /// 每日免費使用上限
  final int dailyFreeLimit;

  const UserEntitlement({
    required this.hasActivePass,
    this.activePassType,
    this.expiresAt,
    required this.remainingFreeUsage,
    this.dailyFreeLimit = 3,
  });

  /// 免費用戶的初始狀態
  factory UserEntitlement.free({int dailyFreeLimit = 3}) {
    return UserEntitlement(
      hasActivePass: false,
      remainingFreeUsage: dailyFreeLimit,
      dailyFreeLimit: dailyFreeLimit,
    );
  }

  /// 付費用戶的狀態
  factory UserEntitlement.premium({
    required PassType passType,
    DateTime? expiresAt,
  }) {
    return UserEntitlement(
      hasActivePass: true,
      activePassType: passType,
      expiresAt: expiresAt,
      remainingFreeUsage: 0, // 付費用戶不需要免費次數
    );
  }

  /// 是否可以使用 AI 導覽
  bool get canUseNarration => hasActivePass || remainingFreeUsage > 0;

  /// 是否為無限使用（已付費）
  bool get isUnlimited => hasActivePass;

  /// 是否已達免費上限
  bool get hasReachedFreeLimit => !hasActivePass && remainingFreeUsage <= 0;

  /// 複製並更新部分屬性
  UserEntitlement copyWith({
    bool? hasActivePass,
    PassType? activePassType,
    DateTime? expiresAt,
    int? remainingFreeUsage,
    int? dailyFreeLimit,
  }) {
    return UserEntitlement(
      hasActivePass: hasActivePass ?? this.hasActivePass,
      activePassType: activePassType ?? this.activePassType,
      expiresAt: expiresAt ?? this.expiresAt,
      remainingFreeUsage: remainingFreeUsage ?? this.remainingFreeUsage,
      dailyFreeLimit: dailyFreeLimit ?? this.dailyFreeLimit,
    );
  }

  @override
  String toString() {
    return 'UserEntitlement('
        'hasActivePass: $hasActivePass, '
        'activePassType: $activePassType, '
        'expiresAt: $expiresAt, '
        'remainingFreeUsage: $remainingFreeUsage, '
        'dailyFreeLimit: $dailyFreeLimit)';
  }
}
