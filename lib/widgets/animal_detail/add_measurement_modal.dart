import 'package:flutter/material.dart';
import 'package:scalesync_pro_ecosystem/models/reptile.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';

class AddMeasurementModal extends StatefulWidget {
  final Reptile reptile;
  final Future<void> Function(double? weight, String weightUnit, double? length, String lengthUnit) onSave;

  const AddMeasurementModal({
    super.key,
    required this.reptile,
    required this.onSave,
  });

  @override
  State<AddMeasurementModal> createState() => _AddMeasurementModalState();
}

class _AddMeasurementModalState extends State<AddMeasurementModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _lengthController;

  late String _selectedWeightUnit;
  late String _selectedLengthUnit;
  bool _isSaving = false;

  final List<String> _weightUnits = ['gr', 'kg', 'oz', 'lbs'];
  final List<String> _lengthUnits = ['cm', 'in'];

  @override
  void initState() {
    super.initState();
    final r = widget.reptile;
    _weightController = TextEditingController(
        text: (r.measurements['weight'] ?? '').toString());
    _lengthController = TextEditingController(
        text: (r.measurements['length'] ?? '').toString());
    _selectedWeightUnit = r.measurements['weightUnit'] ?? 'gr';
    _selectedLengthUnit = r.measurements['lengthUnit'] ?? 'cm';
  }

  @override
  void dispose() {
    _weightController.dispose();
    _lengthController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    final weightText = _weightController.text.trim();
    final lengthText = _lengthController.text.trim();

    if (weightText.isEmpty && lengthText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter weight or length to log measurements.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final weight = double.tryParse(weightText);
      final length = double.tryParse(lengthText);

      await widget.onSave(
        weight,
        _selectedWeightUnit,
        length,
        _selectedLengthUnit,
      );
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                  const Icon(Icons.scale_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Log Measurements',
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context)),
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
                      // Weight field
                      _SectionLabel('Weight', isDark, theme),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'Enter weight (e.g. 150)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (v) {
                                if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              value: _selectedWeightUnit,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              items: _weightUnits
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedWeightUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Length field
                      _SectionLabel('Length', isDark, theme),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lengthController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                hintText: 'Enter length (e.g. 45)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              validator: (v) {
                                if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                                  return 'Enter a valid number';
                                  }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              value: _selectedLengthUnit,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                              items: _lengthUnits
                                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedLengthUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Save Measurements', style: TextStyle(fontWeight: FontWeight.bold)),
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
