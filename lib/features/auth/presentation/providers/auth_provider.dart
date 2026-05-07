import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository(Hive.box<dynamic>('settings'));
}

/// 현재 인증 상태를 동기적으로 노출.
///
/// Supabase Auth 통합 시 `build()` 내부에서 onAuthStateChange를
/// 구독해 자동 업데이트하도록 확장한다.
@riverpod
class AuthState extends _$AuthState {
  @override
  AuthMode build() {
    return ref.watch(authRepositoryProvider).getMode();
  }

  Future<void> continueAsGuest() async {
    await ref.read(authRepositoryProvider).setMode(AuthMode.guest);
    state = AuthMode.guest;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).reset();
    state = AuthMode.unauthenticated;
  }
}
