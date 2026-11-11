/// Supabase connection settings.
///
/// Values come from `--dart-define` / `--dart-define-from-file`
/// (see `supabase.env.example.json` and `.vscode/launch.json`).
/// If nothing is passed, the OLD Supabase project is used as a fallback.
abstract final class SupabaseConfig {
  // Old project (kept for now, may no longer exist).
  static const _oldUrl = 'https://nprwbqrwqxeidvjxulbo.supabase.co';
  static const _oldAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wcndicXJ3cXhlaWR2anh1bGJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2Njk0OTksImV4cCI6MjA1NjI0NTQ5OX0.ATvP8OU5DlQsoAu0KiiV1Z5nY2f4sw6VwEa8i-DO8LM';

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _oldUrl,
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _oldAnonKey,
  );

  static bool get isOldProject => url == _oldUrl;
}
