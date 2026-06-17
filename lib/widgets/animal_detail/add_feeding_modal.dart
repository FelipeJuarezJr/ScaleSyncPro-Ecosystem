import 'package:flutter/material.dart';
import 'package:scalesync_pro_ecosystem/models/feeding_log.dart';
import 'package:scalesync_pro_ecosystem/models/reptile.dart';
import 'package:scalesync_pro_ecosystem/services/reptile_service.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';

class AddFeedingModal extends StatefulWidget {
  final String? reptileId;
  final Future<void> Function(String reptileId, FeedingLog) onSave;

  const AddFeedingModal({
    super.key,
    this.reptileId,
    required this.onSave,
  });

  @override
  State<AddFeedingModal> createState() => _AddFeedingModalState();
}

class _AddFeedingModalState extends State<AddFeedingModal> {
  final _foodController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedUnit = 'gr';
  final List<String> _units = ['gr', 'kg', 'oz', 'pieces', 'ml'];

  final Map<String, bool> _supplements = {
    'Multivitamin': false,
    'Calcium': false,
    'D3': false,
    'Probiotics': false,
  };

  DateTime _feedingDate = DateTime.now();
  bool _isSaving = false;

  final List<String> _feedItems = [];
  final _feedItemController = TextEditingController();

  List<Reptile> _reptiles = [];
  bool _isLoadingReptiles = false;
  String? _selectedReptileId;

  @override
  void initState() {
    super.initState();
    if (widget.reptileId != null) {
      _selectedReptileId = widget.reptileId;
    } else {
      _loadReptiles();
    }
  }

  Future<void> _loadReptiles() async {
    setState(() => _isLoadingReptiles = true);
    try {
      final reptiles = await ReptileService().getReptiles();
      if (mounted) {
        setState(() {
          _reptiles = reptiles;
          _isLoadingReptiles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReptiles = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reptiles: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _foodController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _feedItemController.dispose();
    super.dispose();
  }

  void _addFeedItem() {
    final item = _feedItemController.text.trim();
    if (item.isNotEmpty) {
      setState(() {
        final qty = _quantityController.text.trim();
        _feedItems.add(qty.isNotEmpty ? '$qty $_selectedUnit $item' : item);
        _feedItemController.clear();
        _quantityController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (_selectedReptileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an animal')),
      );
      return;
    }

    if (_feedItems.isEmpty && _feedItemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one food item')),
      );
      return;
    }

    // Auto-add current item if not yet added
    if (_feedItemController.text.trim().isNotEmpty) {
      _addFeedItem();
    }

    setState(() => _isSaving = true);
    try {
      final activeSupplements = _supplements.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final log = FeedingLog(
        feedItems: List.from(_feedItems),
        supplements: activeSupplements,
        feedingDate: _feedingDate,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );
      await widget.onSave(_selectedReptileId!, log);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _feedingDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _feedingDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _feedingDate.hour,
          _feedingDate.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_feedingDate),
    );
    if (picked != null) {
      setState(() {
        _feedingDate = DateTime(
          _feedingDate.year,
          _feedingDate.month,
          _feedingDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerBg = isDark ? AppTheme.bgPrimary : const Color(0xFF2C5530);

    return Dialog(
      backgroundColor: isDark ? AppTheme.bgSecondary : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: headerBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.borderRadiusLg),
                  topRight: Radius.circular(AppTheme.borderRadiusLg),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.restaurant, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Log Feeding',
                        style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animal selection (if reptileId is null)
                    if (widget.reptileId == null) ...[
                      _SectionLabel('Select Animal', isDark, theme),
                      const SizedBox(height: 6),
                      _isLoadingReptiles
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedReptileId,
                              dropdownColor: isDark ? AppTheme.bgSecondary : Colors.white,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                  borderSide: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                  borderSide: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                                ),
                              ),
                              hint: Text(
                                'Choose a reptile...',
                                style: TextStyle(
                                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              items: _reptiles.map((r) {
                                return DropdownMenuItem<String>(
                                  value: r.id,
                                  child: Text('${r.name} (${r.species})'),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedReptileId = v),
                            ),
                      const SizedBox(height: 16),
                    ],

                     // Date picker
                    _SectionLabel('Date', isDark, theme),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgSecondary,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                            const SizedBox(width: 8),
                            Text(
                              '${_feedingDate.day}/${_feedingDate.month}/${_feedingDate.year}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Time picker
                    _SectionLabel('Time', isDark, theme),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgSecondary,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          border: Border.all(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                            const SizedBox(width: 8),
                            Text(
                              TimeOfDay.fromDateTime(_feedingDate).format(context),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Food items
                    _SectionLabel('Food Items', isDark, theme),
                    const SizedBox(height: 6),
                    // Add item row
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Qty',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                borderSide: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 80,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            isDense: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                borderSide: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                              ),
                            ),
                            items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 12)))).toList(),
                            onChanged: (v) => setState(() => _selectedUnit = v!),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _feedItemController,
                            decoration: InputDecoration(
                              hintText: 'Food item (e.g. Mealworms)',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                borderSide: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                              ),
                            ),
                            onSubmitted: (_) => _addFeedItem(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
                          onPressed: _addFeedItem,
                          tooltip: 'Add item',
                        ),
                      ],
                    ),
                    if (_feedItems.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _feedItems.asMap().entries.map((entry) {
                          return Chip(
                            label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => setState(() => _feedItems.removeAt(entry.key)),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Supplements
                    _SectionLabel('Supplements', isDark, theme),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _supplements.keys.map((s) {
                        return FilterChip(
                          label: Text(s, style: const TextStyle(fontSize: 12)),
                          selected: _supplements[s]!,
                          onSelected: (v) => setState(() => _supplements[s] = v),
                          selectedColor: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withOpacity(0.2),
                          checkmarkColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _SectionLabel('Notes (optional)', isDark, theme),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Any additional notes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          borderSide: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save Feeding Log', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final ThemeData theme;
  const _SectionLabel(this.text, this.isDark, this.theme);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
      ),
    );
  }
}
