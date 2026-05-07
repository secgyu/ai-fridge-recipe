import 'package:hive_ce_flutter/hive_flutter.dart';

/// 온보딩 완료 상태를 Hive `settings` 박스에 영속화하는 저장소.
///
/// 온보딩은 최초 1회만 노출. 키가 존재하지 않으면 미완료(false)로 간주.
class OnboardingRepository {
  OnboardingRepository(this._box);

  final Box<dynamic> _box;

  static const String _completedKey = 'onboarding_completed';

  bool isCompleted() {
    return (_box.get(_completedKey, defaultValue: false) as bool?) ?? false;
  }

  Future<void> markCompleted() async {
    await _box.put(_completedKey, true);
  }

  /// 디버그 / 테스트 용도. 프로덕션 흐름에선 호출하지 않는다.
  Future<void> reset() async {
    await _box.delete(_completedKey);
  }
}
