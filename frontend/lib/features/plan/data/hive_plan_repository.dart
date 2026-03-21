import 'dart:convert';

import 'package:context_app/features/plan/domain/models/plan.dart';
import 'package:context_app/features/plan/domain/repositories/plan_repository.dart';
import 'package:hive/hive.dart';

/// Hive 實作的 PlanRepository
///
/// 使用 JSON 字串序列化存入 Box，與現有 Hive 使用方式一致。
/// Key = plan.id，Value = jsonEncoded plan.toJson()
class HivePlanRepository implements PlanRepository {
  static const String _boxName = 'plans';

  Future<Box<dynamic>> _getBox() => Hive.openBox<dynamic>(_boxName);

  @override
  Future<List<Plan>> getAll() async {
    try {
      final box = await _getBox();
      final plans =
          box.values
              .map(
                (v) => Plan.fromJson(
                  jsonDecode(v as String) as Map<String, dynamic>,
                ),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return plans;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(Plan plan) async {
    final box = await _getBox();
    await box.put(plan.id, jsonEncode(plan.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
