// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'access_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessLog _$AccessLogFromJson(Map<String, dynamic> json) => AccessLog(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      petId: json['petId'] as String?,
      direction: $enumDecode(_$AccessDirectionEnumMap, json['direction']),
      method: $enumDecode(_$AccessMethodEnumMap, json['method']),
      status: $enumDecode(_$AccessStatusEnumMap, json['status']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      rfidTag: json['rfidTag'] as String?,
      bleMacAddress: json['bleMacAddress'] as String?,
      errorMessage: json['errorMessage'] as String?,
      doorOpenDuration: (json['doorOpenDuration'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$AccessLogToJson(AccessLog instance) => <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'petId': instance.petId,
      'direction': _$AccessDirectionEnumMap[instance.direction]!,
      'method': _$AccessMethodEnumMap[instance.method]!,
      'status': _$AccessStatusEnumMap[instance.status]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'rfidTag': instance.rfidTag,
      'bleMacAddress': instance.bleMacAddress,
      'errorMessage': instance.errorMessage,
      'doorOpenDuration': instance.doorOpenDuration,
      'metadata': instance.metadata,
    };

const _$AccessDirectionEnumMap = {
  AccessDirection.entry: 'entry',
  AccessDirection.exit: 'exit',
};

const _$AccessMethodEnumMap = {
  AccessMethod.rfid: 'rfid',
  AccessMethod.ble: 'ble',
  AccessMethod.manual: 'manual',
  AccessMethod.scheduled: 'scheduled',
};

const _$AccessStatusEnumMap = {
  AccessStatus.success: 'success',
  AccessStatus.denied: 'denied',
  AccessStatus.error: 'error',
  AccessStatus.timeout: 'timeout',
};

AccessStats _$AccessStatsFromJson(Map<String, dynamic> json) => AccessStats(
      totalAccesses: (json['totalAccesses'] as num).toInt(),
      successfulAccesses: (json['successfulAccesses'] as num).toInt(),
      deniedAccesses: (json['deniedAccesses'] as num).toInt(),
      errorAccesses: (json['errorAccesses'] as num).toInt(),
      entriesCount: (json['entriesCount'] as num).toInt(),
      exitsCount: (json['exitsCount'] as num).toInt(),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      accessesByPet: Map<String, int>.from(json['accessesByPet'] as Map),
      accessesByHour: Map<String, int>.from(json['accessesByHour'] as Map),
      accessesByDay: Map<String, int>.from(json['accessesByDay'] as Map),
    );

Map<String, dynamic> _$AccessStatsToJson(AccessStats instance) =>
    <String, dynamic>{
      'totalAccesses': instance.totalAccesses,
      'successfulAccesses': instance.successfulAccesses,
      'deniedAccesses': instance.deniedAccesses,
      'errorAccesses': instance.errorAccesses,
      'entriesCount': instance.entriesCount,
      'exitsCount': instance.exitsCount,
      'periodStart': instance.periodStart.toIso8601String(),
      'periodEnd': instance.periodEnd.toIso8601String(),
      'accessesByPet': instance.accessesByPet,
      'accessesByHour': instance.accessesByHour,
      'accessesByDay': instance.accessesByDay,
    };
