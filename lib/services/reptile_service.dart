import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reptile.dart';

/// ReptileService — all data operations through the ScaleSyncPro Firebase project.
class ReptileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Get user's reptiles collection reference
  CollectionReference<Map<String, dynamic>> get _reptilesCollection =>
      _firestore.collection('users').doc(_userId).collection('reptiles');

  // Add a new reptile
  Future<String> addReptile(Reptile reptile) async {
    try {
      final docRef = await _reptilesCollection.add(reptile.toMap());
      return docRef.id;
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
      await _reptilesCollection.doc(id).update(reptile.toMap());
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
} 