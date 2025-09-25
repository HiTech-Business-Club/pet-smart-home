// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pet.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pet _$PetFromJson(Map<String, dynamic> json) => Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photoUrl'] as String?,
      rfidTag: json['rfidTag'] as String?,
      bleMacAddress: json['bleMacAddress'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PetToJson(Pet instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'species': instance.species,
      'breed': instance.breed,
      'age': instance.age,
      'weight': instance.weight,
      'photoUrl': instance.photoUrl,
      'rfidTag': instance.rfidTag,
      'bleMacAddress': instance.bleMacAddress,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
    };
