import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_schedule.dart';

class TaskScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _schedulesCollection =>
      _firestore.collection('users').doc(_userId).collection('schedules');

  // Add a new schedule
  Future<String> addSchedule(TaskSchedule schedule) async {
    try {
      final docRef = await _schedulesCollection.add(schedule.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add schedule: $e');
    }
  }

  // Update a schedule
  Future<void> updateSchedule(String id, TaskSchedule schedule) async {
    try {
      await _schedulesCollection.doc(id).update(schedule.toMap());
    } catch (e) {
      throw Exception('Failed to update schedule: $e');
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id) async {
    try {
      await _schedulesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete schedule: $e');
    }
  }

  // Get all schedules
  Future<List<TaskSchedule>> getSchedules() async {
    try {
      if (_userId.isEmpty) return [];
      final querySnapshot = await _schedulesCollection.get();
      return querySnapshot.docs
          .map((doc) => TaskSchedule.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get schedules: $e');
    }
  }

  // Watch schedules in real-time
  Stream<List<TaskSchedule>> watchSchedules() {
    if (_userId.isEmpty) return Stream.value([]);
    return _schedulesCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskSchedule.fromMap(doc.data(), doc.id))
            .toList());
  }
}
