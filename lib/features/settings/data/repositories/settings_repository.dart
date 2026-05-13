import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:fridge_meal/features/settings/data/models/dietary_restriction.dart';

/// 사용자 환경설정을 Hive `settings` 박스에 영속화.
///
/// 키 네임스페이스는 `settings.*`. Auth/Onboarding 키와 충돌하지 않도록 분리.
/// 기본값은 항상 코드에서 반환 (저장된 값이 없거나 타입 불일치 시).
class SettingsRepository {
  SettingsRepository(this._box);

  final Box<dynamic> _box;

  static const String _expiryNotificationKey = 'settings.expiry_notification';
  static const String _defaultServingsKey = 'settings.default_servings';
  static const String _dietaryRestrictionsKey = 'settings.dietary_restrictions';

  /// 유통기한 알림 ON/OFF. 기본값 `true` (안내 보내는 게 사용자 이득).
  bool getExpiryNotificationEnabled() {
    final Object? raw = _box.get(_expiryNotificationKey);
    return raw is bool ? raw : true;
  }

  Future<void> setExpiryNotificationEnabled(bool enabled) async {
    await _box.put(_expiryNotificationKey, enabled);
  }

  /// 레시피 생성 시 기본 인분 수. 1~6 범위로 클램프.
  int getDefaultServings() {
    final Object? raw = _box.get(_defaultServingsKey);
    final int value = raw is int ? raw : 2;
    return value.clamp(1, 6);
  }

  Future<void> setDefaultServings(int servings) async {
    final int clamped = servings.clamp(1, 6);
    await _box.put(_defaultServingsKey, clamped);
  }

  /// 사용자가 선택한 식이 제한 모음. 저장은 `value` 문자열 리스트.
  Set<DietaryRestriction> getDietaryRestrictions() {
    final Object? raw = _box.get(_dietaryRestrictionsKey);
    if (raw is! List) return const <DietaryRestriction>{};
    final Set<DietaryRestriction> out = <DietaryRestriction>{};
    for (final Object? item in raw) {
      if (item is String) {
        final DietaryRestriction? r = DietaryRestriction.fromValue(item);
        if (r != null) out.add(r);
      }
    }
    return out;
  }

  Future<void> setDietaryRestrictions(Set<DietaryRestriction> next) async {
    final List<String> values =
        next.map((DietaryRestriction r) => r.value).toList(growable: false);
    await _box.put(_dietaryRestrictionsKey, values);
  }
}
