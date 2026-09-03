import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final mockLocationServiceProvider = Provider<MockLocationService>((ref) {
  return MockLocationService();
});

class MockLocationNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDetected(bool value) {
    state = value;
  }
}

final isMockLocationDetectedProvider = NotifierProvider<MockLocationNotifier, bool>(() {
  return MockLocationNotifier();
});

class MockLocationService {
  static const MethodChannel _channel = MethodChannel('com.gawe.gaweflutter/anti_mock_location');

  /// Detects if Fake GPS / Mock Location is currently active
  Future<bool> checkIsMockLocation() async {
    // 1. Native Android detection via Platform Channel (checks fresh last known location)
    if (Platform.isAndroid) {
      try {
        final bool? nativeMock = await _channel.invokeMethod<bool>('checkMockLocation');
        if (nativeMock == true) {
          return true;
        }
      } catch (_) {
        // Fallback to geolocator
      }
    }

    // 2. Geolocator Position inspection (live position check)
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always || hasPermission == LocationPermission.whileInUse) {
        final Position currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
        if (currentPos.isMocked) {
          return true;
        }

        final Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null && lastPos.isMocked) {
          final diff = DateTime.now().difference(lastPos.timestamp);
          if (diff.inSeconds < 30) {
            return true;
          }
        }
      }
    } catch (_) {
      // Ignore if location can't be fetched immediately
    }

    return false;
  }
}
