// lib/features/ScaleSyncPro/models/breeding_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BreedingPair {
  final String id;
  final String sireId;       // Pointer to Male ScaleSyncAnimal
  final String sireName;
  final String damId;        // Pointer to Female ScaleSyncAnimal
  final String damName;
  final DateTime pairedDate;
  final String status;       // "Active", "Separated", "Successful"
  final List<DateTime> copulationDates;
  final String? notes;

  BreedingPair({
    required this.id,
    required this.sireId,
    required this.sireName,
    required this.damId,
    required this.damName,
    required this.pairedDate,
    required this.status,
    required this.copulationDates,
    this.notes,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'sireId': sireId,
      'sireName': sireName,
      'damId': damId,
      'damName': damName,
      'pairedDate': Timestamp.fromDate(pairedDate),
      'status': status,
      'copulationDates': copulationDates.map((d) => Timestamp.fromDate(d)).toList(),
      'notes': notes,
    };
  }

  factory BreedingPair.fromFirestore(String id, Map<String, dynamic> data) {
    return BreedingPair(
      id: id,
      sireId: data['sireId'] ?? '',
      sireName: data['sireName'] ?? '',
      damId: data['damId'] ?? '',
      damName: data['damName'] ?? '',
      pairedDate: (data['pairedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'Active',
      copulationDates: (data['copulationDates'] as List? ?? [])
          .map((t) => (t as Timestamp).toDate())
          .toList(),
      notes: data['notes'],
    );
  }
}

class ClutchInfo {
  final String id;
  final String? pairId;       // Links directly back to the active pairing
  final String damId;
  final String? damName;      // Display name for the dam
  final String? sireName;     // Display name for the sire
  final String? species;      // e.g., "Ball Python", "Boa Constrictor"
  final String clutchNumber;  // e.g., "Clutch 2026-#05"
  final DateTime layDate;
  final DateTime? estimatedHatchDate;
  final int totalEggs;
  final int goodEggs;        // Fertile count
  final int slugs;           // Infertile count
  final double incubatorTemp; // Precise temp tracking
  final String status;       // "Incubating", "Hatching", "Completed"

  ClutchInfo({
    required this.id,
    this.pairId,
    required this.damId,
    this.damName,
    this.sireName,
    this.species,
    required this.clutchNumber,
    required this.layDate,
    this.estimatedHatchDate,
    required this.totalEggs,
    required this.goodEggs,
    required this.slugs,
    required this.incubatorTemp,
    required this.status,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'pairId': pairId,
      'damId': damId,
      'damName': damName,
      'sireName': sireName,
      'species': species,
      'clutchNumber': clutchNumber,
      'layDate': Timestamp.fromDate(layDate),
      'estimatedHatchDate': estimatedHatchDate != null ? Timestamp.fromDate(estimatedHatchDate!) : null,
      'totalEggs': totalEggs,
      'goodEggs': goodEggs,
      'slugs': slugs,
      'incubatorTemp': incubatorTemp,
      'status': status,
    };
  }

  factory ClutchInfo.fromFirestore(String id, Map<String, dynamic> data) {
    return ClutchInfo(
      id: id,
      pairId: data['pairId'],
      damId: data['damId'] ?? '',
      damName: data['damName'],
      sireName: data['sireName'],
      species: data['species'],
      clutchNumber: data['clutchNumber'] ?? '',
      layDate: (data['layDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estimatedHatchDate: (data['estimatedHatchDate'] as Timestamp?)?.toDate(),
      totalEggs: data['totalEggs'] ?? 0,
      goodEggs: data['goodEggs'] ?? 0,
      slugs: data['slugs'] ?? 0,
      incubatorTemp: (data['incubatorTemp'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'Incubating',
    );
  }
}