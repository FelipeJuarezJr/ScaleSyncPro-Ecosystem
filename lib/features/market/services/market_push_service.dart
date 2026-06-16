import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scalesyncpro_firestore/models/reptile.dart';

/// Type-safe response representing the result of the market push transaction.
class MarketPushResult {
  final bool success;
  final String message;
  final String? listingId;

  MarketPushResult({
    required this.success,
    required this.message,
    this.listingId,
  });

  factory MarketPushResult.success(String listingId) {
    return MarketPushResult(
      success: true,
      message: 'Successfully listed animal on the marketplace!',
      listingId: listingId,
    );
  }

  factory MarketPushResult.failure(String message) {
    return MarketPushResult(
      success: false,
      message: message,
    );
  }
}

/// A Riverpod provider for the MarketPushService.
final marketPushServiceProvider = Provider<MarketPushService>((ref) {
  return MarketPushService();
});

/// Service to handle transaction block for copying private inventory to the global marketplace storefront.
class MarketPushService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Generate a random V4-compliant UUID
  String _generateUuid() {
    final random = Random();
    const hexDigits = '0123456789abcdef';
    final charList = List<String>.generate(36, (index) {
      if (index == 8 || index == 13 || index == 18 || index == 23) {
        return '-';
      } else if (index == 14) {
        return '4'; // Version 4
      } else if (index == 19) {
        return hexDigits[random.nextInt(4) + 8]; // y-position variant bits: 8, 9, a, or b
      } else {
        return hexDigits[random.nextInt(16)];
      }
    });
    return charList.join();
  }

  /// Parses numeric weight from an ActivityLog detail string.
  /// Handles formats like "120 gr → 130 gr" or "Logged initial weight: 150 gr"
  double? _parseWeightFromDetail(String detail) {
    try {
      if (detail.contains('→')) {
        final parts = detail.split('→');
        if (parts.length > 1) {
          final afterArrow = parts[1].trim();
          final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(afterArrow);
          if (match != null) {
            return double.tryParse(match.group(1) ?? '');
          }
        }
      }
      if (detail.contains('Logged initial weight:')) {
        final afterColon = detail.split('Logged initial weight:')[1].trim();
        final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(afterColon);
        if (match != null) {
          return double.tryParse(match.group(1) ?? '');
        }
      }
      final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(detail);
      if (match != null) {
        return double.tryParse(match.group(1) ?? '');
      }
    } catch (_) {
      // Return null on parsing issues
    }
    return null;
  }

  /// Pushes a reptile to the public marketplace collection `/marketplace_listings`
  /// and updates its commercial status in the user's private collection `/users/{userId}/reptiles/{animalId}`.
  Future<MarketPushResult> pushToMarket({
    required Reptile reptile,
    required double price,
    String? customTitle,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return MarketPushResult.failure('Authentication error: No active user session.');
    }

    final userId = currentUser.uid;
    final animalId = reptile.id;
    if (animalId == null) {
      return MarketPushResult.failure('Invalid reptile: The selected animal has no valid database ID.');
    }

    try {
      // 1. Fetch historical weight logs to populate verifiedPedigreeSnapshot
      final activityLogsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('reptiles')
          .doc(animalId)
          .collection('activity_logs')
          .where('type', isEqualTo: 'weight_change')
          .get();

      final List<Map<String, dynamic>> logsWithDates = [];
      for (final doc in activityLogsSnapshot.docs) {
        final data = doc.data();
        final detail = data['detail'] as String?;
        final logDate = data['logDate'] as Timestamp?;
        if (detail != null && logDate != null) {
          final weight = _parseWeightFromDetail(detail);
          if (weight != null) {
            logsWithDates.add({
              'weight': weight,
              'date': logDate.toDate(),
            });
          }
        }
      }

      // Sort logs chronologically (oldest first) to correctly plot the growth graph
      logsWithDates.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
      final List<double> verifiedPedigreeSnapshot = logsWithDates.map((e) => e['weight'] as double).toList();

      // If the timeline didn't produce weight changes, default to the reptile's current weight
      final currentWeight = reptile.measurements['weight'];
      if (verifiedPedigreeSnapshot.isEmpty && currentWeight != null) {
        if (currentWeight is num) {
          verifiedPedigreeSnapshot.add(currentWeight.toDouble());
        }
      }

      // 2. Prepare public listing values
      final listingId = _generateUuid();
      final title = customTitle ?? 
          '${reptile.gender.toUpperCase()} ${reptile.morph ?? ''} ${reptile.species}'
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();

      final List<String> morphs = reptile.morph != null
          ? reptile.morph!
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
          : [];

      final sellerName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';

      // References for transaction
      final reptileRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('reptiles')
          .doc(animalId);

      final listingRef = _firestore
          .collection('marketplace_listings')
          .doc(listingId);

      // Execute atomic transaction block
      await _firestore.runTransaction((transaction) async {
        // Read reptile doc first to confirm existence/integrity
        final reptileDoc = await transaction.get(reptileRef);
        if (!reptileDoc.exists) {
          throw Exception('Source reptile document not found in rack inventory.');
        }

        // Set the public marketplace listing
        transaction.set(listingRef, {
          'listingId': listingId,
          'sellerId': userId,
          'sellerName': sellerName,
          'animalId': animalId,
          'title': title,
          'price': price,
          'morphs': morphs,
          'genetics': morphs, // Backward compatibility alias
          'imageUrls': reptile.photoUrls,
          'listingDate': Timestamp.now(),
          'verifiedPedigreeSnapshot': verifiedPedigreeSnapshot,
        });

        // Update the private reptile inventory document
        transaction.update(reptileRef, {
          'isForSale': true,
          'salePrice': price,
          'marketplaceListingId': listingId,
          'updatedAt': Timestamp.now(),
        });
      });

      return MarketPushResult.success(listingId);
    } catch (e) {
      return MarketPushResult.failure('Failed to complete transaction: $e');
    }
  }

  /// Removes a reptile from the public marketplace collection `/marketplace_listings`
  /// and updates its commercial status in the user's private collection `/users/{userId}/reptiles/{animalId}`.
  Future<MarketPushResult> removeFromMarket({
    required Reptile reptile,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return MarketPushResult.failure('Authentication error: No active user session.');
    }

    final userId = currentUser.uid;
    final animalId = reptile.id;
    final listingId = reptile.marketplaceListingId;

    if (animalId == null) {
      return MarketPushResult.failure('Invalid reptile: The selected animal has no valid database ID.');
    }

    try {
      final reptileRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('reptiles')
          .doc(animalId);

      // Execute atomic transaction block
      await _firestore.runTransaction((transaction) async {
        // Read reptile doc first to confirm existence/integrity
        final reptileDoc = await transaction.get(reptileRef);
        if (!reptileDoc.exists) {
          throw Exception('Source reptile document not found.');
        }

        // Delete the public marketplace listing if it exists
        if (listingId != null && listingId.isNotEmpty) {
          final listingRef = _firestore.collection('marketplace_listings').doc(listingId);
          transaction.delete(listingRef);
        }

        // Update the private reptile inventory document to clear marketplace attributes
        transaction.update(reptileRef, {
          'isForSale': false,
          'salePrice': null,
          'marketplaceListingId': null,
          'updatedAt': Timestamp.now(),
        });
      });

      return MarketPushResult(
        success: true,
        message: 'Successfully removed animal from the marketplace!',
        listingId: null,
      );
    } catch (e) {
      return MarketPushResult.failure('Failed to complete transaction: $e');
    }
  }
}
