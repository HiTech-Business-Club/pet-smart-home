import 'package:json_annotation/json_annotation.dart';

part 'access_log.g.dart';

enum AccessDirection {
  @JsonValue('entry')
  entry,
  @JsonValue('exit')
  exit,
}

enum AccessMethod {
  @JsonValue('rfid')
  rfid,
  @JsonValue('ble')
  ble,
  @JsonValue('manual')
  manual,
  @JsonValue('scheduled')
  scheduled,
}

enum AccessStatus {
  @JsonValue('success')
  success,
  @JsonValue('denied')
  denied,
  @JsonValue('error')
  error,
  @JsonValue('timeout')
  timeout,
}

@JsonSerializable()
class AccessLog {
  final String id;
  final String deviceId;
  final String? petId;
  final AccessDirection direction;
  final AccessMethod method;
  final AccessStatus status;
  final DateTime timestamp;
  final String? rfidTag;
  final String? bleMacAddress;
  final String? errorMessage;
  final int? doorOpenDuration; // en secondes
  final Map<String, dynamic>? metadata;

  AccessLog({
    required this.id,
    required this.deviceId,
    this.petId,
    required this.direction,
    required this.method,
    required this.status,
    required this.timestamp,
    this.rfidTag,
    this.bleMacAddress,
    this.errorMessage,
    this.doorOpenDuration,
    this.metadata,
  });

  factory AccessLog.fromJson(Map<String, dynamic> json) => _$AccessLogFromJson(json);
  Map<String, dynamic> toJson() => _$AccessLogToJson(this);

  AccessLog copyWith({
    String? id,
    String? deviceId,
    String? petId,
    AccessDirection? direction,
    AccessMethod? method,
    AccessStatus? status,
    DateTime? timestamp,
    String? rfidTag,
    String? bleMacAddress,
    String? errorMessage,
    int? doorOpenDuration,
    Map<String, dynamic>? metadata,
  }) {
    return AccessLog(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      petId: petId ?? this.petId,
      direction: direction ?? this.direction,
      method: method ?? this.method,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      rfidTag: rfidTag ?? this.rfidTag,
      bleMacAddress: bleMacAddress ?? this.bleMacAddress,
      errorMessage: errorMessage ?? this.errorMessage,
      doorOpenDuration: doorOpenDuration ?? this.doorOpenDuration,
      metadata: metadata ?? this.metadata,
    );
  }

  // Méthodes utilitaires
  String get directionDisplayName {
    switch (direction) {
      case AccessDirection.entry:
        return 'Entrée';
      case AccessDirection.exit:
        return 'Sortie';
    }
  }

  String get methodDisplayName {
    switch (method) {
      case AccessMethod.rfid:
        return 'RFID';
      case AccessMethod.ble:
        return 'Bluetooth';
      case AccessMethod.manual:
        return 'Manuel';
      case AccessMethod.scheduled:
        return 'Programmé';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case AccessStatus.success:
        return 'Succès';
      case AccessStatus.denied:
        return 'Refusé';
      case AccessStatus.error:
        return 'Erreur';
      case AccessStatus.timeout:
        return 'Timeout';
    }
  }

  bool get isSuccessful => status == AccessStatus.success;
  bool get isUnauthorized => status == AccessStatus.denied;
  bool get hasError => status == AccessStatus.error || status == AccessStatus.timeout;

  String get timestampDisplayText {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String get fullTimestampText {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
           '${timestamp.month.toString().padLeft(2, '0')}/'
           '${timestamp.year} à '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String get identificationMethod {
    if (rfidTag != null && rfidTag!.isNotEmpty) {
      return 'RFID: ${rfidTag!.substring(0, 8)}...';
    } else if (bleMacAddress != null && bleMacAddress!.isNotEmpty) {
      return 'BLE: ${bleMacAddress!.substring(0, 8)}...';
    } else {
      return methodDisplayName;
    }
  }

  String? get durationDisplayText {
    if (doorOpenDuration == null) return null;
    if (doorOpenDuration! < 60) {
      return '${doorOpenDuration}s';
    } else {
      final minutes = doorOpenDuration! ~/ 60;
      final seconds = doorOpenDuration! % 60;
      return '${minutes}min ${seconds}s';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AccessLog{id: $id, deviceId: $deviceId, petId: $petId, direction: $direction, method: $method, status: $status, timestamp: $timestamp}';
  }
}

// Classe pour les statistiques d'accès
@JsonSerializable()
class AccessStats {
  final int totalAccesses;
  final int successfulAccesses;
  final int deniedAccesses;
  final int errorAccesses;
  final int entriesCount;
  final int exitsCount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, int> accessesByPet;
  final Map<String, int> accessesByHour;
  final Map<String, int> accessesByDay;

  AccessStats({
    required this.totalAccesses,
    required this.successfulAccesses,
    required this.deniedAccesses,
    required this.errorAccesses,
    required this.entriesCount,
    required this.exitsCount,
    required this.periodStart,
    required this.periodEnd,
    required this.accessesByPet,
    required this.accessesByHour,
    required this.accessesByDay,
  });

  factory AccessStats.fromJson(Map<String, dynamic> json) => _$AccessStatsFromJson(json);
  Map<String, dynamic> toJson() => _$AccessStatsToJson(this);

  factory AccessStats.fromLogs(List<AccessLog> logs, DateTime start, DateTime end) {
    final filteredLogs = logs.where((log) => 
        log.timestamp.isAfter(start) && log.timestamp.isBefore(end)).toList();

    final accessesByPet = <String, int>{};
    final accessesByHour = <String, int>{};
    final accessesByDay = <String, int>{};

    for (final log in filteredLogs) {
      // Par animal
      if (log.petId != null) {
        accessesByPet[log.petId!] = (accessesByPet[log.petId!] ?? 0) + 1;
      }

      // Par heure
      final hour = log.timestamp.hour.toString().padLeft(2, '0');
      accessesByHour[hour] = (accessesByHour[hour] ?? 0) + 1;

      // Par jour
      final day = '${log.timestamp.day}/${log.timestamp.month}';
      accessesByDay[day] = (accessesByDay[day] ?? 0) + 1;
    }

    return AccessStats(
      totalAccesses: filteredLogs.length,
      successfulAccesses: filteredLogs.where((log) => log.status == AccessStatus.success).length,
      deniedAccesses: filteredLogs.where((log) => log.status == AccessStatus.denied).length,
      errorAccesses: filteredLogs.where((log) => log.hasError).length,
      entriesCount: filteredLogs.where((log) => log.direction == AccessDirection.entry).length,
      exitsCount: filteredLogs.where((log) => log.direction == AccessDirection.exit).length,
      periodStart: start,
      periodEnd: end,
      accessesByPet: accessesByPet,
      accessesByHour: accessesByHour,
      accessesByDay: accessesByDay,
    );
  }

  double get successRate => totalAccesses > 0 ? successfulAccesses / totalAccesses : 0.0;
  double get errorRate => totalAccesses > 0 ? errorAccesses / totalAccesses : 0.0;
  
  String get successRateDisplayText => '${(successRate * 100).toStringAsFixed(1)}%';
  String get errorRateDisplayText => '${(errorRate * 100).toStringAsFixed(1)}%';
}