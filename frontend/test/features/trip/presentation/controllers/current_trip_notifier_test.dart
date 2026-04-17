import 'package:context_app/features/trip/providers/trip_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CurrentTripIdNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is null when no saved value exists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentTripIdProvider), isNull);
    });

    test('hydrates state from SharedPreferences on first read', () async {
      SharedPreferences.setMockInitialValues({
        'current_trip_id': 'trip-99',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 觸發 build() 啟動非同步 _loadFromPrefs()
      container.read(currentTripIdProvider);
      // 等一輪 microtask + SharedPreferences 的非同步讀取
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentTripIdProvider), 'trip-99');
    });

    test('setCurrentTripId updates state and persists to SharedPreferences',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(currentTripIdProvider.notifier)
          .setCurrentTripId('trip-1');

      expect(container.read(currentTripIdProvider), 'trip-1');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_trip_id'), 'trip-1');
    });

    test('clear removes the saved value and resets state', () async {
      SharedPreferences.setMockInitialValues({
        'current_trip_id': 'trip-1',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(currentTripIdProvider.notifier).clear();

      expect(container.read(currentTripIdProvider), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_trip_id'), isNull);
    });
  });
}
