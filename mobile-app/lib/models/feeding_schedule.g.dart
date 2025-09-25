// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feeding_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedingSchedule _$FeedingScheduleFromJson(Map<String, dynamic> json) =>
    FeedingSchedule(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      petId: json['petId'] as String,
      name: json['name'] as String,
      feedingTimes: (json['feedingTimes'] as List<dynamic>)
          .map((e) => FeedingTime.fromJson(e as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$FeedingScheduleToJson(FeedingSchedule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'petId': instance.petId,
      'name': instance.name,
      'feedingTimes': instance.feedingTimes,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
    };

FeedingTime _$FeedingTimeFromJson(Map<String, dynamic> json) => FeedingTime(
      id: json['id'] as String,
      time: TimeOfDay.fromJson(json['time'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toInt(),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5, 6, 7],
      isActive: json['isActive'] as bool? ?? true,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$FeedingTimeToJson(FeedingTime instance) =>
    <String, dynamic>{
      'id': instance.id,
      'time': instance.time,
      'amount': instance.amount,
      'daysOfWeek': instance.daysOfWeek,
      'isActive': instance.isActive,
      'note': instance.note,
    };

TimeOfDay _$TimeOfDayFromJson(Map<String, dynamic> json) => TimeOfDay(
      hour: (json['hour'] as num).toInt(),
      minute: (json['minute'] as num).toInt(),
    );

Map<String, dynamic> _$TimeOfDayToJson(TimeOfDay instance) => <String, dynamic>{
      'hour': instance.hour,
      'minute': instance.minute,
    };
