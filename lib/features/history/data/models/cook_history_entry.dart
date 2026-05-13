import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fridge_meal/features/recipe/data/models/recipe.dart';

part 'cook_history_entry.freezed.dart';
part 'cook_history_entry.g.dart';

/// 사용자가 실제로 조리 완료한 레시피 한 건의 기록.
///
/// 추후 Supabase `cook_history` 테이블 도입 시 동일 컬럼 매핑.
@freezed
abstract class CookHistoryEntry with _$CookHistoryEntry {
  const CookHistoryEntry._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CookHistoryEntry({
    /// `${recipe.id}_${cookedAt.millisecondsSinceEpoch}` 같은 식으로 유일하게.
    required String id,
    required Recipe recipe,
    required DateTime cookedAt,
  }) = _CookHistoryEntry;

  factory CookHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$CookHistoryEntryFromJson(json);
}
