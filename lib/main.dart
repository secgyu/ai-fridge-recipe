import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fridge_meal/app.dart';
import 'package:fridge_meal/core/network/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  await Hive.initFlutter();
  // Adapter 등록은 Supabase 도입 시 진행 (현재는 Recipe를 jsonEncode 문자열로 저장).
  await Hive.openBox<dynamic>('settings');
  // F-07: 즐겨찾기 레시피 캐시. key=recipe.id, value=jsonEncoded Recipe.
  await Hive.openBox<String>('favorites');
  // F-07: 만든 요리 기록. key=`${recipe.id}_${ms}`, value=jsonEncoded CookHistoryEntry.
  await Hive.openBox<String>('cook_history');

  runApp(const ProviderScope(child: FridgeMealApp()));
}
