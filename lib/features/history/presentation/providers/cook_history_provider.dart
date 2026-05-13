import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/history/data/models/cook_history_entry.dart';
import 'package:fridge_meal/features/history/data/repositories/cook_history_repository.dart';
import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

part 'cook_history_provider.g.dart';

@Riverpod(keepAlive: true)
CookHistoryRepository cookHistoryRepository(Ref ref) {
  return CookHistoryRepository(Hive.box<String>('cook_history'));
}

/// 사용자가 만든 요리 기록 (최근순).
@Riverpod(keepAlive: true)
class CookHistory extends _$CookHistory {
  @override
  List<CookHistoryEntry> build() {
    return ref.read(cookHistoryRepositoryProvider).readAll();
  }

  /// 요리 완료 기록 추가. 추가된 entry를 반환.
  Future<CookHistoryEntry> addCompleted(Recipe recipe) async {
    final CookHistoryRepository repo = ref.read(cookHistoryRepositoryProvider);
    final CookHistoryEntry entry = await repo.add(recipe);
    state = repo.readAll();
    return entry;
  }

  Future<void> delete(String id) async {
    final CookHistoryRepository repo = ref.read(cookHistoryRepositoryProvider);
    await repo.remove(id);
    state = repo.readAll();
  }
}
