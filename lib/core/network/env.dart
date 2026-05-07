/// 빌드 시 주입되는 환경 변수.
///
/// 사용:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGc...
/// ```
///
/// API 키(OpenAI, 식약처)는 절대 여기 추가하지 말 것.
/// 외부 API 호출은 Supabase Edge Function 경유로만 한다.
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
