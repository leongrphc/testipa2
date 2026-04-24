import 'package:flutter/foundation.dart';

class AnalyticsService {
  const AnalyticsService();

  void track(String name, [Map<String, Object?> properties = const {}]) {
    if (kReleaseMode) {
      return;
    }
    debugPrint('[analytics] $name $properties');
  }
}

const analyticsService = AnalyticsService();
