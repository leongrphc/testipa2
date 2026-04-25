import 'package:flutter/foundation.dart';

class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nsylscurmpeeibjhmnre.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zeWxzY3VybXBlZWliamhtbnJlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NzY0MTYsImV4cCI6MjA5MjE1MjQxNn0._8LW-bTs19uCbTE2B8Mj5hXmi_Nwm9E1mrc4FHIBnxk',
  );

  static String get apiBaseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (configuredBaseUrl.isNotEmpty) {
      return configuredBaseUrl;
    }

    // LAN IP - PC'deki backend'e erişim için (aynı WiFi'de olmalı)
    return 'http://192.168.1.105:3000';
  }

  static bool get isSupabaseConfigured {
    return !supabaseUrl.contains('YOUR_SUPABASE_URL') &&
        !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
  }

  static List<String> get missingConfiguration {
    return [
      if (supabaseUrl.contains('YOUR_SUPABASE_URL')) 'SUPABASE_URL',
      if (supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY'))
        'SUPABASE_ANON_KEY',
    ];
  }

  static bool get isLocalApiBaseUrl {
    return apiBaseUrl.contains('localhost') ||
        apiBaseUrl.contains('127.0.0.1') ||
        apiBaseUrl.contains('10.0.2.2');
  }

  static const admobAndroidAppId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713',
  );

  static const admobIosAppId = String.fromEnvironment(
    'ADMOB_IOS_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~1458002511',
  );

  static String get rewardedAdUnitId {
    const configured = String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID');
    if (configured.isNotEmpty) {
      return configured;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ca-app-pub-3940256099942544/1712485313';
      case TargetPlatform.android:
        return 'ca-app-pub-3940256099942544/5224354917';
      default:
        return 'ca-app-pub-3940256099942544/5224354917';
    }
  }
}
