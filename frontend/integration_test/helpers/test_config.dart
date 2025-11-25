/// Test configuration for integration tests
class TestConfig {
  /// Whether to use local Supabase instance
  static const bool useLocalSupabase = true;

  /// Local Supabase URL
  static const String localSupabaseUrl = 'http://localhost:54321';

  /// Local Supabase Anon Key
  /// This is the default anon key for local Supabase
  static const String localSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  /// Test user credentials
  static const String testUserEmail = 'test@example.com';
  static const String testUserPassword = 'TestPassword123!';

  /// Test delays
  static const Duration shortDelay = Duration(milliseconds: 500);
  static const Duration mediumDelay = Duration(seconds: 1);
  static const Duration longDelay = Duration(seconds: 3);

  /// Network timeouts
  static const Duration networkTimeout = Duration(seconds: 30);

  /// Get Supabase URL based on configuration
  static String get supabaseUrl {
    return useLocalSupabase
        ? localSupabaseUrl
        : const String.fromEnvironment(
            'SUPABASE_URL',
            defaultValue: '',
          );
  }

  /// Get Supabase anon key based on configuration
  static String get supabaseAnonKey {
    return useLocalSupabase
        ? localSupabaseAnonKey
        : const String.fromEnvironment(
            'SUPABASE_ANON_KEY',
            defaultValue: '',
          );
  }

  /// Whether to take screenshots during tests
  static const bool takeScreenshots = true;

  /// Whether to print debug information
  static const bool debug = true;
}
