import 'package:json_annotation/json_annotation.dart';

part 'feeding_schedule.g.dart';

@JsonSerializable()
class FeedingSchedule {
  final String id;
  final String deviceId;
  final String petId;
  final String name;
  final List<FeedingTime> feedingTimes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  FeedingSchedule({
    required this.id,
    required this.deviceId,
    required this.petId,
    required this.name,
    required this.feedingTimes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory FeedingSchedule.fromJson(Map<String, dynamic> json) => _$FeedingScheduleFromJson(json);
  Map<String, dynamic> toJson() => _$FeedingScheduleToJson(this);

  FeedingSchedule copyWith({
    String? id,
    String? deviceId,
    String? petId,
    String? name,
    List<FeedingTime>? feedingTimes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FeedingSchedule(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      feedingTimes: feedingTimes ?? this.feedingTimes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utilitaires
  int get totalDailyAmount => feedingTimes.fold(0, (sum, time) => sum + time.amount);
  int get activeFeedingCount => feedingTimes.where((time) => time.isActive).length;
  
  FeedingTime? get nextFeeding {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final activeTimes = feedingTimes.where((time) => time.isActive).toList();
    activeTimes.sort((a, b) => a.time.compareTo(b.time));
    
    for (final feedingTime in activeTimes) {
      final feedingDateTime = DateTime(
        today.year,
        today.month,
        today.day,
        feedingTime.time.hour,
        feedingTime.time.minute,
      );
      
      if (feedingDateTime.isAfter(now)) {
        return feedingTime;
      }
    }
    
    // Si aucun repas aujourd'hui, retourner le premier de demain
    if (activeTimes.isNotEmpty) {
      return activeTimes.first;
    }
    
    return null;
  }

  Duration? get timeUntilNextFeeding {
    final next = nextFeeding;
    if (next == null) return null;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var feedingDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      next.time.hour,
      next.time.minute,
    );
    
    // Si c'est pour demain
    if (feedingDateTime.isBefore(now)) {
      feedingDateTime = feedingDateTime.add(const Duration(days: 1));
    }
    
    return feedingDateTime.difference(now);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FeedingSchedule{id: $id, name: $name, petId: $petId, feedingTimes: ${feedingTimes.length}, isActive: $isActive}';
  }
}

@JsonSerializable()
class FeedingTime {
  final String id;
  final TimeOfDay time;
  final int amount; // en grammes
  final List<int> daysOfWeek; // 1=Lundi, 7=Dimanche
  final bool isActive;
  final String? note;

  FeedingTime({
    required this.id,
    required this.time,
    required this.amount,
    this.daysOfWeek = const [1, 2, 3, 4, 5, 6, 7], // Tous les jours par défaut
    this.isActive = true,
    this.note,
  });

  factory FeedingTime.fromJson(Map<String, dynamic> json) => _$FeedingTimeFromJson(json);
  Map<String, dynamic> toJson() => _$FeedingTimeToJson(this);

  FeedingTime copyWith({
    String? id,
    TimeOfDay? time,
    int? amount,
    List<int>? daysOfWeek,
    bool? isActive,
    String? note,
  }) {
    return FeedingTime(
      id: id ?? this.id,
      time: time ?? this.time,
      amount: amount ?? this.amount,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }

  // Méthodes utilitaires
  String get timeDisplayText {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get amountDisplayText => '${amount}g';

  String get daysDisplayText {
    if (daysOfWeek.length == 7) {
      return 'Tous les jours';
    } else if (daysOfWeek.length == 5 && 
               daysOfWeek.contains(1) && 
               daysOfWeek.contains(2) && 
               daysOfWeek.contains(3) && 
               daysOfWeek.contains(4) && 
               daysOfWeek.contains(5)) {
      return 'En semaine';
    } else if (daysOfWeek.length == 2 && 
               daysOfWeek.contains(6) && 
               daysOfWeek.contains(7)) {
      return 'Week-end';
    } else {
      const dayNames = ['', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return daysOfWeek.map((day) => dayNames[day]).join(', ');
    }
  }

  bool isScheduledForToday() {
    final today = DateTime.now().weekday;
    return daysOfWeek.contains(today);
  }

  bool isScheduledForDay(DateTime date) {
    return daysOfWeek.contains(date.weekday);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedingTime &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FeedingTime{id: $id, time: $timeDisplayText, amount: $amount, days: $daysDisplayText, isActive: $isActive}';
  }
}

// Classe utilitaire pour TimeOfDay JSON serialization
@JsonSerializable()
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromJson(Map<String, dynamic> json) => _$TimeOfDayFromJson(json);
  Map<String, dynamic> toJson() => _$TimeOfDayToJson(this);

  factory TimeOfDay.now() {
    final now = DateTime.now();
    return TimeOfDay(hour: now.hour, minute: now.minute);
  }

  int compareTo(TimeOfDay other) {
    if (hour != other.hour) {
      return hour.compareTo(other.hour);
    }
    return minute.compareTo(other.minute);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}