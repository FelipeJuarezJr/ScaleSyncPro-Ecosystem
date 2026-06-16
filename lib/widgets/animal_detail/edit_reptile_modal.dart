import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reptile.dart';
import '../../services/reptile_service.dart';
import '../../utils/theme.dart';

class EditReptileModal extends StatefulWidget {
  final Reptile reptile;
  const EditReptileModal({super.key, required this.reptile});

  @override
  State<EditReptileModal> createState() => _EditReptileModalState();
}

class _EditReptileModalState extends State<EditReptileModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _identifierController;
  late TextEditingController _speciesController;
  late TextEditingController _morphController;
  late TextEditingController _breederController;
  late TextEditingController _notesController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;

  late String _selectedGender;
  late String _selectedStatus;
  late String _selectedWeightUnit;
  late String _selectedLengthUnit;

  DateTime? _birthDate;
  DateTime? _acquisitionDate;
  bool _isSaving = false;

  static const List<String> _statuses = ['active', 'breeding', 'sold', 'deceased'];
  static const List<String> _weightUnits = ['gr', 'kg', 'oz', 'lbs'];
  static const List<String> _lengthUnits = ['cm', 'in'];

  @override
  void initState() {
    super.initState();
    final r = widget.reptile;
    _nameController = TextEditingController(text: r.name);
    _identifierController = TextEditingController(
        text: (r.measurements['identifier'] ?? '').toString());
    _speciesController = TextEditingController(text: r.species);
    _morphController = TextEditingController(text: r.morph ?? '');
    _breederController = TextEditingController(text: r.breeder ?? '');
    _notesController = TextEditingController(text: r.notes ?? '');
    _weightController = TextEditingController(
        text: (r.measurements['weight'] ?? '').toString());
    _lengthController = TextEditingController(
        text: (r.measurements['length'] ?? '').toString());
    _selectedGender = r.gender;
    _selectedStatus = r.status;
    _selectedWeightUnit = r.measurements['weightUnit'] ?? 'gr';
    _selectedLengthUnit = r.measurements['lengthUnit'] ?? 'cm';
    _birthDate = r.birthDate;
    _acquisitionDate = r.acquisitionDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _speciesController.dispose();
    _morphController.dispose();
    _breederController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isBirth) async {
    final initial = isBirth
        ? (_birthDate ?? DateTime(DateTime.now().year - 1))
        : (_acquisitionDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _acquisitionDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final newReptile = widget.reptile.copyWith(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        morph: _morphController.text.trim().isEmpty ? null : _morphController.text.trim(),
        gender: _selectedGender,
        status: _selectedStatus,
        breeder: _breederController.text.trim().isEmpty ? null : _breederController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        birthDate: _birthDate,
        acquisitionDate: _acquisitionDate,
        measurements: {
          ...widget.reptile.measurements,
          'identifier': _identifierController.text.trim().isEmpty ? null : _identifierController.text.trim(),
          'weight': double.tryParse(_weightController.text.trim()) ?? widget.reptile.measurements['weight'],
          'weightUnit': _selectedWeightUnit,
          'length': double.tryParse(_lengthController.text.trim()) ?? widget.reptile.measurements['length'],
          'lengthUnit': _selectedLengthUnit,
        },
      );
      await ReptileService().updateReptileWithHistoryLog(
          widget.reptile.id!, widget.reptile, newReptile);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newReptile.name} updated!'),
            backgroundColor: AppTheme.lightSuccessColor,
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerBg = isDark ? AppTheme.bgPrimary : const Color(0xFF2C5530);
    final fmt = DateFormat('MMM d, yyyy');

    return Dialog(
      backgroundColor: isDark ? AppTheme.bgSecondary : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
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
                  const Icon(Icons.edit, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Edit Details',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context)),
                  IconButton(
                      icon: Icon(_isSaving ? Icons.hourglass_empty : Icons.check,
                          color: Colors.white),
                      onPressed: _isSaving ? null : _save),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Identifier
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Name', isDark, theme),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(hintText: 'Animal name'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Identifier', isDark, theme),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _identifierController,
                                  decoration: const InputDecoration(hintText: 'Unique identifier'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Label('Species / Type', isDark, theme),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _speciesController,
                        decoration: const InputDecoration(hintText: 'Species'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Species is required' : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Morph', isDark, theme),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _morphController,
                                  decoration:
                                      const InputDecoration(hintText: 'e.g. Normal'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Breeder', isDark, theme),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _breederController,
                                  decoration:
                                      const InputDecoration(hintText: 'Breeder name'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Gender & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Sex', isDark, theme),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedGender,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10)),
                                  items: ['male', 'female', 'unknown']
                                      .map((g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g[0].toUpperCase() + g.substring(1))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedGender = v!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Status', isDark, theme),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: _selectedStatus,
                                  decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10)),
                                  items: _statuses
                                      .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s[0].toUpperCase() + s.substring(1))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedStatus = v!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Weight & Length
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Weight', isDark, theme),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _weightController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(decimal: true),
                                        decoration:
                                            const InputDecoration(hintText: '0.0'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: _selectedWeightUnit,
                                      underline: const SizedBox(),
                                      items: _weightUnits
                                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedWeightUnit = v!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Length', isDark, theme),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _lengthController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(decimal: true),
                                        decoration:
                                            const InputDecoration(hintText: '0.0'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DropdownButton<String>(
                                      value: _selectedLengthUnit,
                                      underline: const SizedBox(),
                                      items: _lengthUnits
                                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedLengthUnit = v!),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Birth date & Acquisition date
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Birth Date', isDark, theme),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(true),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.borderRadius),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.bgTertiary
                                          : AppTheme.lightBgSecondary,
                                      borderRadius:
                                          BorderRadius.circular(AppTheme.borderRadius),
                                      border: Border.all(
                                          color: isDark
                                              ? AppTheme.borderColor
                                              : AppTheme.lightBorderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.cake_outlined, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _birthDate != null
                                                ? fmt.format(_birthDate!)
                                                : 'Select date',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                        if (_birthDate != null)
                                          GestureDetector(
                                            onTap: () =>
                                                setState(() => _birthDate = null),
                                            child: const Icon(Icons.clear, size: 14),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Acquisition Date', isDark, theme),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _pickDate(false),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.borderRadius),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 13),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.bgTertiary
                                          : AppTheme.lightBgSecondary,
                                      borderRadius:
                                          BorderRadius.circular(AppTheme.borderRadius),
                                      border: Border.all(
                                          color: isDark
                                              ? AppTheme.borderColor
                                              : AppTheme.lightBorderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.shopping_bag_outlined, size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _acquisitionDate != null
                                                ? fmt.format(_acquisitionDate!)
                                                : 'Select date',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                        if (_acquisitionDate != null)
                                          GestureDetector(
                                            onTap: () =>
                                                setState(() => _acquisitionDate = null),
                                            child: const Icon(Icons.clear, size: 14),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Notes
                      _Label('Notes', isDark, theme),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(hintText: 'General notes about this animal...'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.borderRadius)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  final ThemeData theme;
  const _Label(this.text, this.isDark, this.theme);

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
