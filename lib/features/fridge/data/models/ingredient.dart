import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:fridge_meal/core/constants/ingredient_category.dart';
import 'package:fridge_meal/features/fridge/data/models/storage_location.dart';

part 'ingredient.freezed.dart';
part 'ingredient.g.dart';

// TODO(persistence): Supabase + 오프라인 캐시 도입 시 hive_ce의 @HiveType/@HiveField를
// 여기에 추가한다. typeId는 0번부터 순차 할당 (image_mapper 도입 후 첫 모델).

/// 사용자가 등록한 냉장고 재료.
///
/// - 서버: Postgres `ingredients` 테이블 (1 row = 1 instance)
/// - 클라이언트: snake_case 컬럼 → Freezed/JsonSerializable로 매핑
@freezed
abstract class Ingredient with _$Ingredient {
  const Ingredient._();

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Ingredient({
    required String id,
    required String userId,
    required String name,
    required IngredientCategory category,
    required StorageLocation storage,

    /// 유통기한. 미설정이면 D-day 계산 불가 → 정렬 맨 뒤.
    DateTime? expiryDate,

    @Default(1) int quantity,
    @Default('개') String unit,
    DateTime? createdAt,
  }) = _Ingredient;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);

  /// 오늘 자정 기준 남은 일수.
  /// `expiryDate`가 없으면 `null`.
  int? get daysLeft {
    final DateTime? exp = expiryDate;
    if (exp == null) return null;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime expDay = DateTime(exp.year, exp.month, exp.day);
    return expDay.difference(today).inDays;
  }

  /// 유통기한 임박(D-3 이내, 만료 포함)인지.
  bool get isExpirySoon {
    final int? d = daysLeft;
    return d != null && d <= 3;
  }
}
