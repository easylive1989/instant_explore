# Integration Tests with Patrol

This directory contains E2E (end-to-end) integration tests for the Travel Diary app using [Patrol](https://patrol.leancode.co/).

## Test Coverage

### 1. Authentication Flow (`auth_flow_test.dart`)
- Login screen display verification
- Google Sign-In flow
- Logout functionality
- Navigation after authentication

### 2. Diary Creation and Viewing (`diary_create_and_view_test.dart`)
- Create diary entry with title and content
- Create diary entry with images
- Form validation (required fields)
- View diary details
- List display after creation

### 3. Tag Filtering (`diary_tag_filter_test.dart`)
- Filter diary entries by tags
- Apply and clear filters
- Create diary with tags and verify filtering

### 4. Edit and Delete (`diary_edit_delete_test.dart`)
- Edit existing diary entry
- Save changes and verify updates
- Delete diary entry with confirmation
- Cancel deletion

## Prerequisites

### 1. Install Patrol CLI

```bash
# Install Patrol CLI globally
dart pub global activate patrol_cli
```

### 2. Set up Local Supabase (for testing)

These tests are designed to work with a local Supabase instance. Follow these steps:

#### Install Supabase CLI

```bash
# macOS
brew install supabase/tap/supabase

# Windows (using Scoop)
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Linux
brew install supabase/tap/supabase
```

#### Start Local Supabase

```bash
# Navigate to your project directory
cd /path/to/instant_explore

# Initialize Supabase (first time only)
supabase init

# Start local Supabase
supabase start
```

This will start local Supabase services on:
- API URL: `http://localhost:54321`
- Studio URL: `http://localhost:54323`
- Default anon key will be displayed in the output

#### Configure Test Environment

Edit `integration_test/helpers/test_config.dart` to use your local Supabase:

```dart
static const String localSupabaseUrl = 'http://localhost:54321';
static const String localSupabaseAnonKey = 'your-local-anon-key-from-supabase-start';
```

### 3. Environment Variables

When running tests, you need to provide environment variables for API keys:

```bash
# Required environment variables
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-local-anon-key
GOOGLE_MAPS_API_KEY=your-google-maps-key
GOOGLE_DIRECTIONS_API_KEY=your-google-directions-key
GOOGLE_WEB_CLIENT_ID=your-google-web-client-id
GOOGLE_IOS_CLIENT_ID=your-google-ios-client-id (for iOS tests)
```

## Running Tests

### Run All Tests

```bash
# Android
patrol test --target integration_test --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=your-key

# iOS
patrol test --target integration_test --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=your-key --dart-define=GOOGLE_IOS_CLIENT_ID=your-ios-client-id
```

### Run Specific Test File

```bash
patrol test --target integration_test/auth_flow_test.dart --dart-define=SUPABASE_URL=http://localhost:54321 --dart-define=SUPABASE_ANON_KEY=your-key
```

### Run with Environment File

Create a `.env` file with your configuration:

```bash
# .env file
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GOOGLE_MAPS_API_KEY=AIza...
GOOGLE_DIRECTIONS_API_KEY=AIza...
GOOGLE_WEB_CLIENT_ID=123456789-....apps.googleusercontent.com
```

Then use a script to load env vars:

```bash
#!/bin/bash
# scripts/run_tests.sh

source .env

patrol test \
  --target integration_test \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY \
  --dart-define=GOOGLE_DIRECTIONS_API_KEY=$GOOGLE_DIRECTIONS_API_KEY \
  --dart-define=GOOGLE_WEB_CLIENT_ID=$GOOGLE_WEB_CLIENT_ID
```

## Test Configuration

### Test Settings

You can configure test behavior in `helpers/test_config.dart`:

```dart
class TestConfig {
  // Use local Supabase instance
  static const bool useLocalSupabase = true;

  // Take screenshots during tests
  static const bool takeScreenshots = true;

  // Enable debug output
  static const bool debug = true;

  // Adjust timeouts
  static const Duration shortDelay = Duration(milliseconds: 500);
  static const Duration mediumDelay = Duration(seconds: 1);
  static const Duration longDelay = Duration(seconds: 3);
}
```

### Test Data

Tests create and clean up their own test data:
- Test diary entries are created with titles starting with "測試" (test)
- All test data is deleted after tests complete
- Tests are designed to be idempotent

## Troubleshooting

### Common Issues

#### 1. "flutter: command not found"

Make sure Flutter is in your PATH:

```bash
export PATH="$PATH:/path/to/flutter/bin"
```

#### 2. Tests fail with Supabase connection errors

- Verify local Supabase is running: `supabase status`
- Check the API URL and anon key in `test_config.dart`
- Ensure your database schema is set up correctly

#### 3. Google Sign-In fails in tests

- For E2E tests with real Google auth, you may need to:
  - Configure test accounts in Google Cloud Console
  - Handle OAuth flows in tests using Patrol's native automation
  - Or mock authentication for faster tests

#### 4. Image picker tests fail

- Grant photo permissions manually first time
- Ensure you have test images in the simulator/emulator
- Consider mocking the image picker for consistent results

#### 5. Tests are flaky

- Increase delays in `test_config.dart`
- Add more explicit waits for network operations
- Use `$.pumpAndSettle()` more frequently
- Check for race conditions in state updates

## Screenshots

Screenshots are automatically saved during test execution if `TestConfig.takeScreenshots` is `true`.

Location: `build/app/outputs/patrol_screenshots/`

## CI/CD Integration

To run tests in CI/CD, see `.github/workflows/ci.yml` for the configuration.

Key points for CI:
- Use GitHub Secrets for API keys
- Run tests against local Supabase or test instance
- Generate and upload test reports
- Upload screenshots as artifacts

## Writing New Tests

### Test Structure

```dart
import 'package:patrol/patrol.dart';
import 'helpers/test_config.dart';
import 'helpers/test_helpers.dart';

void main() {
  patrolTest(
    'Test description',
    ($) async {
      // Arrange: Set up test conditions
      await $.pumpAndSettle();

      // Act: Perform actions
      await $(SomeWidget).tap();

      // Assert: Verify results
      expect($(ResultWidget), findsOneWidget);

      // Take screenshot if needed
      if (TestConfig.takeScreenshots) {
        await TestHelpers.takeScreenshot($, 'test_step_name');
      }
    },
  );
}
```

### Best Practices

1. **Use Helper Methods**: Leverage `TestHelpers` for common operations
2. **Clean Up**: Always delete test data after tests
3. **Screenshots**: Take screenshots at key steps for debugging
4. **Wait for Animations**: Use `$.pumpAndSettle()` after interactions
5. **Explicit Waits**: Add delays for network operations
6. **Descriptive Names**: Use clear test and screenshot names
7. **Idempotency**: Tests should be runnable multiple times
8. **Independence**: Tests should not depend on each other

## Resources

- [Patrol Documentation](https://patrol.leancode.co/)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Supabase Local Development](https://supabase.com/docs/guides/cli/local-development)

## Support

If you encounter issues with the tests, please:
1. Check the troubleshooting section above
2. Review the test logs and screenshots
3. Verify your environment setup
4. Open an issue in the repository
