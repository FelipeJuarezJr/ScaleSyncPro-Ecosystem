import 'package:cloud_firestore/cloud_firestore.dart';

class TaskSchedule {
  final String? id;
  final String description;
  final String timeOfDay; // HH:mm format, e.g., '08:00'
  final DateTime startDate;
  final int intervalValue;
  final String intervalUnit; // 'Days', 'Weeks', 'Months'
  final List<int> daysOfWeek; // 1 = Monday, 7 = Sunday
  final List<String> actions; // 'Feeding', 'Weight changed', 'Cleaned (spot)', 'Water changed'
  final String targetType; // 'all', 'single'
  final String? reptileId;
  final String? reptileName;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskSchedule({
    this.id,
    required this.description,
    required this.timeOfDay,
    required this.startDate,
    required this.intervalValue,
    required this.intervalUnit,
    required this.daysOfWeek,
    required this.actions,
    required this.targetType,
    this.reptileId,
    this.reptileName,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'timeOfDay': timeOfDay,
      'startDate': Timestamp.fromDate(startDate),
      'intervalValue': intervalValue,
      'intervalUnit': intervalUnit,
      'daysOfWeek': daysOfWeek,
      'actions': actions,
      'targetType': targetType,
      'reptileId': reptileId,
      'reptileName': reptileName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TaskSchedule.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TaskSchedule(
      id: id,
      description: map['description'] ?? '',
      timeOfDay: map['timeOfDay'] ?? map['scheduleType'] ?? '08:00',
      startDate: parseDate(map['startDate']),
      intervalValue: map['intervalValue'] ?? 1,
      intervalUnit: map['intervalUnit'] ?? 'Weeks',
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      actions: List<String>.from(map['actions'] ?? []),
      targetType: map['targetType'] ?? 'all',
      reptileId: map['reptileId'],
      reptileName: map['reptileName'],
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  TaskSchedule copyWith({
    String? id,
    String? description,
    String? timeOfDay,
    DateTime? startDate,
    int? intervalValue,
    String? intervalUnit,
    List<int>? daysOfWeek,
    List<String>? actions,
    String? targetType,
    String? reptileId,
    String? reptileName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskSchedule(
      id: id ?? this.id,
      description: description ?? this.description,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      startDate: startDate ?? this.startDate,
      intervalValue: intervalValue ?? this.intervalValue,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      actions: actions ?? this.actions,
      targetType: targetType ?? this.targetType,
      reptileId: reptileId ?? this.reptileId,
      reptileName: reptileName ?? this.reptileName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
