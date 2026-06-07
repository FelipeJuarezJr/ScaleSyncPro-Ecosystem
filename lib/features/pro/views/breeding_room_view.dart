import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../models/reptile.dart';
import '../../../services/reptile_service.dart';
import '../../../utils/theme.dart';
import '../models/breeding_model.dart';


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

  Future<void> recordCopulation(String pairId, List<DateTime> currentDates) async {
    final updatedDates = [...currentDates, DateTime.now()];
    await _breedingCollection.doc(pairId).update({
      'copulationDates': updatedDates.map((d) => Timestamp.fromDate(d)).toList(),
    });
  }

  Future<void> removeBreedingPair(String id) async {
    await _breedingCollection.doc(id).delete();
  }

  Future<void> removeClutch(String id) async {
    await _clutchesCollection.doc(id).delete();
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

              // Quick Actions & Quick-Log trigger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operational Summary',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPairingDialog(context, ref),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Log New Pairing'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

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

              // Active Pairings HUD
              Text(
                'Active Pairings HUD',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
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
        itemCount: clutches.length,
        itemBuilder: (context, index) {
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
          
          final displayRemaining = remainingDays > 0 ? '$remainingDays days left' : 'Hatching expected';

          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.surface 
                  : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            clutch.clutchNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (val) {
                            if (val == 'delete') {
                              ref.read(breedingServiceProvider).removeClutch(clutch.id);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Clutch', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EGGS STATUS', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              '${clutch.goodEggs} Fertile / ${clutch.slugs} Slugs',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('TEMP', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(
                              '${clutch.incubatorTemp}°F',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Incubation Timeline',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          displayRemaining,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
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
                  onPressed: () => _showAddPairingDialog(context, ref),
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
  // REGISTER NEW BREEDING PAIR DIALOG
  // ----------------------------------------------------
  void _showAddPairingDialog(BuildContext context, WidgetRef ref) {
    final reptilesState = ref.read(reptilesProvider);
    final theme = Theme.of(context);

    reptilesState.when(
      data: (reptiles) {
        final males = reptiles.where((r) => r.gender.toLowerCase() == 'male').toList();
        final females = reptiles.where((r) => r.gender.toLowerCase() == 'female').toList();

        if (males.isEmpty || females.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Specimens'),
              content: const Text(
                'You must have at least one Male and one Female reptile in your collection to plan facility pairings.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        Reptile? selectedSire = males.first;
        Reptile? selectedDam = females.first;
        final notesController = TextEditingController();

        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Log New Breeding Pairing'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sire Selection
                        DropdownButtonFormField<Reptile>(
                          value: selectedSire,
                          decoration: const InputDecoration(labelText: 'Select Sire (Male)'),
                          items: males.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text('${m.name} (${m.morph ?? "Normal"})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedSire = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Dam Selection
                        DropdownButtonFormField<Reptile>(
                          value: selectedDam,
                          decoration: const InputDecoration(labelText: 'Select Dam (Female)'),
                          items: females.map((f) {
                            return DropdownMenuItem(
                              value: f,
                              child: Text('${f.name} (${f.morph ?? "Normal"})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedDam = val;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Notes Field
                        TextField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Breeding Notes (Optional)',
                            hintText: 'e.g. Visual locks, ambient weights...',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedSire == null || selectedDam == null) return;
                        
                        final pair = BreedingPair(
                          id: '',
                          sireId: selectedSire!.id ?? '',
                          sireName: selectedSire!.name,
                          damId: selectedDam!.id ?? '',
                          damName: selectedDam!.name,
                          pairedDate: DateTime.now(),
                          status: 'Active',
                          copulationDates: [],
                          notes: notesController.text,
                        );

                        try {
                          await ref.read(breedingServiceProvider).addBreedingPair(pair);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Breeding pair successfully logged!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving pairing: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Register Setup'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Still loading reptiles database...')),
      ),
      error: (err, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading collection: $err')),
      ),
    );
  }

  // ----------------------------------------------------
  // REGISTER NEW INCUBATOR CLUTCH DIALOG
  // ----------------------------------------------------
  void _showAddClutchDialog(BuildContext context, WidgetRef ref) {
    final reptilesState = ref.read(reptilesProvider);

    reptilesState.when(
      data: (reptiles) {
        final females = reptiles.where((r) => r.gender.toLowerCase() == 'female').toList();

        if (females.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Dams Available'),
              content: const Text(
                'You need to register at least one Female reptile in your collection to map clutch laying data.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        Reptile? selectedDam = females.first;
        final clutchNumberController = TextEditingController(text: 'Clutch ${DateTime.now().year}-#01');
        final goodEggsController = TextEditingController(text: '8');
        final slugsController = TextEditingController(text: '0');
        final tempController = TextEditingController(text: '89.5');

        showDialog(
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Log Incubator Clutch'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clutch Reference
                        TextField(
                          controller: clutchNumberController,
                          decoration: const InputDecoration(labelText: 'Clutch ID / Number'),
                        ),
                        const SizedBox(height: 12),

                        // Dam selection
                        DropdownButtonFormField<Reptile>(
                          value: selectedDam,
                          decoration: const InputDecoration(labelText: 'Select Dam (Mother)'),
                          items: females.map((f) {
                            return DropdownMenuItem(
                              value: f,
                              child: Text(f.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedDam = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: goodEggsController,
                                decoration: const InputDecoration(labelText: 'Fertile Eggs'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: slugsController,
                                decoration: const InputDecoration(labelText: 'Slugs (Bad Eggs)'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: tempController,
                          decoration: const InputDecoration(labelText: 'Incubator Temperature (°F)'),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedDam == null) return;
                        
                        final good = int.tryParse(goodEggsController.text) ?? 0;
                        final bad = int.tryParse(slugsController.text) ?? 0;
                        final temp = double.tryParse(tempController.text) ?? 0.0;
                        final lay = DateTime.now();

                        final clutch = ClutchInfo(
                          id: '',
                          damId: selectedDam!.id ?? '',
                          clutchNumber: clutchNumberController.text,
                          layDate: lay,
                          estimatedHatchDate: lay.add(const Duration(days: 58)),
                          totalEggs: good + bad,
                          goodEggs: good,
                          slugs: bad,
                          incubatorTemp: temp,
                          status: 'Incubating',
                        );

                        try {
                          await ref.read(breedingServiceProvider).addClutchInfo(clutch);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Clutch registered to incubator!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error registering: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('Register Clutch'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loading collection...')),
      ),
      error: (err, stack) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $err')),
      ),
    );
  }
}
