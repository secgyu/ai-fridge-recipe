import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:fridge_meal/features/history/data/models/cook_history_entry.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

/// 요리 기록의 Hive 영속화 계층.
///
/// 키: `${recipe.id}_${cookedAt.millisecondsSinceEpoch}` — 같은 레시피를
/// 여러 번 만들어도 별도 entry로 누적.
/// 값: jsonEncoded `CookHistoryEntry`.
class CookHistoryRepository {
  CookHistoryRepository(this._box);

  final Box<String> _box;

  /// 시간 역순(최근 → 과거).
  List<CookHistoryEntry> readAll() {
    final List<CookHistoryEntry> out = <CookHistoryEntry>[];
    for (final String raw in _box.values) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        out.add(CookHistoryEntry.fromJson(json));
      } catch (_) {
        // ignore corrupt
      }
    }
    out.sort((CookHistoryEntry a, CookHistoryEntry b) =>
        b.cookedAt.compareTo(a.cookedAt));
    return List<CookHistoryEntry>.unmodifiable(out);
  }

  Future<CookHistoryEntry> add(Recipe recipe) async {
    final DateTime now = DateTime.now();
    final CookHistoryEntry entry = CookHistoryEntry(
      id: '${recipe.id}_${now.millisecondsSinceEpoch}',
      recipe: recipe,
      cookedAt: now,
    );
    await _box.put(entry.id, jsonEncode(entry.toJson()));
    return entry;
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}
