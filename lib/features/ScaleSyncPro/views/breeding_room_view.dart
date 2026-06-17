import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../models/reptile.dart';
import '../../../services/reptile_service.dart';
import '../../../utils/theme.dart';
import '../models/breeding_model.dart';
import '../../../models/activity_log.dart';
import '../../../models/animal_note.dart';
import '../../../screens/breeding_pair_detail_screen.dart';
import '../../../widgets/add_breeding_modal.dart';


// ==========================================
// Riverpod Data Providers
// ==========================================

final breedingServiceProvider = Provider((ref) => BreedingService());

final activePairingsProvider = StreamProvider.autoDispose<List<BreedingPair>>((ref) {
  final service = ref.watch(breedingServiceProvider);
  return service.watchActivePairings();
});

final activeClutchesProvider = StreamProvider.autoDispose<List<ClutchInfo>>((ref) {
  final service = ref.watch(breedingServiceProvider);
  return service.watchActiveClutches();
});

final reptilesProvider = FutureProvider.autoDispose<List<Reptile>>((ref) async {
  return await ReptileService().getReptiles();
});

// ==========================================
// Data Access Service
// ==========================================

class BreedingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _breedingCollection =>
      _firestore.collection('users').doc(_userId).collection('breeding_logs');

  CollectionReference<Map<String, dynamic>> get _clutchesCollection =>
      _firestore.collection('users').doc(_userId).collection('clutches');

  Stream<List<BreedingPair>> watchActivePairings() {
    if (_userId.isEmpty) return Stream.value([]);
    return _breedingCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreedingPair.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<BreedingPair?> watchPair(String pairId) {
    if (_userId.isEmpty) return Stream.value(null);
    return _breedingCollection
        .doc(pairId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) return null;
          return BreedingPair.fromFirestore(snapshot.id, snapshot.data()!);
        });
  }

  Stream<List<ClutchInfo>> watchActiveClutches() {
    if (_userId.isEmpty) return Stream.value([]);
    return _clutchesCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ClutchInfo.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> addBreedingPair(BreedingPair pair) async {
    await _breedingCollection.add(pair.toFirestore());
  }

  Future<void> addClutchInfo(ClutchInfo clutch) async {
    await _clutchesCollection.add(clutch.toFirestore());
  }

  Future<void> recordCopulation(String pairId, List<DateTime> currentDates, {DateTime? date}) async {
    final lockDate = date ?? DateTime.now();
    final updatedDates = [...currentDates, lockDate];
    await _breedingCollection.doc(pairId).update({
      'copulationDates': updatedDates.map((d) => Timestamp.fromDate(d)).toList(),
    });
    // Log in activity history as well
    await addActivityLog(
      pairId,
      ActivityLog(
        event: 'Breeding observed',
        detail: 'observed',
        type: 'manual',
        logDate: lockDate,
      ),
    );
  }

  Future<void> removeBreedingPair(String id) async {
    await _breedingCollection.doc(id).delete();
  }

  Future<void> removeClutch(String id) async {
    await _clutchesCollection.doc(id).delete();
  }

  // Breeding Notes Subcollection Methods
  Stream<List<AnimalNote>> watchNotes(String pairId) {
    if (_userId.isEmpty || pairId.isEmpty) return Stream.value([]);
    return _breedingCollection
        .doc(pairId)
        .collection('notes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnimalNote.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addNote(String pairId, AnimalNote note) async {
    if (_userId.isEmpty || pairId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('notes').add(note.toMap());
  }

  Future<void> deleteNote(String pairId, String noteId) async {
    if (_userId.isEmpty || pairId.isEmpty || noteId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('notes').doc(noteId).delete();
  }

  // Breeding Activity Logs (History) Subcollection Methods
  Stream<List<ActivityLog>> watchActivityLogs(String pairId) {
    if (_userId.isEmpty || pairId.isEmpty) return Stream.value([]);
    return _breedingCollection
        .doc(pairId)
        .collection('activity_logs')
        .orderBy('logDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addActivityLog(String pairId, ActivityLog log) async {
    if (_userId.isEmpty || pairId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('activity_logs').add(log.toMap());
  }

  Future<void> deleteActivityLog(String pairId, String logId) async {
    if (_userId.isEmpty || pairId.isEmpty || logId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('activity_logs').doc(logId).delete();
  }

  /// Combined unified stream of both activity logs and notes, sorted in reverse-chronological order.
  Stream<List<dynamic>> watchUnifiedTimeline(String pairId) {
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

    final logsSub = watchActivityLogs(pairId).listen(
      (data) {
        logs = data;
        emit();
      },
      onError: (err) => controller.addError(err),
    );

    final notesSub = watchNotes(pairId).listen(
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

  // Breeding Photos Subcollection Methods
  Stream<List<Map<String, dynamic>>> watchPhotos(String pairId) {
    if (_userId.isEmpty || pairId.isEmpty) return Stream.value([]);
    return _breedingCollection
        .doc(pairId)
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'url': doc.data()['url'] ?? '',
                  'createdAt': (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                })
            .toList());
  }

  Future<void> addPhoto(String pairId, String url) async {
    if (_userId.isEmpty || pairId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('photos').add({
      'url': url,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deletePhoto(String pairId, String photoId) async {
    if (_userId.isEmpty || pairId.isEmpty || photoId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('photos').doc(photoId).delete();
  }

  // Breeding Files Subcollection Methods
  Stream<List<Map<String, dynamic>>> watchFiles(String pairId) {
    if (_userId.isEmpty || pairId.isEmpty) return Stream.value([]);
    return _breedingCollection
        .doc(pairId)
        .collection('files')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  'name': doc.data()['name'] ?? '',
                  'url': doc.data()['url'] ?? '',
                  'createdAt': (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                })
            .toList());
  }

  Future<void> addFile(String pairId, String name, String url) async {
    if (_userId.isEmpty || pairId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('files').add({
      'name': name,
      'url': url,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> deleteFile(String pairId, String fileId) async {
    if (_userId.isEmpty || pairId.isEmpty || fileId.isEmpty) return;
    await _breedingCollection.doc(pairId).collection('files').doc(fileId).delete();
  }
}

// ==========================================
// Main View UI
// ==========================================

class BreedingRoomView extends ConsumerWidget {
  const BreedingRoomView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pairingsAsync = ref.watch(activePairingsProvider);
    final clutchesAsync = ref.watch(activeClutchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Facility Breeding Room'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(activePairingsProvider);
              ref.invalidate(activeClutchesProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              _buildHeaderSection(context),
              const SizedBox(height: 24),

              // Incubator Clutch Overview
              Text(
                'Incubator Clutches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              clutchesAsync.when(
                data: (clutches) => _buildClutchOverview(context, ref, clutches),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text('Error loading clutches: $err'),
                ),
              ),
              const SizedBox(height: 24),

              // Active Pairings HUD + Log New Pairing button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Pairings HUD',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddBreedingModal(context, ref),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Log New Pairing'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              pairingsAsync.when(
                data: (pairings) => _buildPairingsList(context, ref, pairings),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => Center(
                  child: Text('Error loading pairings: $err'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Breeding Operations Deck',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor copulation frequencies, manage visual egg incubator progress timelines, and plan facility pairings.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // INCUBATOR CLUTCHES UI
  // ----------------------------------------------------
  Widget _buildClutchOverview(BuildContext context, WidgetRef ref, List<ClutchInfo> clutches) {
    final theme = Theme.of(context);

    if (clutches.isEmpty) {
      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          alignment: Alignment.center,
          child: Column(
            children: [
              Icon(
                Icons.egg_outlined,
                size: 40,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No Active Incubator Clutches',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Eggs in the incubation chambers will appear here.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showAddClutchDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Clutch Data'),
              )
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 185,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: clutches.length + 1,
        itemBuilder: (context, index) {
          // ── Trailing "+" card ──
          if (index == clutches.length) {
            return GestureDetector(
              onTap: () => _showAddClutchDialog(context, ref),
              child: Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    width: 1.5,
                    // Dart doesn't have native dashed borders, so we use
                    // a slightly lighter stroke + icon to suggest "add"
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '+ Add Clutch',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Log a new clutch',
                      style: TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final clutch = clutches[index];
          
          // Calculate Incubation Countdown
          final layDate = clutch.layDate;
          final hatchDate = clutch.estimatedHatchDate ?? layDate.add(const Duration(days: 60));
          final totalDays = hatchDate.difference(layDate).inDays;
          final daysPassed = DateTime.now().difference(layDate).inDays;
          final remainingDays = hatchDate.difference(DateTime.now()).inDays;
          
          // Clamp progress calculation
          final double progress = totalDays > 0 
              ? (daysPassed / totalDays).clamp(0.0, 1.0) 
              : 0.0;

          return Container(
            width: 290,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              color: theme.brightness == Brightness.dark
                  ? AppTheme.bgPrimary
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                side: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.18),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: Clutch ID + menu ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                          ),
                          child: const Icon(Icons.egg_outlined,
                              size: 16, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clutch.clutchNumber,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.brightness == Brightness.dark
                                      ? AppTheme.textPrimary
                                      : AppTheme.lightTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (clutch.species != null && clutch.species!.isNotEmpty)
                                Text(
                                  clutch.species!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 16,
                              color: AppTheme.textLight),
                          padding: EdgeInsets.zero,
                          onSelected: (val) {
                            if (val == 'delete') {
                              ref.read(breedingServiceProvider).removeClutch(clutch.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Clutch',
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Sire × Dam chip row ──
                    if (clutch.damName != null || clutch.sireName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (clutch.damName != null)
                            _clutchChip(Icons.female, clutch.damName!, Colors.pinkAccent),
                          if (clutch.damName != null && clutch.sireName != null)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text('×',
                                  style: TextStyle(
                                      color: AppTheme.textLight, fontSize: 11)),
                            ),
                          if (clutch.sireName != null)
                            _clutchChip(Icons.male, clutch.sireName!, Colors.blueAccent),
                        ],
                      ),
                    ],

                    const Divider(height: 14),

                    // ── Stats row: eggs + temp ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EGGS',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 9, letterSpacing: 0.6)),
                            const SizedBox(height: 2),
                            Text(
                              '${clutch.goodEggs}/${clutch.totalEggs}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('TEMP',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 9, letterSpacing: 0.6)),
                            const SizedBox(height: 2),
                            Text(
                              '${clutch.incubatorTemp}°F',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Countdown badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: remainingDays <= 7
                                ? AppTheme.warningColor.withOpacity(0.15)
                                : AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadiusSm),
                            border: Border.all(
                              color: remainingDays <= 7
                                  ? AppTheme.warningColor.withOpacity(0.4)
                                  : AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            remainingDays > 0
                                ? '$remainingDays d left'
                                : 'Hatching!',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: remainingDays <= 7
                                  ? AppTheme.warningColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Progress bar ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Day $daysPassed of $totalDays',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10)),
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          remainingDays <= 7
                              ? AppTheme.warningColor
                              : AppTheme.primaryColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }


  // Compact name chip for dam/sire in clutch cards
  Widget _clutchChip(IconData icon, String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ACTIVE PAIRINGS LIST HUD UI
  // ----------------------------------------------------
  Widget _buildPairingsList(BuildContext context, WidgetRef ref, List<BreedingPair> pairings) {
    final theme = Theme.of(context);

    if (pairings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Pairings Scheduled',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Click "Log New Pairing" to define Sire/Dam genetic locks.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openAddBreedingModal(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Log First Pairing'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pairings.length,
      itemBuilder: (context, index) {
        final pair = pairings[index];
        final formattedDate = DateFormat.yMMMd().format(pair.pairedDate);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Sire icon & Dam representation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Pair Details
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BreedingPairDetailScreen(pair: pair),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pair.sireName} ♂  x  ${pair.damName} ♀',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Introduced: $formattedDate',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (pair.notes != null && pair.notes!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Notes: ${pair.notes}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Interactive Copulation Badge
                InkWell(
                  onTap: () => _confirmAndLogCopulation(context, ref, pair),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Locks: ${pair.copulationDates.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Options Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'delete') {
                      ref.read(breedingServiceProvider).removeBreedingPair(pair.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Pair', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // INTERACTIVE COPULATION LOGGING HANDLER
  // ----------------------------------------------------
  void _confirmAndLogCopulation(BuildContext context, WidgetRef ref, BreedingPair pair) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log Successful Copulation'),
          content: Text(
            'Would you like to register a successful copulation (genetic lock) for:\n\n${pair.sireName} x ${pair.damName}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref.read(breedingServiceProvider).recordCopulation(
                    pair.id,
                    pair.copulationDates,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copulation lock logged successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to log: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Register Lock'),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // OPEN FULL BREEDING MODAL (Add Breeding Modal)
  // ----------------------------------------------------
  void _openAddBreedingModal(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddBreedingModal(),
    );

    if (result == true) {
      // Refresh providers so the new pairing appears immediately
      ref.invalidate(activePairingsProvider);
      ref.invalidate(activeClutchesProvider);
    }
  }

  // ----------------------------------------------------
  // REGISTER NEW INCUBATOR CLUTCH — STYLED MODAL SHEET
  // ----------------------------------------------------
  void _showAddClutchDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final clutchIdCtrl = TextEditingController(text: 'Clutch ${DateTime.now().year}-#01');
    final speciesCtrl = TextEditingController();
    final damCtrl = TextEditingController();
    final sireCtrl = TextEditingController();
    final totalEggsCtrl = TextEditingController(text: '8');
    final tempCtrl = TextEditingController(text: '89.5');

    // Pull unique dam/sire names from active pairings for quick-fill chips
    final pairings = ref.read(activePairingsProvider).value ?? [];
    final damSuggestions = pairings.map((p) => p.damName).toSet().toList();
    final sireSuggestions = pairings.map((p) => p.sireName).toSet().toList();

    // Track which chip is selected per field (for highlight feedback)
    String? selectedDam;
    String? selectedSire;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20, top: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.egg_outlined, color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LOG INCUBATOR CLUTCH',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'Register a new clutch to the incubation system',
                              style: TextStyle(color: AppTheme.textLight, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Row 1: Clutch ID + Species ──
                    Row(
                      children: [
                        Expanded(
                          child: _modalField(
                            controller: clutchIdCtrl,
                            label: 'Clutch ID',
                            hint: 'e.g. Clutch 2026-#01',
                            icon: Icons.tag,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _modalField(
                            controller: speciesCtrl,
                            label: 'Species',
                            hint: 'e.g. Ball Python',
                            icon: Icons.pets,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Row 2: Dam + Sire (searchable pickers) ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildSelectorTile(
                            label: 'Dam (Female)',
                            value: selectedDam,
                            icon: Icons.female,
                            accentColor: Colors.pinkAccent,
                            required: true,
                            onTap: () async {
                              final picked = await _showAnimalPickerSheet(
                                context: sheetCtx,
                                title: 'Select Dam',
                                suggestions: damSuggestions,
                                accentColor: Colors.pinkAccent,
                                genderIcon: Icons.female,
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDam = picked);
                                damCtrl.text = picked;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSelectorTile(
                            label: 'Sire (Male)',
                            value: selectedSire,
                            icon: Icons.male,
                            accentColor: Colors.blueAccent,
                            required: false,
                            onTap: () async {
                              final picked = await _showAnimalPickerSheet(
                                context: sheetCtx,
                                title: 'Select Sire',
                                suggestions: sireSuggestions,
                                accentColor: Colors.blueAccent,
                                genderIcon: Icons.male,
                              );
                              if (picked != null) {
                                setSheetState(() => selectedSire = picked);
                                sireCtrl.text = picked;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Row 3: Total Eggs + Target Temp ──
                    Row(
                      children: [
                        Expanded(
                          child: _modalField(
                            controller: totalEggsCtrl,
                            label: 'Total Eggs',
                            hint: '0',
                            icon: Icons.egg,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (int.tryParse(v.trim()) == null) return 'Must be a number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _modalField(
                            controller: tempCtrl,
                            label: 'Target Temp (°F)',
                            hint: '89.5',
                            icon: Icons.thermostat,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v.trim()) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Save Button ──
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          ),
                        ),
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text(
                          'SAVE CLUTCH',
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;

                          final eggs = int.tryParse(totalEggsCtrl.text.trim()) ?? 0;
                          final temp = double.tryParse(tempCtrl.text.trim()) ?? 89.5;
                          final lay = DateTime.now();

                          final clutch = ClutchInfo(
                            id: '',
                            damId: damCtrl.text.trim(),
                            damName: damCtrl.text.trim(),
                            sireName: sireCtrl.text.trim().isEmpty ? null : sireCtrl.text.trim(),
                            species: speciesCtrl.text.trim(),
                            clutchNumber: clutchIdCtrl.text.trim(),
                            layDate: lay,
                            estimatedHatchDate: lay.add(const Duration(days: 58)),
                            totalEggs: eggs,
                            goodEggs: eggs,
                            slugs: 0,
                            incubatorTemp: temp,
                            status: 'Incubating',
                          );

                          try {
                            await ref.read(breedingServiceProvider).addClutchInfo(clutch);
                            if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Clutch registered to incubator!'),
                                  backgroundColor: AppTheme.successColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error registering: $e'),
                                  backgroundColor: AppTheme.dangerColor,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
          }, // StatefulBuilder builder
        ); // StatefulBuilder
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // Searchable animal picker sheet
  // ─────────────────────────────────────────────────────────────────────
  Future<String?> _showAnimalPickerSheet({
    required BuildContext context,
    required String title,
    required List<String> suggestions,
    required Color accentColor,
    required IconData genderIcon,
  }) async {
    final searchCtrl = TextEditingController();
    final customCtrl = TextEditingController();

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (pickerCtx) {
        return StatefulBuilder(
          builder: (pickerCtx, setPickerState) {
            // Filter list based on search query
            final query = searchCtrl.text.toLowerCase().trim();
            final filtered = query.isEmpty
                ? suggestions
                : suggestions
                    .where((n) => n.toLowerCase().contains(query))
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(pickerCtx).viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(pickerCtx).size.height * 0.75,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(
                      color: accentColor.withOpacity(0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.06),
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                      child: Row(
                        children: [
                          Icon(genderIcon, color: accentColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            title,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length} of ${suggestions.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        onChanged: (_) => setPickerState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name…',
                          hintStyle: const TextStyle(
                              color: AppTheme.textLight, fontSize: 13),
                          prefixIcon: const Icon(Icons.search,
                              color: AppTheme.textLight, size: 18),
                          suffixIcon: searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      size: 16, color: AppTheme.textLight),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setPickerState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.bgTertiary,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
                            borderSide:
                                const BorderSide(color: AppTheme.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.borderRadius),
                            borderSide:
                                BorderSide(color: accentColor, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // Results list
                    Flexible(
                      child: filtered.isEmpty && suggestions.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off,
                                      color: AppTheme.textLight, size: 36),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No matches for "${searchCtrl.text}"',
                                    style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : suggestions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'No active pairings found.\nUse the custom name field below.',
                                    style: const TextStyle(
                                        color: AppTheme.textLight,
                                        fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) {
                                    final name = filtered[i];
                                    return InkWell(
                                      onTap: () =>
                                          Navigator.of(pickerCtx).pop(name),
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.borderRadius),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 13),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: AppTheme.borderColor
                                                  .withOpacity(0.5),
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: accentColor
                                                    .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: accentColor
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              child: Icon(genderIcon,
                                                  size: 14,
                                                  color: accentColor),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: const TextStyle(
                                                  color: AppTheme.textPrimary,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Icon(Icons.chevron_right,
                                                size: 18,
                                                color: AppTheme.textLight),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // ── Custom name entry ──
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: AppTheme.borderColor, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: customCtrl,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Or enter a custom name…',
                                hintStyle: const TextStyle(
                                    color: AppTheme.textLight, fontSize: 12),
                                filled: true,
                                fillColor: AppTheme.bgTertiary,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                  borderSide: const BorderSide(
                                      color: AppTheme.borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                  borderSide: BorderSide(
                                      color: accentColor, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.borderRadius),
                              ),
                            ),
                            onPressed: () {
                              final custom = customCtrl.text.trim();
                              if (custom.isNotEmpty) {
                                Navigator.of(pickerCtx).pop(custom);
                              }
                            },
                            child: const Text('Use',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Styled tap-to-open selector tile shown in the clutch modal
  Widget _buildSelectorTile({
    required String label,
    required String? value,
    required IconData icon,
    required Color accentColor,
    required bool required,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label${required ? ' *' : ''}',
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: hasValue
                  ? accentColor.withOpacity(0.07)
                  : AppTheme.bgTertiary,
              borderRadius:
                  BorderRadius.circular(AppTheme.borderRadius),
              border: Border.all(
                color: hasValue ? accentColor : AppTheme.borderColor,
                width: hasValue ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: 16,
                    color: hasValue ? accentColor : AppTheme.textLight),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? value : 'Tap to select…',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasValue
                          ? AppTheme.textPrimary
                          : AppTheme.textLight,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  hasValue ? Icons.check_circle : Icons.arrow_drop_down,
                  size: 18,
                  color: hasValue ? accentColor : AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Reusable styled text field for the modal
  Widget _modalField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 16, color: AppTheme.textLight),
        filled: true,
        fillColor: AppTheme.bgTertiary,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.dangerColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.dangerColor, width: 1.5),
        ),
        errorStyle: const TextStyle(color: AppTheme.dangerColor, fontSize: 10),
      ),
    );
  }
}
