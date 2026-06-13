import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scalesyncpro_firestore/models/task_schedule.dart';
import 'package:scalesyncpro_firestore/models/reptile.dart';
import 'package:scalesyncpro_firestore/services/reptile_service.dart';
import 'package:scalesyncpro_firestore/services/task_schedule_service.dart';
import 'package:scalesyncpro_firestore/utils/theme.dart';


class AddTaskModal extends StatefulWidget {
  final TaskSchedule? schedule;

  const AddTaskModal({super.key, this.schedule});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController(text: 'Schedule');
  final _intervalValueController = TextEditingController(text: '1');

  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateTime.now();
  String _selectedIntervalUnit = 'Weeks';
  final Set<int> _selectedDays = {};
  final Set<String> _selectedActions = {};
  String? _selectedTargetId = 'all'; // 'all' or reptileId

  List<Reptile> _reptiles = [];
  bool _isLoadingReptiles = true;
  bool _isSaving = false;
  final _taskScheduleService = TaskScheduleService();

  @override
  void initState() {
    super.initState();
    _loadReptiles();
    if (widget.schedule != null) {
      _descriptionController.text = widget.schedule!.description;
      final parts = widget.schedule!.timeOfDay.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
      _startDate = widget.schedule!.startDate;
      _intervalValueController.text = widget.schedule!.intervalValue.toString();
      _selectedIntervalUnit = widget.schedule!.intervalUnit;
      _selectedDays.addAll(widget.schedule!.daysOfWeek);
      _selectedActions.addAll(widget.schedule!.actions);
      _selectedTargetId = widget.schedule!.targetType == 'all' ? 'all' : widget.schedule!.reptileId;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _intervalValueController.dispose();
    super.dispose();
  }

  Future<void> _loadReptiles() async {
    try {
      final list = await ReptileService().getReptiles();
      if (mounted) {
        setState(() {
          _reptiles = list;
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
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgSecondary : Colors.white,
          title: const Text('How does scheduling work?'),
          content: const Text(
            'Create a recurring task schedule for your animals. '
            'You can specify the starting date, how often the action repeats (e.g. every 2 weeks), '
            'which days of the week it should run, and the specific actions to complete.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day of the week.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }
    if (_selectedActions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one action to schedule.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final intervalVal = int.tryParse(_intervalValueController.text) ?? 1;
      final targetType = _selectedTargetId == 'all' ? 'all' : 'single';
      String? reptileName;
      if (targetType == 'single') {
        final rep = _reptiles.firstWhere((r) => r.id == _selectedTargetId);
        reptileName = rep.name;
      }

      final timeOfDayStr = "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}";

      final schedule = TaskSchedule(
        id: widget.schedule?.id,
        description: _descriptionController.text.trim(),
        timeOfDay: timeOfDayStr,
        startDate: _startDate,
        intervalValue: intervalVal,
        intervalUnit: _selectedIntervalUnit,
        daysOfWeek: _selectedDays.toList()..sort(),
        actions: _selectedActions.toList(),
        targetType: targetType,
        reptileId: targetType == 'single' ? _selectedTargetId : null,
        reptileName: reptileName,
      );

      if (widget.schedule != null) {
        await _taskScheduleService.updateSchedule(widget.schedule!.id!, schedule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _taskScheduleService.addSchedule(schedule);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
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

  Future<void> _deleteSchedule() async {
    if (widget.schedule?.id == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgSecondary : Colors.white,
          title: const Text('Delete Schedule'),
          content: const Text('Are you sure you want to delete this schedule? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _taskScheduleService.deleteSchedule(widget.schedule!.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error deleting schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete schedule: $e'),
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
                  Expanded(
                    child: Text(
                      widget.schedule != null ? 'Edit schedule' : 'Add schedule',
                      style: const TextStyle(
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
                    onPressed: _isSaving ? null : _saveSchedule,
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
                            // Description Field
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                TextButton.icon(
                                  onPressed: _showHelpDialog,
                                  icon: const Icon(Icons.help_outline, size: 16, color: Colors.blue),
                                  label: const Text(
                                    'How does this work?',
                                    style: TextStyle(fontSize: 12, color: Colors.blue),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                hintText: 'Enter schedule description...',
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Description is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Time of Day Picker
                            const Text(
                              'Time of day',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  suffixIcon: Icon(Icons.access_time),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Starts On Date Picker
                            const Text(
                              'Starts on',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  suffixIcon: Icon(Icons.calendar_today),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                child: Text(DateFormat('dd-MM-yyyy').format(_startDate)),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Complete Action Every Recurrence
                            const Text(
                              'Complete action every',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _intervalValueController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. 1',
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(val) == null) {
                                        return 'Invalid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedIntervalUnit,
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'Days', child: Text('Days')),
                                      DropdownMenuItem(value: 'Weeks', child: Text('Weeks')),
                                      DropdownMenuItem(value: 'Months', child: Text('Months')),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _selectedIntervalUnit = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Weekday Selector (Mon - Sun)
                            const Text(
                              'Select days of the week',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildWeekdaySelector(theme, isDark),
                            const SizedBox(height: 18),

                            // Warning Banner for Web App Notifications
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Unfortunately notifications are not yet available on the web app',
                                      style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Actions Checklist: "What do you want to schedule?"
                            const Text(
                              'What do you want to schedule?',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildActionRow('Feeding', 'Feeding', isDark, theme),
                            _buildActionRow('Weight changed', 'Weight changed', isDark, theme),
                            _buildActionRow('Cleaned (spot)', 'Cleaned (spot)', isDark, theme),
                            _buildActionRow('Water changed', 'Water changed', isDark, theme),
                            const SizedBox(height: 18),

                            // Target selection: "Who is the schedule for?"
                            const Text(
                              'Who is the schedule for?',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _selectedTargetId,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: [
                                const DropdownMenuItem(value: 'all', child: Text('All my animals')),
                                ..._reptiles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedTargetId = val;
                                  });
                                }
                              },
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
                children: [
                  if (widget.schedule != null)
                    TextButton.icon(
                      onPressed: _isSaving ? null : _deleteSchedule,
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  const Spacer(),
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
                    onPressed: _isSaving ? null : _saveSchedule,
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

  Widget _buildWeekdaySelector(ThemeData theme, bool isDark) {
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = _selectedDays.contains(dayNum);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(dayNum);
              } else {
                _selectedDays.add(dayNum);
              }
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? (isDark ? AppTheme.primaryColor : const Color(0xFF2C5530))
                  : (isDark ? AppTheme.bgTertiary : const Color(0xFFE1E4E6)),
              border: Border.all(
                color: isSelected
                    ? (isDark ? AppTheme.primaryColor : const Color(0xFF2C5530))
                    : (isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              weekdays[index],
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.black : Colors.white)
                    : (isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionRow(String label, String value, bool isDark, ThemeData theme) {
    final isSelected = _selectedActions.contains(value);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedActions.remove(value);
          } else {
            _selectedActions.add(value);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppTheme.primaryColor : const Color(0xFF2C5530))
                      : (isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                  width: 2,
                ),
                color: isSelected
                    ? (isDark ? AppTheme.primaryColor : const Color(0xFF2C5530))
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: isDark ? Colors.black : Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
