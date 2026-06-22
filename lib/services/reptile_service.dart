import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reptile.dart';
import '../models/feeding_log.dart';
import '../models/activity_log.dart';
import '../models/animal_note.dart';

/// ReptileService — all data operations through the ScaleSyncPro Firebase project.
class ReptileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Get user's reptiles collection reference
  CollectionReference<Map<String, dynamic>> get _reptilesCollection =>
      _firestore.collection('users').doc(_userId).collection('reptiles');

  // Generate a new unique reptile document ID
  String generateReptileId() {
    return _reptilesCollection.doc().id;
  }

  // Add a new reptile
  Future<String> addReptile(Reptile reptile) async {
    try {
      if (reptile.id != null && reptile.id!.isNotEmpty) {
        await _reptilesCollection.doc(reptile.id).set(reptile.toMap());
        return reptile.id!;
      } else {
        final docRef = await _reptilesCollection.add(reptile.toMap());
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to add reptile: $e');
    }
  }

  // Get all reptiles for the current user
  Future<List<Reptile>> getReptiles() async {
    try {
      final querySnapshot = await _reptilesCollection.get();
      return querySnapshot.docs
          .map((doc) => Reptile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reptiles: $e');
    }
  }

  // Watch all reptiles in real-time
  Stream<List<Reptile>> watchReptiles() {
    return _reptilesCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reptile.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get a specific reptile by ID
  Future<Reptile?> getReptile(String id) async {
    try {
      final doc = await _reptilesCollection.doc(id).get();
      if (doc.exists) {
        return Reptile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get reptile: $e');
    }
  }

  // Update a reptile
  Future<void> updateReptile(String id, Reptile reptile) async {
    try {
      final batch = _firestore.batch();
      final reptileRef = _reptilesCollection.doc(id);
      batch.update(reptileRef, reptile.toMap());

      // Automatic State Synchronization (Requirement 4)
      final listingId = reptile.marketplaceListingId;
      final status = reptile.status.toLowerCase();
      if (listingId != null && listingId.isNotEmpty && (status == 'sold' || status == 'archived' || status == 'deceased')) {
        final listingRef = _firestore.collection('marketplace_listings').doc(listingId);
        batch.update(listingRef, {
          'status': reptile.status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update reptile: $e');
    }
  }

  // Delete a reptile
  Future<void> deleteReptile(String id) async {
    try {
      await _reptilesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete reptile: $e');
    }
  }

  // Search reptiles by name or species
  Future<List<Reptile>> searchReptiles(String query) async {
    try {
      final querySnapshot = await _reptilesCollection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '$query\uf8ff')
          .get();
      
      final speciesQuery = await _reptilesCollection
          .where('species', isGreaterThanOrEqualTo: query)
          .where('species', isLessThan: '$query\uf8ff')
          .get();

      final allDocs = [...querySnapshot.docs, ...speciesQuery.docs];
      final uniqueDocs = allDocs.toSet().toList();
      
      return uniqueDocs
          .map((doc) => Reptile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to search reptiles: $e');
    }
  }

  // Get reptiles by status
  Future<List<Reptile>> getReptilesByStatus(String status) async {
    try {
      final querySnapshot = await _reptilesCollection
          .where('status', isEqualTo: status)
          .get();
      return querySnapshot.docs
          .map((doc) => Reptile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reptiles by status: $e');
    }
  }

  // Get reptiles by species
  Future<List<Reptile>> getReptilesBySpecies(String species) async {
    try {
      final querySnapshot = await _reptilesCollection
          .where('species', isEqualTo: species)
          .get();
      return querySnapshot.docs
          .map((doc) => Reptile.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reptiles by species: $e');
    }
  }

  // Get reptile statistics
  Future<Map<String, dynamic>> getReptileStats() async {
    try {
      final reptiles = await getReptiles();
      
      final stats = <String, dynamic>{
        'total': reptiles.length,
        'byStatus': <String, int>{},
        'bySpecies': <String, int>{},
        'byGender': <String, int>{},
      };

      for (final reptile in reptiles) {
        // Count by status
        final status = reptile.status;
        stats['byStatus']![status] = (stats['byStatus']![status] ?? 0) + 1;
        
        // Count by species
        final species = reptile.species;
        stats['bySpecies']![species] = (stats['bySpecies']![species] ?? 0) + 1;
        
        // Count by gender
        final gender = reptile.gender;
        stats['byGender']![gender] = (stats['byGender']![gender] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get reptile statistics: $e');
    }
  }

  // Get reptiles that need attention (feeding, health check, etc.)
  Future<List<Reptile>> getReptilesNeedingAttention() async {
    try {
      final now = DateTime.now();
      final reptiles = await getReptiles();
      
      return reptiles.where((reptile) {
        // Check if feeding is overdue
        if (reptile.lastFeeding != null) {
          final daysSinceFeeding = now.difference(reptile.lastFeeding!).inDays;
          if (daysSinceFeeding > 7) return true; // Overdue for feeding
        }
        
        // Check if health check is overdue
        if (reptile.lastHealthCheck != null) {
          final daysSinceHealthCheck = now.difference(reptile.lastHealthCheck!).inDays;
          if (daysSinceHealthCheck > 30) return true; // Overdue for health check
        }
        
        return false;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get reptiles needing attention: $e');
    }
  }

  // ─── Sub-collection helpers ──────────────────────────────────────────────

  // Feeding Logs
  CollectionReference<Map<String, dynamic>> _feedingLogsRef(String reptileId) =>
      _reptilesCollection.doc(reptileId).collection('feeding_logs');

  Stream<List<FeedingLog>> watchFeedingLogs(String reptileId) {
    return _feedingLogsRef(reptileId)
        .orderBy('feedingDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => FeedingLog.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addFeedingLog(String reptileId, FeedingLog log) async {
    try {
      await _feedingLogsRef(reptileId).add(log.toMap());
      // Update lastFeeding on the parent reptile
      await _reptilesCollection.doc(reptileId).update({
        'lastFeeding': log.feedingDate.toIso8601String(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      // Log to activity history
      await addActivityLog(reptileId, ActivityLog(
        event: 'Feeding logged',
        detail: log.summary,
        type: 'feeding',
        logDate: log.feedingDate,
      ));
    } catch (e) {
      throw Exception('Failed to add feeding log: $e');
    }
  }

  Future<void> deleteFeedingLog(String reptileId, String logId) async {
    await _feedingLogsRef(reptileId).doc(logId).delete();
  }

  // Activity / History Logs
  CollectionReference<Map<String, dynamic>> _activityLogsRef(String reptileId) =>
      _reptilesCollection.doc(reptileId).collection('activity_logs');

  Stream<List<ActivityLog>> watchActivityLogs(String reptileId) {
    return _activityLogsRef(reptileId)
        .orderBy('logDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => ActivityLog.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addActivityLog(String reptileId, ActivityLog log) async {
    try {
      await _activityLogsRef(reptileId).add(log.toMap());
    } catch (e) {
      throw Exception('Failed to add activity log: $e');
    }
  }

  // Notes
  CollectionReference<Map<String, dynamic>> _notesRef(String reptileId) =>
      _reptilesCollection.doc(reptileId).collection('notes');

  Stream<List<AnimalNote>> watchNotes(String reptileId) {
    return _notesRef(reptileId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AnimalNote.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addNote(String reptileId, AnimalNote note) async {
    try {
      await _notesRef(reptileId).add(note.toMap());
    } catch (e) {
      throw Exception('Failed to add note: $e');
    }
  }

  Future<void> deleteNote(String reptileId, String noteId) async {
    await _notesRef(reptileId).doc(noteId).delete();
  }

  /// Combined unified stream of both activity logs and notes, sorted in reverse-chronological order.
  Stream<List<dynamic>> watchUnifiedTimeline(String reptileId) {
    final controller = StreamController<List<dynamic>>();
    List<ActivityLog> logs = [];
    List<AnimalNote> notes = [];

    void emit() {
      final combined = <dynamic>[...logs, ...notes];
      combined.sort((a, b) {
        final dateA = a is ActivityLog ? a.logDate : (a as AnimalNote).createdAt;
        final dateB = b is ActivityLog ? b.logDate : (b as AnimalNote).createdAt;
        return dateB.compareTo(dateA); // Newest first
      });
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    final logsSub = watchActivityLogs(reptileId).listen(
      (data) {
        logs = data;
        emit();
      },
      onError: (err) => controller.addError(err),
    );

    final notesSub = watchNotes(reptileId).listen(
      (data) {
        notes = data;
        emit();
      },
      onError: (err) => controller.addError(err),
    );

    controller.onCancel = () {
      logsSub.cancel();
      notesSub.cancel();
    };

    return controller.stream;
  }

  /// Updates a reptile and auto-logs weight/length changes to activity history.
  Future<void> updateReptileWithHistoryLog(String reptileId, Reptile oldReptile, Reptile newReptile) async {
    try {
      final now = DateTime.now();
      final logs = <ActivityLog>[];

      final oldWeight = oldReptile.measurements['weight'];
      final newWeight = newReptile.measurements['weight'];
      final weightUnit = newReptile.measurements['weightUnit'] ?? 'gr';
      if (newWeight != null && oldWeight != newWeight) {
        logs.add(ActivityLog(
          event: 'Weight changed',
          detail: oldWeight == null
              ? 'Logged initial weight: $newWeight $weightUnit'
              : '$oldWeight $weightUnit → $newWeight $weightUnit',
          type: 'weight_change',
          logDate: now,
        ));
      }

      final oldLength = oldReptile.measurements['length'];
      final newLength = newReptile.measurements['length'];
      final lengthUnit = newReptile.measurements['lengthUnit'] ?? 'cm';
      if (newLength != null && oldLength != newLength) {
        logs.add(ActivityLog(
          event: 'Length changed',
          detail: oldLength == null
              ? 'Logged initial length: $newLength $lengthUnit'
              : '$oldLength $lengthUnit → $newLength $lengthUnit',
          type: 'length_change',
          logDate: now,
        ));
      }

      final batch = _firestore.batch();
      final reptileRef = _reptilesCollection.doc(reptileId);
      batch.update(reptileRef, newReptile.copyWith(updatedAt: now).toMap());

      // Automatic State Synchronization (Requirement 4)
      final listingId = newReptile.marketplaceListingId;
      final status = newReptile.status.toLowerCase();
      if (listingId != null && listingId.isNotEmpty && (status == 'sold' || status == 'archived' || status == 'deceased')) {
        final listingRef = _firestore.collection('marketplace_listings').doc(listingId);
        batch.update(listingRef, {
          'status': newReptile.status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      for (final log in logs) {
        await addActivityLog(reptileId, log);
      }
    } catch (e) {
      throw Exception('Failed to update reptile: $e');
    }
  }
}