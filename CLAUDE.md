# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Instant Explore (隨性探點) is a location-based smart recommendation Flutter app that helps users discover nearby places through AI-powered suggestions and group voting features. The app integrates with Google Places API and Google Maps API to provide real-time location recommendations.

## Architecture

### Feature-First Structure
The project follows a **Feature-First** architecture with Clean Architecture principles:

```
lib/
├── core/           # Shared infrastructure (config, utils, services)
├── shared/         # Reusable widgets and models
└── features/       # Feature modules (location, places, voting, navigation)
    └── [feature]/
        ├── models/     # Data entities and repository interfaces
        ├── services/   # Business logic implementation
        ├── widgets/    # Feature-specific UI components
        └── screens/    # Screen-level widgets
```

### State Management
Uses **Riverpod** with StateNotifier pattern for immutable state management:
- StateNotifier classes extend StateNotifier<StateClass>
- Immutable state classes with copyWith methods
- Providers defined using StateNotifierProvider

### API Integration
- Google Places API (New) for location search and details
- Google Maps SDK for map display and interaction
- Google Directions API for navigation routing
- All API keys managed through environment variables using String.fromEnvironment()

## Development Commands

### Environment Setup
API keys must be set as environment variables. Never hard-code API keys in source code.

```bash
# Create .env file (not committed to git)
GOOGLE_PLACES_API_KEY=your_key_here
GOOGLE_MAPS_API_KEY=your_key_here
```

### Running the App
```bash
# Use the development script (loads .env and passes all environment variables)
./scripts/run_dev.sh
```

### Testing
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test/

# Generate test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Code Quality
```bash
# Lint code
flutter analyze

# Format code
dart format .

# Security check for hardcoded API keys
grep -r "AIza[A-Za-z0-9_-]\{35\}" lib/ || echo "No hardcoded API keys found"
```

### Building
```bash
# Android
GOOGLE_MAPS_API_KEY="your_api_key_here" fvm flutter build apk --release \
  --dart-define=GOOGLE_PLACES_API_KEY="your_api_key_here" \
  --dart-define=GOOGLE_MAPS_API_KEY="your_api_key_here"

# iOS
GOOGLE_MAPS_API_KEY="your_api_key_here" fvm flutter build ios --release \
  --dart-define=GOOGLE_PLACES_API_KEY="your_api_key_here" \
  --dart-define=GOOGLE_MAPS_API_KEY="your_api_key_here"
```

## Key Technical Decisions

### Security
- All API keys use environment variables with String.fromEnvironment()
- ApiKeys class validates configuration at startup
- .env files are gitignored
- Security checks prevent hardcoded keys in source

### Testing Framework
- Uses **mocktail** instead of mockito for null safety compatibility
- Unit tests in test/unit/
- Widget tests in test/widget/
- Integration tests in integration_test/

### API Cost Optimization
- Implements caching strategies to reduce API calls
- Uses Field Masking to limit returned data
- Batch processing for multiple API requests
- Smart retry mechanisms with exponential backoff

## Documentation Structure

- `doc/ARCHITECTURE.md` - Detailed technical architecture
- `doc/DEVELOPMENT.md` - Development environment setup and guidelines
- `doc/API_INTEGRATION.md` - Google APIs integration details with security practices
- `doc/USER_GUIDE.md` - End-user functionality guide
- `doc/PLAN.md` - Detailed development roadmap with 240+ tasks

## Important Notes

- This is currently a documentation-only project (no actual Flutter code exists yet)
- The project structure and patterns are designed for a production-ready Flutter application
- When implementing features, follow the established Feature-First architecture
- Always use Riverpod StateNotifier pattern for state management
- Maintain security practices around API key management
- Use mocktail for mocking in tests