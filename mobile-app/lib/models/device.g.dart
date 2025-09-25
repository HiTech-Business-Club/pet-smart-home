// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$DeviceTypeEnumMap, json['type']),
      macAddress: json['macAddress'] as String,
      firmwareVersion: json['firmwareVersion'] as String? ?? '1.0.0',
      status: $enumDecodeNullable(_$DeviceStatusEnumMap, json['status']) ??
          DeviceStatus.offline,
      batteryLevel: (json['batteryLevel'] as num?)?.toInt() ?? 100,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: DateTime.parse(json['lastSeen'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      config: DeviceConfig.fromJson(json['config'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$DeviceTypeEnumMap[instance.type]!,
      'macAddress': instance.macAddress,
      'firmwareVersion': instance.firmwareVersion,
      'status': _$DeviceStatusEnumMap[instance.status]!,
      'batteryLevel': instance.batteryLevel,
      'isOnline': instance.isOnline,
      'lastSeen': instance.lastSeen.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'config': instance.config,
      'metadata': instance.metadata,
    };

const _$DeviceTypeEnumMap = {
  DeviceType.feeder: 'feeder',
  DeviceType.door: 'door',
  DeviceType.combo: 'combo',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.online: 'online',
  DeviceStatus.offline: 'offline',
  DeviceStatus.error: 'error',
  DeviceStatus.maintenance: 'maintenance',
};

DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) => DeviceConfig(
      feederEnabled: json['feederEnabled'] as bool? ?? true,
      defaultFeedingAmount:
          (json['defaultFeedingAmount'] as num?)?.toInt() ?? 50,
      antiJamEnabled: json['antiJamEnabled'] as bool? ?? true,
      lowFoodThreshold: (json['lowFoodThreshold'] as num?)?.toInt() ?? 100,
      doorEnabled: json['doorEnabled'] as bool? ?? true,
      doorOpenDuration: (json['doorOpenDuration'] as num?)?.toInt() ?? 10,
      autoCloseEnabled: json['autoCloseEnabled'] as bool? ?? true,
      authorizedPetIds: (json['authorizedPetIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      intrusionDetectionEnabled:
          json['intrusionDetectionEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      heartbeatInterval: (json['heartbeatInterval'] as num?)?.toInt() ?? 60,
      customSettings: json['customSettings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DeviceConfigToJson(DeviceConfig instance) =>
    <String, dynamic>{
      'feederEnabled': instance.feederEnabled,
      'defaultFeedingAmount': instance.defaultFeedingAmount,
      'antiJamEnabled': instance.antiJamEnabled,
      'lowFoodThreshold': instance.lowFoodThreshold,
      'doorEnabled': instance.doorEnabled,
      'doorOpenDuration': instance.doorOpenDuration,
      'autoCloseEnabled': instance.autoCloseEnabled,
      'authorizedPetIds': instance.authorizedPetIds,
      'intrusionDetectionEnabled': instance.intrusionDetectionEnabled,
      'notificationsEnabled': instance.notificationsEnabled,
      'heartbeatInterval': instance.heartbeatInterval,
      'customSettings': instance.customSettings,
    };
