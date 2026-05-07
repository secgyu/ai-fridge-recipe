import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fridge_meal/features/onboarding/data/repositories/onboarding_repository.dart';

part 'onboarding_provider.g.dart';

@riverpod
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepository(Hive.box<dynamic>('settings'));
}

@riverpod
class OnboardingCompleted extends _$OnboardingCompleted {
  @override
  bool build() {
    return ref.watch(onboardingRepositoryProvider).isCompleted();
  }

  Future<void> markCompleted() async {
    await ref.read(onboardingRepositoryProvider).markCompleted();
    state = true;
  }
}
