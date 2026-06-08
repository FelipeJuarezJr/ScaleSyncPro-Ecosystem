import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import 'package:scalesyncpro_firestore/models/reptile.dart';
import 'package:scalesyncpro_firestore/models/activity_log.dart';
import 'package:scalesyncpro_firestore/models/animal_note.dart';
import 'package:scalesyncpro_firestore/services/reptile_service.dart';
import 'package:scalesyncpro_firestore/services/storage_service.dart';
import 'package:scalesyncpro_firestore/features/pro/models/breeding_model.dart';
import 'package:scalesyncpro_firestore/features/pro/views/breeding_room_view.dart';
import 'package:scalesyncpro_firestore/utils/theme.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/detail_section_card.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/add_note_modal.dart';
import 'package:scalesyncpro_firestore/widgets/animal_detail/add_activity_modal.dart';
import 'package:scalesyncpro_firestore/screens/animal_detail_screen.dart';

class BreedingPairDetailScreen extends StatefulWidget {
  final BreedingPair pair;

  const BreedingPairDetailScreen({super.key, required this.pair});

  @override
  State<BreedingPairDetailScreen> createState() => _BreedingPairDetailScreenState();
}

class _BreedingPairDetailScreenState extends State<BreedingPairDetailScreen> {
  final _breedingService = BreedingService();
  final _reptileService = ReptileService();
  final _imagePicker = ImagePicker();

  bool _isLoadingReptiles = true;
  Reptile? _sireReptile;
  Reptile? _damReptile;

  bool _showAllActivity = false;
  bool _showAllNotes = false;

  @override
  void initState() {
    super.initState();
    _loadReptiles();
  }

  Future<void> _loadReptiles() async {
    try {
      final results = await Future.wait([
        _reptileService.getReptile(widget.pair.sireId),
        _reptileService.getReptile(widget.pair.damId),
      ]);
      if (mounted) {
        setState(() {
          _sireReptile = results[0];
          _damReptile = results[1];
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

  // ─── Modals & Actions ──────────────────────────────────────────────────

  void _openAddNote() {
    showDialog(
      context: context,
      builder: (_) => AddNoteModal(
        onSave: (note) async {
          await _breedingService.addNote(widget.pair.id, note);
          // Log note added to history
          await _breedingService.addActivityLog(
            widget.pair.id,
            ActivityLog(
              event: 'Added a note',
              detail: note.content.length > 30 ? '${note.content.substring(0, 30)}...' : note.content,
              type: 'note',
              logDate: DateTime.now(),
            ),
          );
        },
      ),
    );
  }

  void _openAddActivity() {
    showDialog(
      context: context,
      builder: (_) => AddActivityModal(
        onSave: (log) => _breedingService.addActivityLog(widget.pair.id, log),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image == null) return;

      // Show uploading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading photo to storage...')),
      );

      final bytes = await image.readAsBytes();
      final storage = StorageService();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final uploadPath = 'breeding_logs/${widget.pair.id}/photos/$fileName';

      final downloadUrl = await storage.uploadFile(
        path: uploadPath,
        data: bytes,
        contentType: 'image/jpeg',
      );

      await _breedingService.addPhoto(widget.pair.id, downloadUrl);

      // Log activity
      await _breedingService.addActivityLog(
        widget.pair.id,
        ActivityLog(
          event: 'Uploaded a photo',
          detail: image.name,
          type: 'photo',
          logDate: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Show dialog to enter file name first
    final fileTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgSecondary : Colors.white,
          title: const Text('Add File Attachment'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'File Description / Title',
                hintText: 'e.g. Genetic Certificate, Weight Sheet',
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a description' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(context, titleController.text.trim());
                }
              },
              child: const Text('Next: Choose File'),
            ),
          ],
        );
      },
    );

    if (fileTitle == null) return;

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading file to storage...')),
      );

      final bytes = await file.readAsBytes();
      final storage = StorageService();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final uploadPath = 'breeding_logs/${widget.pair.id}/files/$fileName';

      final downloadUrl = await storage.uploadFile(
        path: uploadPath,
        data: bytes,
        contentType: 'image/jpeg', // Treat as image/jpeg or general binary
      );

      await _breedingService.addFile(widget.pair.id, fileTitle, downloadUrl);

      // Log activity
      await _breedingService.addActivityLog(
        widget.pair.id,
        ActivityLog(
          event: 'Uploaded a file',
          detail: fileTitle,
          type: 'manual',
          logDate: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File attached successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  void _openFileLink(String name, String url) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgSecondary : Colors.white,
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This file is hosted securely on Firebase Storage:'),
              const SizedBox(height: 8),
              SelectableText(
                url,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard!')),
                );
              },
              child: const Text('Copy URL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ─── Build UI ─────────────────────────────────────────────────────────

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
                final isWide = constraints.maxWidth > 750;
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
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(widget.pair.pairedDate);

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // Breadcrumbs
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
                      Text('Breeding Room',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 14,
                    color: isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                Text('Pairing details',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          
          // Breeder pairing row
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
                            'PAIRING: ${widget.pair.sireName} x ${widget.pair.damName}'.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paired Date: $formattedDate',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(widget.pair.status, isDark),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Sire and Dame side-by-side details
                _isLoadingReptiles
                    ? const Center(child: LinearProgressIndicator())
                    : Row(
                        children: [
                          // Sire Column
                          Expanded(
                            child: _buildParentProfileCard(
                              title: 'SIRE (MALE)',
                              reptile: _sireReptile,
                              fallbackName: widget.pair.sireName,
                              isSire: true,
                              theme: theme,
                              isDark: isDark,
                            ),
                          ),
                          
                          // Connection heart
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.pair.copulationDates.length} Locks',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Dame Column
                          Expanded(
                            child: _buildParentProfileCard(
                              title: 'DAME (FEMALE)',
                              reptile: _damReptile,
                              fallbackName: widget.pair.damName,
                              isSire: false,
                              theme: theme,
                              isDark: isDark,
                            ),
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

  Widget _buildParentProfileCard({
    required String title,
    required Reptile? reptile,
    required String fallbackName,
    required bool isSire,
    required ThemeData theme,
    required bool isDark,
  }) {
    final avatarColor = isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary;
    final subColor = isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary;

    return Card(
      color: isDark ? AppTheme.bgTertiary.withOpacity(0.4) : Colors.white,
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
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                color: avatarColor,
                child: reptile != null && reptile.photoUrls.isNotEmpty
                    ? Image.network(
                        reptile.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          isSire ? Icons.male : Icons.female,
                          size: 20,
                          color: isSire ? Colors.blue : Colors.pink,
                        ),
                      )
                    : Icon(
                        isSire ? Icons.male : Icons.female,
                        size: 20,
                        color: isSire ? Colors.blue : Colors.pink,
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
                    title,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isSire ? Colors.blue : Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reptile?.name ?? fallbackName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    reptile?.morph ?? 'Normal',
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
            
            // Action button to view profile
            if (reptile != null)
              IconButton(
                icon: const Icon(Icons.arrow_forward, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnimalDetailScreen(reptile: reptile),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color = isDark ? AppTheme.successColor : AppTheme.lightSuccessColor;
    if (status.toLowerCase() == 'separated') {
      color = isDark ? AppTheme.textLight : AppTheme.lightTextLight;
    } else if (status.toLowerCase() == 'successful') {
      color = isDark ? AppTheme.warningColor : AppTheme.lightWarningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
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

  // ─── Body layouts ──────────────────────────────────────────────────────

  Widget _buildTwoColumnBody(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (History & Notes)
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHistorySection(),
                const SizedBox(height: 16),
                _buildNotesSection(),
              ],
            ),
          ),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
        ),
        // Right Column (Photos & Files)
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
          _buildHistorySection(),
          const SizedBox(height: 16),
          _buildNotesSection(),
          const SizedBox(height: 16),
          _buildPhotosSection(),
          const SizedBox(height: 16),
          _buildFilesSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Section widgets ──────────────────────────────────────────────────

  Widget _buildNotesSection() {
    return StreamBuilder<List<AnimalNote>>(
      stream: _breedingService.watchNotes(widget.pair.id),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final notes = snapshot.data ?? [];
        final visibleNotes = _showAllNotes ? notes : notes.take(3).toList();

        return DetailSectionCard(
          title: 'Notes',
          onAdd: _openAddNote,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting && notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (notes.isEmpty)
                _emptyMessage('You haven\'t added any notes yet', isDark, theme)
              else
                ...visibleNotes.map((note) => _noteTile(note, isDark, theme)),
              if (notes.length > 3)
                _showMoreButton(
                  _showAllNotes ? 'SHOW LESS' : 'SHOW ALL NOTES',
                  () => setState(() => _showAllNotes = !_showAllNotes),
                  isDark, theme,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _noteTile(AnimalNote note, bool isDark, ThemeData theme) {
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    return Dismissible(
      key: Key(note.id ?? note.createdAt.toIso8601String()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.dangerColor.withOpacity(0.15),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
      ),
      onDismissed: (_) => _breedingService.deleteNote(widget.pair.id, note.id!),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(note.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)),
            ),
            const SizedBox(width: 12),
            Text(_timeAgo(note.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return StreamBuilder<List<ActivityLog>>(
      stream: _breedingService.watchActivityLogs(widget.pair.id),
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final logs = snapshot.data ?? [];
        final visibleLogs = _showAllActivity ? logs : logs.take(5).toList();

        return DetailSectionCard(
          title: 'History',
          onAdd: _openAddActivity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting && logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (logs.isEmpty)
                _emptyMessage('No activity logged yet. Tap + to add an entry.', isDark, theme)
              else
                ...visibleLogs.map((log) => _activityTile(log, isDark, theme)),
              if (logs.length > 5)
                _showMoreButton(
                  _showAllActivity ? 'SHOW LESS' : 'SHOW ALL HISTORY',
                  () => setState(() => _showAllActivity = !_showAllActivity),
                  isDark, theme,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _activityTile(ActivityLog log, bool isDark, ThemeData theme) {
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.event.toLowerCase().contains('breeding') || log.event.toLowerCase().contains('copulation')
                ? Icons.favorite
                : Icons.circle_outlined,
            size: 14,
            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.event,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary)),
                if (log.detail != null)
                  Text(log.detail!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary)),
              ],
            ),
          ),
          Text(_timeAgo(log.logDate),
              style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _breedingService.watchPhotos(widget.pair.id),
      builder: (context, snapshot) {
        final photos = snapshot.data ?? [];

        return DetailSectionCard(
          title: 'Photos',
          onAdd: _pickAndUploadPhoto,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: photos.isEmpty
                ? _emptyMessage('You haven\'t uploaded any files yet', isDark, theme, inline: true)
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
                    itemBuilder: (context, i) {
                      final url = photos[i]['url'] as String;
                      final photoId = photos[i]['id'] as String;

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => _breedingService.deletePhoto(widget.pair.id, photoId),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete, color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFilesSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _breedingService.watchFiles(widget.pair.id),
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];

        return DetailSectionCard(
          title: 'Files',
          onAdd: _pickAndUploadFile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (snapshot.connectionState == ConnectionState.waiting && files.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (files.isEmpty)
                _emptyMessage('You haven\'t uploaded any files yet', isDark, theme)
              else
                ...files.map((file) {
                  final name = file['name'] as String;
                  final url = file['url'] as String;
                  final fileId = file['id'] as String;
                  final date = file['createdAt'] as DateTime;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insert_drive_file_outlined,
                            size: 18, color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _openFileLink(name, url),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                Text(
                                  'Uploaded: ${DateFormat.yMMMd().format(date)}',
                                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 16, color: isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                          onPressed: () => _breedingService.deleteFile(widget.pair.id, fileId),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ─── Shared UI ────────────────────────────────────────────────────────

  Widget _emptyMessage(String msg, bool isDark, ThemeData theme, {bool inline = false}) {
    return Padding(
      padding: EdgeInsets.all(inline ? 0 : 16),
      child: Text(msg,
          style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight)),
    );
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
}
