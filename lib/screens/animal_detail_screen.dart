import 'package:flutter/material.dart';
import 'package:scalesyncpro_firestore/models/reptile.dart';
import 'package:scalesyncpro_firestore/models/activity_log.dart';
import 'package:scalesyncpro_firestore/models/animal_note.dart';
import 'package:scalesyncpro_firestore/services/reptile_service.dart';
import 'package:scalesyncpro_firestore/utils/theme.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/detail_section_card.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/add_feeding_modal.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/add_note_modal.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/add_activity_modal.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/edit_reptile_modal.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/add_measurement_modal.dart';

class AnimalDetailScreen extends StatefulWidget {
  final Reptile reptile;

  const AnimalDetailScreen({super.key, required this.reptile});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late Reptile _reptile;
  final _service = ReptileService();

  String _selectedCategory = 'All';
  bool _showAllTimeline = false;

  @override
  void initState() {
    super.initState();
    _reptile = widget.reptile;
  }

  // ─── Helpers ────────────────────────────────────────────────────────────

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${(diff.inDays / 365).floor()} year(s) ago';
  }

  String _ageLabel() {
    final age = _reptile.age;
    if (age == null) return '—';
    if (age == 0) return '< 1 year';
    return '$age year${age > 1 ? 's' : ''}';
  }

  // ─── Modals ────────────────────────────────────────────────────────────

  void _openEditModal() async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => EditReptileModal(reptile: _reptile),
    );
    if (updated == true && mounted) {
      // Re-fetch reptile to get fresh data
      final fresh = await _service.getReptile(_reptile.id!);
      if (fresh != null && mounted) setState(() => _reptile = fresh);
    }
  }

  void _openAddFeeding() {
    showDialog(
      context: context,
      builder: (_) => AddFeedingModal(
        reptileId: _reptile.id!,
        onSave: (reptileId, log) => _service.addFeedingLog(reptileId, log),
      ),
    );
  }

  void _openAddActivity() {
    showDialog(
      context: context,
      builder: (_) => AddActivityModal(
        onSave: (log) => _service.addActivityLog(_reptile.id!, log),
      ),
    );
  }

  void _openAddNote() {
    showDialog(
      context: context,
      builder: (_) => AddNoteModal(
        onSave: (note) => _service.addNote(_reptile.id!, note),
      ),
    );
  }

  void _openAddMeasurement() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => AddMeasurementModal(
        reptile: _reptile,
        onSave: (weight, weightUnit, length, lengthUnit) async {
          final newReptile = _reptile.copyWith(
            measurements: {
              ..._reptile.measurements,
              if (weight != null) 'weight': weight,
              'weightUnit': weightUnit,
              if (length != null) 'length': length,
              'lengthUnit': lengthUnit,
            },
          );
          await _service.updateReptileWithHistoryLog(_reptile.id!, _reptile, newReptile);
        },
      ),
    );
    if (updated == true && mounted) {
      final fresh = await _service.getReptile(_reptile.id!);
      if (fresh != null && mounted) setState(() => _reptile = fresh);
    }
  }

  void _confirmDeleteReptile() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Animal'),
        content: Text('Are you sure you want to delete ${_reptile.name}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.deleteReptile(_reptile.id!);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgSecondary,
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return _buildTwoColumnBody(isDark);
                } else {
                  return _buildSingleColumnBody(isDark);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final bgColor = isDark ? AppTheme.bgSecondary : AppTheme.lightBgPrimary;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    final weight = _reptile.measurements['weight'];
    final weightUnit = _reptile.measurements['weightUnit'] ?? 'gr';
    final length = _reptile.measurements['length'];
    final lengthUnit = _reptile.measurements['lengthUnit'] ?? 'cm';

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Breadcrumb
          Container(
            color: isDark ? AppTheme.bgTertiary : const Color(0xFFF1F3F4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                      const SizedBox(width: 4),
                      Text('Animals',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 14,
                    color: isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                Text('Animal details',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          
          // Animal info row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ANIMAL: ${_reptile.name}'.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Species: ${_reptile.species} | Morph: ${_reptile.morph ?? 'Normal'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(_reptile.status, isDark),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'delete') _confirmDeleteReptile();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'delete', child: Text('Delete animal')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        ),
                        child: Icon(Icons.more_vert, size: 16,
                            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Details side-by-side (Sire and Dame style)
                Row(
                  children: [
                    // Identity Card
                    Expanded(
                      child: _buildIdentityProfileCard(theme, isDark),
                    ),
                    
                    // Center edit connection button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Tooltip(
                        message: 'Edit Details',
                        child: InkWell(
                          onTap: _openEditModal,
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Edit Details',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Stats Card
                    Expanded(
                      child: _buildStatsProfileCard(weight, weightUnit, length, lengthUnit, theme, isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color = isDark ? AppTheme.successColor : AppTheme.lightSuccessColor;
    final sLower = status.toLowerCase();
    if (sLower == 'sold' || sLower == 'deceased') {
      color = isDark ? AppTheme.dangerColor : AppTheme.lightDangerColor;
    } else if (sLower == 'breeding') {
      color = isDark ? AppTheme.warningColor : AppTheme.lightWarningColor;
    } else if (sLower == 'inactive') {
      color = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildIdentityProfileCard(ThemeData theme, bool isDark) {
    final avatarColor = isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
    final isMale = _reptile.gender.toLowerCase() == 'male';

    return Card(
      color: isDark ? AppTheme.bgTertiary.withValues(alpha: 0.4) : Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Thumbnail / Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                color: avatarColor,
                child: _reptile.photoUrls.isNotEmpty
                    ? Image.network(
                        _reptile.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          isMale ? Icons.male : Icons.female,
                          size: 20,
                          color: isMale ? Colors.blue : Colors.pink,
                        ),
                      )
                    : Icon(
                        isMale ? Icons.male : Icons.female,
                        size: 20,
                        color: isMale ? Colors.blue : Colors.pink,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IDENTITY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isMale ? Colors.blue : Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _reptile.gender.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    _reptile.species,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsProfileCard(
    dynamic weight,
    String weightUnit,
    dynamic length,
    String lengthUnit,
    ThemeData theme,
    bool isDark,
  ) {
    final avatarColor = isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    final weightText = weight != null ? '$weight $weightUnit' : '—';
    final lengthText = length != null ? '$length $lengthUnit' : '—';

    return Card(
      color: isDark ? AppTheme.bgTertiary.withValues(alpha: 0.4) : Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            // Thumbnail / Icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                color: avatarColor,
                child: Icon(
                  Icons.scale_outlined,
                  size: 20,
                  color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATS & AGE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age: ${_ageLabel()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '$weightText | $lengthText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: subColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Body layouts ──────────────────────────────────────────────────────

  Widget _buildTwoColumnBody(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTimelineSection(),
              ],
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildPhotosSection(),
                const SizedBox(height: 16),
                _buildFilesSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleColumnBody(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimelineSection(),
          const SizedBox(height: 16),
          _buildPhotosSection(),
          const SizedBox(height: 16),
          _buildFilesSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Timeline UI ────────────────────────────────────────────────────────

  Widget _buildFilterChips(bool isDark, ThemeData theme) {
    final categories = ['All', 'Feedings', 'Notes', 'Measurements', 'General'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: categories.map((cat) {
            final selected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat, style: const TextStyle(fontSize: 12)),
                selected: selected,
                onSelected: (val) {
                  if (val) setState(() => _selectedCategory = cat);
                },
                selectedColor: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withValues(alpha: 0.2),
                checkmarkColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return StreamBuilder<List<dynamic>>(
      stream: _service.watchUnifiedTimeline(_reptile.id!),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final allItems = snapshot.data ?? [];

        final weight = _reptile.measurements['weight'];
        final weightUnit = _reptile.measurements['weightUnit'] ?? 'gr';
        final length = _reptile.measurements['length'];
        final lengthUnit = _reptile.measurements['lengthUnit'] ?? 'cm';

        // Apply filtering
        final filteredItems = allItems.where((item) {
          if (_selectedCategory == 'All') return true;
          if (_selectedCategory == 'Feedings') {
            return item is ActivityLog && item.type == 'feeding';
          }
          if (_selectedCategory == 'Notes') {
            return item is AnimalNote;
          }
          if (_selectedCategory == 'Measurements') {
            return item is ActivityLog && (item.type == 'weight_change' || item.type == 'length_change');
          }
          if (_selectedCategory == 'General') {
            return item is ActivityLog &&
                item.type != 'feeding' &&
                item.type != 'weight_change' &&
                item.type != 'length_change';
          }
          return true;
        }).toList();

        final visibleItems = _showAllTimeline ? filteredItems : filteredItems.take(5).toList();

        return DetailSectionCard(
          title: 'Activity Timeline',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: 'Log Feeding',
                child: InkWell(
                  onTap: _openAddFeeding,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.restaurant,
                        size: 18,
                        color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Log Measurements',
                child: InkWell(
                  onTap: _openAddMeasurement,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.scale_outlined,
                        size: 18,
                        color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Log Activity',
                child: InkWell(
                  onTap: _openAddActivity,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.history,
                        size: 18,
                        color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Add Note',
                child: InkWell(
                  onTap: _openAddNote,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.note_add,
                        size: 18,
                        color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterChips(isDark, theme),
              const Divider(height: 1, thickness: 0.5),
              if (snapshot.connectionState == ConnectionState.waiting && allItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: _selectedCategory == 'Measurements' && (weight != null || length != null)
                        ? _buildCurrentMeasurementsCard(theme, isDark, weight, weightUnit, length, lengthUnit)
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _selectedCategory == 'Feedings'
                                    ? Icons.restaurant
                                    : _selectedCategory == 'Measurements'
                                        ? Icons.scale_outlined
                                        : _selectedCategory == 'Notes'
                                            ? Icons.note_add_outlined
                                            : Icons.history,
                                size: 48,
                                color: (isDark ? AppTheme.textLight : AppTheme.lightTextLight).withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No ${_selectedCategory.toLowerCase() == 'all' ? 'events' : _selectedCategory.toLowerCase()} found for this animal.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (_selectedCategory == 'Feedings') {
                                    _openAddFeeding();
                                  } else if (_selectedCategory == 'Measurements') {
                                    _openAddMeasurement();
                                  } else if (_selectedCategory == 'Notes') {
                                    _openAddNote();
                                  } else {
                                    _openAddActivity();
                                  }
                                },
                                icon: Icon(
                                  _selectedCategory == 'Feedings'
                                      ? Icons.restaurant
                                      : _selectedCategory == 'Measurements'
                                          ? Icons.scale_outlined
                                          : _selectedCategory == 'Notes'
                                              ? Icons.note_add
                                              : Icons.add,
                                  size: 16,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                                label: Text(
                                  _selectedCategory == 'Feedings'
                                      ? 'Log Feeding'
                                      : _selectedCategory == 'Measurements'
                                          ? 'Log Measurements'
                                          : _selectedCategory == 'Notes'
                                              ? 'Add Note'
                                              : 'Log Activity',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                )
              else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) {
                    final item = visibleItems[index];
                    final isFirst = index == 0;
                    final isLast = index == visibleItems.length - 1 && visibleItems.length == filteredItems.length;
                    return _buildTimelineItem(item, isFirst, isLast, isDark, theme);
                  },
                ),
                if (filteredItems.length > 5)
                  _showMoreButton(
                    _showAllTimeline ? 'SHOW LESS' : 'SHOW ALL HISTORY',
                    () => setState(() => _showAllTimeline = !_showAllTimeline),
                    isDark,
                    theme,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(dynamic item, bool isFirst, bool isLast, bool isDark, ThemeData theme) {
    // Get date
    final date = item is ActivityLog ? item.logDate : (item as AnimalNote).createdAt;
    
    // Determine type, title, detail, icon, and accent color
    String type;
    String title;
    String? detail;
    IconData iconData;
    Color color;

    if (item is AnimalNote) {
      type = 'note';
      title = 'Note Added';
      detail = item.content;
      iconData = Icons.description;
      color = Colors.amber;
    } else {
      final log = item as ActivityLog;
      type = log.type;
      title = log.event;
      detail = log.detail;
      switch (type) {
        case 'feeding':
          iconData = Icons.restaurant;
          color = const Color(0xFF2E7D32); // Beautiful forest green
          break;
        case 'weight_change':
          iconData = Icons.scale;
          color = const Color(0xFF1565C0); // Royal blue
          break;
        case 'length_change':
          iconData = Icons.straighten;
          color = const Color(0xFF00838F); // Teal
          break;
        case 'note':
          iconData = Icons.description;
          color = Colors.amber;
          break;
        case 'photo':
          iconData = Icons.photo;
          color = const Color(0xFFAD1457); // Pink/magenta
          break;
        default:
          iconData = Icons.circle_outlined;
          color = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;
          break;
      }
    }

    final lineColor = isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : AppTheme.lightBorderColor.withValues(alpha: 0.5);

    Widget tileContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (Line + Icon Dot)
          Column(
            children: [
              // Top line
              Container(
                width: 2,
                height: 8,
                color: isFirst ? Colors.transparent : lineColor,
              ),
              // Icon Dot
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Center(
                  child: Icon(iconData, size: 14, color: color),
                ),
              ),
              // Bottom line
              Container(
                width: 2,
                height: 28,
                color: isLast ? Colors.transparent : lineColor,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12), // Align with center of circle (8px top line + 14px center = 22px; 12px height + ~10px half text height = ~22px)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                      ),
                    ),
                  ],
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (type == 'note' && item is AnimalNote) {
      return Dismissible(
        key: Key(item.id ?? item.createdAt.toIso8601String()),
        direction: DismissDirection.endToStart,
        background: Container(
          color: AppTheme.dangerColor.withValues(alpha: 0.15),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
        ),
        onDismissed: (_) => _service.deleteNote(_reptile.id!, item.id!),
        child: tileContent,
      );
    }

    return tileContent;
  }

  Widget _buildPhotosSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final photos = _reptile.photoUrls;

    return DetailSectionCard(
      title: 'Photos',
      onEdit: () {},
      onAdd: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: photos.isEmpty
            ? _emptyMessage('You haven\'t uploaded any photos yet.', isDark, theme,
                inline: true)
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: photos.length,
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  child: Image.network(photos[i], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                            child: const Icon(Icons.broken_image_outlined),
                          )),
                ),
              ),
      ),
    );
  }

  Widget _buildFilesSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DetailSectionCard(
      title: 'Files',
      onAdd: () {},
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _emptyMessage('You haven\'t uploaded any files yet.', isDark, theme,
            inline: true),
      ),
    );
  }

  // ─── Shared UI ────────────────────────────────────────────────────────

  Widget _emptyMessage(String msg, bool isDark, ThemeData theme, {bool inline = false}) {
    final w = Padding(
      padding: EdgeInsets.all(inline ? 0 : 16),
      child: Text(msg,
          style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
    );
    return inline ? w : w;
  }

  Widget _showMoreButton(
      String label, VoidCallback onTap, bool isDark, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 14,
                color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMeasurementsCard(
    ThemeData theme,
    bool isDark,
    dynamic weight,
    String weightUnit,
    dynamic length,
    String lengthUnit,
  ) {
    final cardBg = isDark ? AppTheme.bgSecondary : AppTheme.lightBgPrimary;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.scale_outlined,
                  color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                  size: 20),
              const SizedBox(width: 8),
              Text(
                'Current Measurements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (weight != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$weight $weightUnit',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (weight != null && length != null) const SizedBox(width: 12),
              if (length != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Length',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$length $lengthUnit',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
