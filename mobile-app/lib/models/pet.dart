import 'package:json_annotation/json_annotation.dart';

part 'pet.g.dart';

@JsonSerializable()
class Pet {
  final String id;
  final String name;
  final String species; // 'cat', 'dog', 'other'
  final String breed;
  final int age; // en mois
  final double weight; // en kg
  final String? photoUrl;
  final String? rfidTag;
  final String? bleMacAddress;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed = '',
    this.age = 0,
    this.weight = 0.0,
    this.photoUrl,
    this.rfidTag,
    this.bleMacAddress,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);
  Map<String, dynamic> toJson() => _$PetToJson(this);

  Pet copyWith({
    String? id,
    String? name,
    String? species,
    String? breed,
    int? age,
    double? weight,
    String? photoUrl,
    String? rfidTag,
    String? bleMacAddress,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      photoUrl: photoUrl ?? this.photoUrl,
      rfidTag: rfidTag ?? this.rfidTag,
      bleMacAddress: bleMacAddress ?? this.bleMacAddress,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utilitaires
  String get displayName => name.isNotEmpty ? name : 'Animal sans nom';
  
  String get speciesDisplayName {
    switch (species.toLowerCase()) {
      case 'cat':
        return 'Chat';
      case 'dog':
        return 'Chien';
      case 'rabbit':
        return 'Lapin';
      case 'bird':
        return 'Oiseau';
      default:
        return 'Autre';
    }
  }

  String get ageDisplayText {
    if (age < 12) {
      return '$age mois';
    } else {
      final years = age ~/ 12;
      final months = age % 12;
      if (months == 0) {
        return '$years an${years > 1 ? 's' : ''}';
      } else {
        return '$years an${years > 1 ? 's' : ''} et $months mois';
      }
    }
  }

  String get weightDisplayText => '${weight.toStringAsFixed(1)} kg';

  bool get hasRfidTag => rfidTag != null && rfidTag!.isNotEmpty;
  bool get hasBleMacAddress => bleMacAddress != null && bleMacAddress!.isNotEmpty;
  bool get hasIdentification => hasRfidTag || hasBleMacAddress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pet &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Pet{id: $id, name: $name, species: $species, breed: $breed, age: $age, weight: $weight}';
  }
}