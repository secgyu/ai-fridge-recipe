import 'package:hive_ce_flutter/hive_flutter.dart';

/// 인증 상태.
enum AuthMode {
  /// 로그인 화면 노출 대상.
  unauthenticated,

  /// "가입 없이 둘러보기" 모드. 메인 진입은 가능하지만 일부 기능 제한 가능.
  guest,

  /// 정식 로그인 (Supabase Auth 통합 후 사용).
  authenticated,
}

/// 인증 상태를 Hive `settings` 박스에 영속화.
///
/// 추후 Supabase Auth가 도입되면 이 저장소는 보조적인 역할만 하고
/// 주 진입점은 `Supabase.instance.client.auth.onAuthStateChange` 가 된다.
class AuthRepository {
  AuthRepository(this._box);

  final Box<dynamic> _box;

  static const String _modeKey = 'auth_mode';

  AuthMode getMode() {
    final String? raw = _box.get(_modeKey) as String?;
    if (raw == null) return AuthMode.unauthenticated;
    return AuthMode.values.firstWhere(
      (AuthMode m) => m.name == raw,
      orElse: () => AuthMode.unauthenticated,
    );
  }

  Future<void> setMode(AuthMode mode) async {
    await _box.put(_modeKey, mode.name);
  }

  /// 로그아웃 / 디버그 리셋용.
  Future<void> reset() async {
    await _box.delete(_modeKey);
  }
}
