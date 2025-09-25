import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

enum DeviceType {
  @JsonValue('feeder')
  feeder,
  @JsonValue('door')
  door,
  @JsonValue('combo')
  combo, // Appareil combiné distributeur + porte
}

enum DeviceStatus {
  @JsonValue('online')
  online,
  @JsonValue('offline')
  offline,
  @JsonValue('error')
  error,
  @JsonValue('maintenance')
  maintenance,
}

@JsonSerializable()
class Device {
  final String id;
  final String name;
  final DeviceType type;
  final String macAddress;
  final String firmwareVersion;
  final DeviceStatus status;
  final int batteryLevel; // 0-100
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DeviceConfig config;
  final Map<String, dynamic>? metadata;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.macAddress,
    this.firmwareVersion = '1.0.0',
    this.status = DeviceStatus.offline,
    this.batteryLevel = 100,
    this.isOnline = false,
    required this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    required this.config,
    this.metadata,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);

  Device copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? macAddress,
    String? firmwareVersion,
    DeviceStatus? status,
    int? batteryLevel,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
    DeviceConfig? config,
    Map<String, dynamic>? metadata,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      macAddress: macAddress ?? this.macAddress,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      config: config ?? this.config,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utilitaires
  String get typeDisplayName {
    switch (type) {
      case DeviceType.feeder:
        return 'Distributeur';
      case DeviceType.door:
        return 'Porte intelligente';
      case DeviceType.combo:
        return 'Système complet';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case DeviceStatus.online:
        return 'En ligne';
      case DeviceStatus.offline:
        return 'Hors ligne';
      case DeviceStatus.error:
        return 'Erreur';
      case DeviceStatus.maintenance:
        return 'Maintenance';
    }
  }

  bool get needsAttention => status == DeviceStatus.error || batteryLevel < 20;
  bool get isLowBattery => batteryLevel < 20;
  bool get isCriticalBattery => batteryLevel < 10;

  Duration get timeSinceLastSeen => DateTime.now().difference(lastSeen);
  
  String get lastSeenDisplayText {
    final duration = timeSinceLastSeen;
    if (duration.inMinutes < 1) {
      return 'À l\'instant';
    } else if (duration.inHours < 1) {
      return 'Il y a ${duration.inMinutes} min';
    } else if (duration.inDays < 1) {
      return 'Il y a ${duration.inHours}h';
    } else {
      return 'Il y a ${duration.inDays} jour${duration.inDays > 1 ? 's' : ''}';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Device{id: $id, name: $name, type: $type, status: $status, isOnline: $isOnline}';
  }
}

@JsonSerializable()
class DeviceConfig {
  // Configuration distributeur
  final bool feederEnabled;
  final int defaultFeedingAmount; // en grammes
  final bool antiJamEnabled;
  final int lowFoodThreshold; // en grammes
  
  // Configuration porte
  final bool doorEnabled;
  final int doorOpenDuration; // en secondes
  final bool autoCloseEnabled;
  final List<String> authorizedPetIds;
  final bool intrusionDetectionEnabled;
  
  // Configuration générale
  final bool notificationsEnabled;
  final int heartbeatInterval; // en secondes
  final Map<String, dynamic>? customSettings;

  DeviceConfig({
    this.feederEnabled = true,
    this.defaultFeedingAmount = 50,
    this.antiJamEnabled = true,
    this.lowFoodThreshold = 100,
    this.doorEnabled = true,
    this.doorOpenDuration = 10,
    this.autoCloseEnabled = true,
    this.authorizedPetIds = const [],
    this.intrusionDetectionEnabled = true,
    this.notificationsEnabled = true,
    this.heartbeatInterval = 60,
    this.customSettings,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) => _$DeviceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceConfigToJson(this);

  DeviceConfig copyWith({
    bool? feederEnabled,
    int? defaultFeedingAmount,
    bool? antiJamEnabled,
    int? lowFoodThreshold,
    bool? doorEnabled,
    int? doorOpenDuration,
    bool? autoCloseEnabled,
    List<String>? authorizedPetIds,
    bool? intrusionDetectionEnabled,
    bool? notificationsEnabled,
    int? heartbeatInterval,
    Map<String, dynamic>? customSettings,
  }) {
    return DeviceConfig(
      feederEnabled: feederEnabled ?? this.feederEnabled,
      defaultFeedingAmount: defaultFeedingAmount ?? this.defaultFeedingAmount,
      antiJamEnabled: antiJamEnabled ?? this.antiJamEnabled,
      lowFoodThreshold: lowFoodThreshold ?? this.lowFoodThreshold,
      doorEnabled: doorEnabled ?? this.doorEnabled,
      doorOpenDuration: doorOpenDuration ?? this.doorOpenDuration,
      autoCloseEnabled: autoCloseEnabled ?? this.autoCloseEnabled,
      authorizedPetIds: authorizedPetIds ?? this.authorizedPetIds,
      intrusionDetectionEnabled: intrusionDetectionEnabled ?? this.intrusionDetectionEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      heartbeatInterval: heartbeatInterval ?? this.heartbeatInterval,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}