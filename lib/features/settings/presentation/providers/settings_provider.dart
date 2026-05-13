import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/settings/data/models/dietary_restriction.dart';
import 'package:fridge_meal/features/settings/data/repositories/settings_repository.dart';

part 'settings_provider.g.dart';

@riverpod
SettingsRepository settingsRepository(Ref ref) {
  return SettingsRepository(Hive.box<dynamic>('settings'));
}

/// 유통기한 알림 토글 상태.
@riverpod
class ExpiryNotificationEnabled extends _$ExpiryNotificationEnabled {
  @override
  bool build() {
    return ref.watch(settingsRepositoryProvider).getExpiryNotificationEnabled();
  }

  Future<void> toggle() async {
    final bool next = !state;
    await ref
        .read(settingsRepositoryProvider)
        .setExpiryNotificationEnabled(next);
    state = next;
  }
}

/// 레시피 생성 기본 인분 수 (1~6).
@riverpod
class DefaultServings extends _$DefaultServings {
  @override
  int build() {
    return ref.watch(settingsRepositoryProvider).getDefaultServings();
  }

  Future<void> set(int servings) async {
    final int clamped = servings.clamp(1, 6);
    if (clamped == state) return;
    await ref.read(settingsRepositoryProvider).setDefaultServings(clamped);
    state = clamped;
  }

  Future<void> increment() => set(state + 1);

  Future<void> decrement() => set(state - 1);
}

/// 앱 버전 + 빌드 번호. "1.0.0 (1)" 형식.
@riverpod
Future<String> appVersion(Ref ref) async {
  final PackageInfo info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

/// 사용자 식이 제한 (F-09). 레시피 추천 시 함께 전달 예정.
@Riverpod(keepAlive: true)
class DietaryRestrictions extends _$DietaryRestrictions {
  @override
  Set<DietaryRestriction> build() {
    return ref.watch(settingsRepositoryProvider).getDietaryRestrictions();
  }

  Future<void> toggle(DietaryRestriction r) async {
    final Set<DietaryRestriction> next = <DietaryRestriction>{...state};
    if (next.contains(r)) {
      next.remove(r);
    } else {
      next.add(r);
    }
    await ref.read(settingsRepositoryProvider).setDietaryRestrictions(next);
    state = next;
  }

  Future<void> clear() async {
    await ref
        .read(settingsRepositoryProvider)
        .setDietaryRestrictions(const <DietaryRestriction>{});
    state = const <DietaryRestriction>{};
  }
}
