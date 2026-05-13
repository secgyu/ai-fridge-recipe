import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

/// 즐겨찾기 레시피의 Hive 영속화 계층.
///
/// 추후 Supabase `favorites` 테이블 도입 시:
/// - 온라인: Postgres에 INSERT/DELETE
/// - 오프라인: 이 클래스의 Hive 박스를 폴백으로 사용
///
/// 현재는 로컬 전용. Recipe를 `jsonEncode`된 String으로 저장해
/// 향후 모델 변경 시에도 마이그레이션이 단순한 형태를 유지한다.
class FavoriteRecipeRepository {
  FavoriteRecipeRepository(this._box);

  final Box<String> _box;

  /// 저장된 모든 즐겨찾기 레시피 (최근 저장 순).
  ///
  /// 손상된 entry는 조용히 건너뛰고, 다음 부팅 시 정리되도록 키 자체는 보존.
  /// 운영 단계에서 corrupt 비율이 높아지면 별도 cleanup 추가.
  List<Recipe> readAll() {
    final List<Recipe> out = <Recipe>[];
    for (final String raw in _box.values) {
      try {
        final Map<String, dynamic> json =
            jsonDecode(raw) as Map<String, dynamic>;
        out.add(Recipe.fromJson(json));
      } catch (_) {
        // ignore corrupt entry
      }
    }
    // 최근에 추가된 항목을 위로. Box는 insertion order를 유지하므로 역순.
    return out.reversed.toList(growable: false);
  }

  bool contains(String recipeId) => _box.containsKey(recipeId);

  Future<void> add(Recipe recipe) async {
    await _box.put(recipe.id, jsonEncode(recipe.toJson()));
  }

  Future<void> remove(String recipeId) async {
    await _box.delete(recipeId);
  }

  /// 즐겨찾기 토글. 반환값은 토글 이후의 등록 상태(`true` = 추가됨).
  Future<bool> toggle(Recipe recipe) async {
    if (contains(recipe.id)) {
      await remove(recipe.id);
      return false;
    }
    await add(recipe);
    return true;
  }
}
