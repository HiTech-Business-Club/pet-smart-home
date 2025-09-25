class AppConfig {
  static const String appName = 'Pet Smart Home';
  static const String appVersion = '1.0.0';
  
  // Firebase Configuration
  static const String firebaseProjectId = 'pet-smart-home-app';
  
  // MQTT Configuration
  static const String mqttBrokerUrl = 'mqtt.pet-smart-home.com';
  static const int mqttPort = 8883;
  static const String mqttClientId = 'pet_smart_home_mobile';
  
  // API Configuration
  static const String baseApiUrl = 'https://api.pet-smart-home.com';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Device Configuration
  static const int maxDevicesPerUser = 10;
  static const int maxPetsPerUser = 20;
  
  // Feeding Configuration
  static const int minFeedingAmount = 10; // grammes
  static const int maxFeedingAmount = 500; // grammes
  static const int defaultFeedingAmount = 50; // grammes
  
  // Door Configuration
  static const Duration doorOpenDuration = Duration(seconds: 10);
  static const Duration rfidScanTimeout = Duration(seconds: 5);
  
  // Notification Configuration
  static const String notificationChannelId = 'pet_smart_home_notifications';
  static const String notificationChannelName = 'Pet Smart Home';
  static const String notificationChannelDescription = 'Notifications pour votre assistant domotique';
  
  // Storage Configuration
  static const String hiveBoxName = 'pet_smart_home_storage';
  static const String userPrefsKey = 'user_preferences';
  static const String deviceCacheKey = 'device_cache';
  static const String petCacheKey = 'pet_cache';
  
  // Security Configuration
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Colors
  static const int primaryColorValue = 0xFF2E7D32; // Vert foncé
  static const int secondaryColorValue = 0xFF4CAF50; // Vert clair
  static const int accentColorValue = 0xFFFF9800; // Orange
  static const int errorColorValue = 0xFFD32F2F; // Rouge
  static const int warningColorValue = 0xFFFFC107; // Jaune
  static const int successColorValue = 0xFF388E3C; // Vert succès
  
  // Development flags
  static const bool isDebugMode = true;
  static const bool enableLogging = true;
  static const bool enableCrashReporting = false;
}