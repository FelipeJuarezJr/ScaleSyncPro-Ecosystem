// lib/widgets/add_breeding_modal.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reptile.dart';
import '../services/reptile_service.dart';
import '../utils/theme.dart';

class AddBreedingModal extends StatefulWidget {
  const AddBreedingModal({super.key});

  @override
  State<AddBreedingModal> createState() => _AddBreedingModalState();
}

class _AddBreedingModalState extends State<AddBreedingModal> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _customSireController = TextEditingController();
  final _customDamController = TextEditingController();
  final _notesController = TextEditingController();

  Reptile? _selectedSire;
  Reptile? _selectedDam;
  DateTime _selectedDate = DateTime.now();

  bool _projectFinished = false;
  bool _multipleClutches = false;
  bool _isLoadingReptiles = true;
  bool _isSaving = false;

  List<Reptile> _males = [];
  List<Reptile> _females = [];

  // Temporary list of clutches to save along with the project
  final List<Map<String, dynamic>> _tempClutches = [];

  @override
  void initState() {
    super.initState();
    _generateDefaultIdentifier();
    _loadReptiles();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _customSireController.dispose();
    _customDamController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _generateDefaultIdentifier() {
    final yearMonth = DateFormat('yyyyMM').format(DateTime.now());
    // Generates a default code like "202606-1"
    _identifierController.text = '$yearMonth-1';
  }

  Future<void> _loadReptiles() async {
    try {
      final reptiles = await ReptileService().getReptiles();
      if (mounted) {
        setState(() {
          _males = reptiles.where((r) => r.gender.toLowerCase() == 'male').toList();
          _females = reptiles.where((r) => r.gender.toLowerCase() == 'female').toList();
          _isLoadingReptiles = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reptiles: $e');
      if (mounted) {
        setState(() {
          _isLoadingReptiles = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppTheme.lightPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _showSelectSireDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        String searchQuery = '';
        
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredMales = _males.where((m) {
              final query = searchQuery.toLowerCase();
              return m.name.toLowerCase().contains(query) || 
                     m.species.toLowerCase().contains(query) ||
                     (m.morph ?? '').toLowerCase().contains(query);
            }).toList();

            return AlertDialog(
              title: const Text('Select Sire (Male)'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search male reptiles...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (filteredMales.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No male reptiles found.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredMales.length,
                          itemBuilder: (context, index) {
                            final male = filteredMales[index];
                            final photoUrl = male.photoUrls.isNotEmpty ? male.photoUrls.first : null;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                backgroundColor: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                                child: photoUrl == null ? const Icon(Icons.male, color: Colors.blue) : null,
                              ),
                              title: Text(male.name),
                              subtitle: Text('${male.species}${male.morph != null ? " • ${male.morph}" : ""}'),
                              onTap: () {
                                setState(() {
                                  _selectedSire = male;
                                  _customSireController.clear();
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelectDameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        String searchQuery = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredFemales = _females.where((f) {
              final query = searchQuery.toLowerCase();
              return f.name.toLowerCase().contains(query) || 
                     f.species.toLowerCase().contains(query) ||
                     (f.morph ?? '').toLowerCase().contains(query);
            }).toList();

            return AlertDialog(
              title: const Text('Select Dame (Female)'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search female reptiles...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (filteredFemales.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No female reptiles found.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredFemales.length,
                          itemBuilder: (context, index) {
                            final female = filteredFemales[index];
                            final photoUrl = female.photoUrls.isNotEmpty ? female.photoUrls.first : null;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                backgroundColor: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                                child: photoUrl == null ? const Icon(Icons.female, color: Colors.pink) : null,
                              ),
                              title: Text(female.name),
                              subtitle: Text('${female.species}${female.morph != null ? " • ${female.morph}" : ""}'),
                              onTap: () {
                                setState(() {
                                  _selectedDam = female;
                                  _customDamController.clear();
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddClutchDialog() {
    final numberController = TextEditingController(text: 'Clutch ${DateTime.now().year}-#${_tempClutches.length + 1}');
    final fertileController = TextEditingController(text: '0');
    final slugsController = TextEditingController(text: '0');
    final tempController = TextEditingController(text: '89.5');
    DateTime layDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Clutch Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(labelText: 'Clutch ID / Number'),
                    ),
                    const SizedBox(height: 12),
                    
                    // Lay Date Selector
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: layDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            layDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Lay Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat.yMMMMd().format(layDate)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fertileController,
                            decoration: const InputDecoration(labelText: 'Fertile Eggs'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: slugsController,
                            decoration: const InputDecoration(labelText: 'Slugs (Bad)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: tempController,
                      decoration: const InputDecoration(labelText: 'Incubator Temp (°F)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final good = int.tryParse(fertileController.text) ?? 0;
                    final bad = int.tryParse(slugsController.text) ?? 0;
                    final temp = double.tryParse(tempController.text) ?? 89.5;

                    setState(() {
                      _tempClutches.add({
                        'clutchNumber': numberController.text,
                        'layDate': layDate,
                        'goodEggs': good,
                        'slugs': bad,
                        'totalEggs': good + bad,
                        'incubatorTemp': temp,
                        'status': 'Incubating',
                      });
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    final sireName = _selectedSire != null ? _selectedSire!.name : _customSireController.text.trim();
    final damName = _selectedDam != null ? _selectedDam!.name : _customDamController.text.trim();

    if (sireName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a Sire/Male'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    if (damName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a Dame/Female'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final db = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      if (userId.isEmpty) {
        throw Exception('User is not authenticated');
      }

      // Generate doc references beforehand so we can link them
      final pairDocRef = db.collection('users').doc(userId).collection('breeding_logs').doc();
      final pairId = pairDocRef.id;

      // Construct dynamic notes field that incorporates identifier and multiple clutches
      String notesText = _notesController.text.trim();
      
      // Let's also store identifier and checkboxes directly in the document's map, 
      // in addition to notes, for rich querying or display later
      final Map<String, dynamic> projectMap = {
        'sireId': _selectedSire?.id ?? '',
        'sireName': sireName,
        'damId': _selectedDam?.id ?? '',
        'damName': damName,
        'pairedDate': Timestamp.fromDate(_selectedDate),
        'status': _projectFinished ? 'Separated' : 'Active',
        'copulationDates': <Timestamp>[],
        'notes': notesText,
        'identifier': _identifierController.text.trim(),
        'multipleClutches': _multipleClutches,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 1. Save breeding pair log
      await pairDocRef.set(projectMap);

      // 2. Save any added clutches
      for (final tempClutch in _tempClutches) {
        final clutchDocRef = db.collection('users').doc(userId).collection('clutches').doc();
        final clutchMap = {
          'pairId': pairId,
          'damId': _selectedDam?.id ?? '',
          'clutchNumber': tempClutch['clutchNumber'],
          'layDate': Timestamp.fromDate(tempClutch['layDate'] as DateTime),
          'estimatedHatchDate': Timestamp.fromDate((tempClutch['layDate'] as DateTime).add(const Duration(days: 58))),
          'totalEggs': tempClutch['totalEggs'],
          'goodEggs': tempClutch['goodEggs'],
          'slugs': tempClutch['slugs'],
          'incubatorTemp': tempClutch['incubatorTemp'],
          'status': tempClutch['status'],
        };
        await clutchDocRef.set(clutchMap);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Breeding Project "$sireName x $damName" saved!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving breeding project: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save project: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final headerBgColor = isDark ? AppTheme.bgPrimary : const Color(0xFF2C5530);
    const headerTextColor = Colors.white;

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        side: isDark ? const BorderSide(color: AppTheme.borderColor) : BorderSide.none,
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadiusLg),
                  topRight: Radius.circular(AppTheme.borderRadiusLg),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'New breeding project',
                      style: TextStyle(
                        color: headerTextColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: headerTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: headerTextColor),
                    onPressed: _isSaving ? null : _saveProject,
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: _isLoadingReptiles
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sire & Dame selection buttons
                            _buildSireDameSelectionRow(isDark, theme),
                            const SizedBox(height: 24),

                            // Project Information Section Header
                            const Text(
                              'Project information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Identifier field
                            const Text(
                              'Identifier',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _identifierController,
                              decoration: const InputDecoration(
                                hintText: 'Enter project identifier...',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Identifier is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Start Date & Time
                            const Text(
                              'Start date & time',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildBetterDateTimePickerRow(theme),
                            const SizedBox(height: 20),

                            // Checkboxes
                            _buildCheckboxRow(
                              value: _projectFinished,
                              label: 'Project is finished',
                              onChanged: (val) {
                                setState(() {
                                  _projectFinished = val ?? false;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            _buildCheckboxRow(
                              value: _multipleClutches,
                              label: 'Multiple clutches',
                              onChanged: (val) {
                                setState(() {
                                  _multipleClutches = val ?? false;
                                  if (!val!) {
                                    _tempClutches.clear();
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Clutches list and Add clutch button
                            if (_multipleClutches) ...[
                              _buildClutchesManagerSection(theme, isDark),
                              const SizedBox(height: 20),
                            ],

                            // General Notes Field
                            const Text(
                              'General Notes (Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Breeding notes, weather conditions, initial pairings...',
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),

            // Bottom Actions Bar
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      side: BorderSide(
                        color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C5530),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSireDameSelectionRow(bool isDark, ThemeData theme) {
    return Row(
      children: [
        // Sire (Male) Selector Card
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedSire == null) ...[
                ElevatedButton.icon(
                  onPressed: _showSelectSireDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add sire / male'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5530),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Text input fallback if database has no records
                TextFormField(
                  controller: _customSireController,
                  decoration: const InputDecoration(
                    hintText: 'Or enter Sire name...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty && _selectedSire != null) {
                      setState(() {
                        _selectedSire = null;
                      });
                    }
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgTertiary : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(
                      color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sire (Male)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.blue, size: 14),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedSire!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedSire!.morph ?? 'Normal',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedSire = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Change', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Interlocking Gender Icon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(-6, -6),
                child: const Icon(Icons.female, size: 36, color: Colors.pinkAccent),
              ),
              Transform.translate(
                offset: const Offset(6, 6),
                child: const Icon(Icons.male, size: 36, color: Colors.blueAccent),
              ),
            ],
          ),
        ),

        // Dame (Female) Selector Card
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedDam == null) ...[
                ElevatedButton.icon(
                  onPressed: _showSelectDameDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add dame / female'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C5530),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Text input fallback if database has no records
                TextFormField(
                  controller: _customDamController,
                  decoration: const InputDecoration(
                    hintText: 'Or enter Dame name...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (val) {
                    if (val.trim().isNotEmpty && _selectedDam != null) {
                      setState(() {
                        _selectedDam = null;
                      });
                    }
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.bgTertiary : const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(
                      color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dame (Female)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.pink,
                            ),
                          ),
                          Icon(Icons.check_circle, color: Colors.pink, size: 14),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDam!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedDam!.morph ?? 'Normal',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDam = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(40, 20),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Change', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBetterDateTimePickerRow(ThemeData theme) {
    // Elegant formatting for date and time
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    final formattedTime = DateFormat('h:mm a').format(_selectedDate);

    return Row(
      children: [
        // Date Selector Button
        Expanded(
          flex: 3,
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: theme.inputDecorationTheme.border?.borderSide.color ?? Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Time Selector Button
        Expanded(
          flex: 2,
          child: InkWell(
            onTap: () => _selectTime(context),
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: theme.inputDecorationTheme.border?.borderSide.color ?? Colors.grey,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formattedTime,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required String label,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildClutchesManagerSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Clutches (${_tempClutches.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            ElevatedButton.icon(
              onPressed: _showAddClutchDialog,
              icon: const Icon(Icons.add, size: 14, color: Colors.white),
              label: const Text('Add a clutch', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppTheme.bgTertiary : const Color(0xFFF1F3F4),
                foregroundColor: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_tempClutches.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            ),
            child: Text(
              'No clutches added yet.',
              style: TextStyle(
                color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                fontSize: 13,
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tempClutches.length,
            itemBuilder: (context, index) {
              final clutch = _tempClutches[index];
              final dateStr = DateFormat.yMMMd().format(clutch['layDate'] as DateTime);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(clutch['clutchNumber'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Laying: $dateStr • ${clutch['goodEggs']} Fertile / ${clutch['slugs']} Slugs • ${clutch['incubatorTemp']}°F',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      setState(() {
                        _tempClutches.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
