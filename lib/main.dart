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
  // Adapter 등록은 Day 3~4에서 모델과 함께 추가.
  // Hive.registerAdapter(IngredientAdapter());
  await Hive.openBox<dynamic>('settings');

  runApp(const ProviderScope(child: FridgeMealApp()));
}
