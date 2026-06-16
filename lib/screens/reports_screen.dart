import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/theme.dart';
import '../utils/download_helper.dart';
import '../models/reptile.dart';
import '../models/expense.dart';
import '../services/reptile_service.dart';
import '../services/expense_service.dart';

final _reportsReptilesProvider = StreamProvider.autoDispose<List<Reptile>>((ref) {
  return ReptileService().watchReptiles();
});

final _reportsExpensesProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  return ExpenseService().watchExpenses();
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _activeTab = 0; // 0: Animal Labels, 1: Inventory Reports, 2: Expense Reports

  // Animal Labels State variables
  final Set<String> _selectedReptileIds = {};
  String _reptileSearchQuery = '';
  String _selectedAveryTemplate = '5160'; // '5160' (Small) or '5163' (Medium)
  int _startIndex = 0; // Where to start on the label sheet (0-based)
  bool _showName = true;
  bool _showIdentifier = true;
  bool _showMorph = true;
  bool _showSpecies = true;
  bool _showGender = true;
  bool _showBirthDate = true;
  String _qrLinkType = 'id'; // 'id' (Firestore Document ID) or 'url' (Web Profile URL)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Section with Title and Tab Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reports & Analytics',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Generate custom Avery labels and explore collection insights',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (!isMobile)
                        Icon(
                          Icons.insights,
                          color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          size: 32,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Segmented Tab bar matching custom button chip style
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabButton(0, 'Animal Labels', Icons.label_outline),
                        const SizedBox(width: 10),
                        _buildTabButton(1, 'Inventory Reports', Icons.pie_chart_outline),
                        const SizedBox(width: 10),
                        _buildTabButton(2, 'Expense Reports', Icons.bar_chart),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Main Content Area
            Expanded(
              child: _buildActiveTabContent(isMobile, isDark, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _activeTab == index;

    final activeColor = isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor;
    final textColor = isSelected 
        ? (isDark ? Colors.black : Colors.white) 
        : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary);

    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
        });
      },
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          border: Border.all(
            color: isSelected 
                ? activeColor 
                : (isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: textColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isMobile, bool isDark, ThemeData theme) {
    switch (_activeTab) {
      case 0:
        return _buildAnimalLabelsView(isMobile, isDark, theme);
      case 1:
        return _buildInventoryReportsView(isDark, theme);
      case 2:
        return _buildExpenseReportsView(isDark, theme);
      default:
        return const SizedBox.shrink();
    }
  }

  // =========================================================================
  // 1. ANIMAL LABELS TAB
  // =========================================================================
  Widget _buildAnimalLabelsView(bool isMobile, bool isDark, ThemeData theme) {
    final reptilesAsync = ref.watch(_reportsReptilesProvider);

    return reptilesAsync.when(
      data: (reptiles) {
        if (reptiles.isEmpty) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.label_off_outlined,
                      size: 64,
                      color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Reptiles in Collection',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add reptiles to your collection to print labels.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Apply local search filter
        final filteredReptiles = reptiles.where((r) {
          final query = _reptileSearchQuery.toLowerCase();
          return r.name.toLowerCase().contains(query) ||
              r.species.toLowerCase().contains(query) ||
              (r.morph?.toLowerCase().contains(query) ?? false);
        }).toList();

        // Responsive split view for labels
        if (isMobile) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabelConfigCard(theme, isDark),
                const SizedBox(height: 16),
                _buildInteractiveSheetCard(theme, isDark),
                const SizedBox(height: 16),
                _buildReptileSelectionCard(filteredReptiles, theme, isDark),
                const SizedBox(height: 20),
                _buildPrintButtonRow(reptiles, theme, isDark),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Controls & Configuration
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabelConfigCard(theme, isDark),
                        const SizedBox(height: 16),
                        _buildReptileSelectionCard(filteredReptiles, theme, isDark),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Right Column: Interactive Avery Sheet Grid Preview & Print Button
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildInteractiveSheetCard(theme, isDark),
                        const SizedBox(height: 20),
                        _buildPrintButtonRow(reptiles, theme, isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading collection: $err')),
    );
  }

  Widget _buildLabelConfigCard(ThemeData theme, bool isDark) {
    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '1. Label Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            // Avery template selector
            Row(
              children: [
                const Text('Avery Sheet Format: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(
                        color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedAveryTemplate,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
                        items: const [
                          DropdownMenuItem(
                            value: '5160',
                            child: Text('Avery 5160 / 8160 (Small - 30 labels)'),
                          ),
                          DropdownMenuItem(
                            value: '5163',
                            child: Text('Avery 5163 / 8163 (Medium - 10 labels)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedAveryTemplate = val;
                              _startIndex = 0; // reset index to prevent out of bounds
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // QR Target Choice
            Row(
              children: [
                const Text('QR Code Directs to: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(
                        color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _qrLinkType,
                        isExpanded: true,
                        dropdownColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
                        items: const [
                          DropdownMenuItem(
                            value: 'id',
                            child: Text('Firestore ID (Raw text scan)'),
                          ),
                          DropdownMenuItem(
                            value: 'url',
                            child: Text('Web Profile URL (Deep link)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _qrLinkType = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Custom detail toggles
            Text('Details to Include:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildToggleButtonChip('Name', _showName, (v) => setState(() => _showName = v)),
                _buildToggleButtonChip('Identifier', _showIdentifier, (v) => setState(() => _showIdentifier = v)),
                _buildToggleButtonChip('Morph', _showMorph, (v) => setState(() => _showMorph = v)),
                _buildToggleButtonChip('Species', _showSpecies, (v) => setState(() => _showSpecies = v)),
                _buildToggleButtonChip('Sex/Gender', _showGender, (v) => setState(() => _showGender = v)),
                _buildToggleButtonChip('Hatch Date', _showBirthDate, (v) => setState(() => _showBirthDate = v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtonChip(String label, bool value, ValueChanged<bool> onChanged) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor;

    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: value,
      onSelected: onChanged,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
      ),
      side: BorderSide(
        color: value 
            ? color 
            : (isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
      ),
    );
  }

  Widget _buildInteractiveSheetCard(ThemeData theme, bool isDark) {
    final int totalLabels = _selectedAveryTemplate == '5160' ? 30 : 10;
    final int crossAxisCount = _selectedAveryTemplate == '5160' ? 3 : 2;
    final double aspectRatio = _selectedAveryTemplate == '5160' ? 2.625 : 2.0;

    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.grid_on,
                  color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '2. Interactive Starting Position',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Have a partially used sheet? Avoid waste by selecting where on the Avery grid you want to start printing.',
              style: theme.textTheme.bodySmall,
            ),
            const Divider(height: 24),
            // The grid representation
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: aspectRatio,
              ),
              itemCount: totalLabels,
              itemBuilder: (context, index) {
                final isSkipped = index < _startIndex;
                final isStart = index == _startIndex;

                Color cardColor;
                Color borderColor;
                Widget labelContent;

                if (isSkipped) {
                  cardColor = isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.2);
                  borderColor = isDark ? Colors.white12 : Colors.grey.withOpacity(0.3);
                  labelContent = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 14, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(height: 2),
                      Text('Skipped', style: TextStyle(fontSize: 8, color: isDark ? Colors.white38 : Colors.black38)),
                    ],
                  );
                } else if (isStart) {
                  cardColor = (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withOpacity(0.15);
                  borderColor = isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor;
                  labelContent = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, size: 16, color: borderColor),
                      const SizedBox(height: 2),
                      Text('Start Here', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: borderColor)),
                    ],
                  );
                } else {
                  cardColor = isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary;
                  borderColor = isDark ? AppTheme.borderColor : AppTheme.lightBorderColor;
                  labelContent = Center(
                    child: Text(
                      'Label #${index + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  );
                }

                return InkWell(
                  onTap: () {
                    setState(() {
                      _startIndex = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                      border: Border.all(color: borderColor, width: isStart ? 1.5 : 1),
                    ),
                    child: labelContent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReptileSelectionCard(List<Reptile> filteredReptiles, ThemeData theme, bool isDark) {
    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '3. Select Animals (${_selectedReptileIds.length} chosen)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedReptileIds.length == filteredReptiles.length) {
                        _selectedReptileIds.clear();
                      } else {
                        _selectedReptileIds.addAll(filteredReptiles.map((r) => r.id ?? ''));
                      }
                    });
                  },
                  child: Text(
                    _selectedReptileIds.length == filteredReptiles.length ? 'Clear All' : 'Select All',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Search Input
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, species or morph...',
                prefixIcon: const Icon(Icons.search, size: 18),
                fillColor: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (val) {
                setState(() {
                  _reptileSearchQuery = val;
                });
              },
            ),
            const SizedBox(height: 12),
            // Scrollable List
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: filteredReptiles.length,
                itemBuilder: (context, index) {
                  final reptile = filteredReptiles[index];
                  final isSelected = _selectedReptileIds.contains(reptile.id);

                  final String? identifier = reptile.measurements['identifier'];
                  final displayName = reptile.name + (identifier != null && identifier.isNotEmpty ? ' ($identifier)' : '');

                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${reptile.species} • ${reptile.morph ?? "Normal"} • ${reptile.gender}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    activeColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                    checkColor: isDark ? Colors.black : Colors.white,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool? checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedReptileIds.add(reptile.id ?? '');
                        } else {
                          _selectedReptileIds.remove(reptile.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintButtonRow(List<Reptile> allReptiles, ThemeData theme, bool isDark) {
    final isBtnEnabled = _selectedReptileIds.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.ios_share),
            label: const Text('EXPORT LABELS...', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: isBtnEnabled
                ? () {
                    final selectedReptiles = allReptiles
                        .where((r) => _selectedReptileIds.contains(r.id))
                        .toList();

                    showModalBottomSheet(
                      context: context,
                      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Choose Export Format',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.withAlpha(30),
                                    child: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                  ),
                                  title: const Text('Export as PDF (Print Ready)'),
                                  subtitle: const Text('Perfect for high-accuracy Avery printing directly from your browser.'),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final pdfBytes = await generateAveryLabelsPdf(
                                      reptiles: selectedReptiles,
                                      template: _selectedAveryTemplate,
                                      startIndex: _startIndex,
                                      showName: _showName,
                                      showIdentifier: _showIdentifier,
                                      showMorph: _showMorph,
                                      showSpecies: _showSpecies,
                                      showGender: _showGender,
                                      showBirthDate: _showBirthDate,
                                      qrType: _qrLinkType,
                                    );

                                    await Printing.layoutPdf(
                                      onLayout: (PdfPageFormat format) async => pdfBytes,
                                      name: 'ScaleSyncPro_Labels_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.withAlpha(30),
                                    child: const Icon(Icons.description, color: Colors.blue),
                                  ),
                                  title: const Text('Export to Google Docs (Avery HTML)'),
                                  subtitle: const Text('Downloads a formatted HTML file to upload and open directly in Google Docs.'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _exportToGoogleDocs(selectedReptiles, isDark, theme);
                                  },
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }

  void _exportToGoogleDocs(List<Reptile> selectedReptiles, bool isDark, ThemeData theme) {
    final htmlContent = _generateAveryLabelsHtml(
      reptiles: selectedReptiles,
      template: _selectedAveryTemplate,
      startIndex: _startIndex,
      showName: _showName,
      showIdentifier: _showIdentifier,
      showMorph: _showMorph,
      showSpecies: _showSpecies,
      showGender: _showGender,
      showBirthDate: _showBirthDate,
      qrType: _qrLinkType,
    );

    final fileName = 'ScaleSyncPro_Avery_Labels_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.html';
    downloadHtmlFile(htmlContent, fileName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
          title: Row(
            children: [
              Icon(
                Icons.description,
                color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
              ),
              const SizedBox(width: 10),
              const Text('Google Docs Export'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Avery labels have been exported and downloaded as an HTML file.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'To edit or print this in Google Docs, follow these simple steps:',
              ),
              const SizedBox(height: 12),
              _buildStepItem('1', 'Upload the downloaded .html file to your Google Drive.'),
              const SizedBox(height: 8),
              _buildStepItem('2', 'Right-click the file in Google Drive, select "Open with", and choose "Google Docs".'),
              const SizedBox(height: 8),
              _buildStepItem('3', 'Google Docs will import the labels, maintaining the structured grid and QR codes!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'GOT IT',
                style: TextStyle(
                  color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppTheme.primaryColor.withAlpha(51),
          child: Text(
            number,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _generateAveryLabelsHtml({
    required List<Reptile> reptiles,
    required String template,
    required int startIndex,
    required bool showName,
    required bool showIdentifier,
    required bool showMorph,
    required bool showSpecies,
    required bool showGender,
    required bool showBirthDate,
    required String qrType,
  }) {
    final bool is5160 = template == '5160';
    final int cols = is5160 ? 3 : 2;
    final int rows = is5160 ? 10 : 5;
    final int labelsPerPage = cols * rows;

    final totalItems = startIndex + reptiles.length;
    final pagesCount = (totalItems / labelsPerPage).ceil();

    final html = StringBuffer();

    html.write("""<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>ScaleSync Pro Avery Labels</title>
  <style>
    @media print {
      body { margin: 0; }
      .page { page-break-after: always; }
    }
    body {
      margin: 0;
      padding: 0;
      font-family: 'Arial', sans-serif;
      background-color: #f0f0f0;
    }
    .page {
      background-color: white;
      width: 8.5in;
      height: 11.0in;
      box-sizing: border-box;
      padding-top: 0.5in;
      position: relative;
      margin: 10px auto;
      box-shadow: 0 0 10px rgba(0,0,0,0.1);
""");

    if (is5160) {
      html.write("""
      padding-left: 0.1875in;
    }
    .grid {
      display: grid;
      grid-template-columns: 2.625in 2.625in 2.625in;
      grid-template-rows: repeat(10, 1.0in);
      column-gap: 0.125in;
      row-gap: 0;
    }
    .label {
      width: 2.625in;
      height: 1.0in;
      box-sizing: border-box;
      padding: 6px 8px;
      border: 1px dashed #e0e0e0;
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      overflow: hidden;
    }
    .label-empty {
      visibility: hidden;
    }
    .text-container {
      display: flex;
      flex-direction: column;
      justify-content: center;
      font-size: 8pt;
      line-height: 1.2;
      max-width: 1.7in;
    }
    .title {
      font-weight: bold;
      font-size: 9pt;
      margin-bottom: 2px;
      color: #000;
    }
    .subtitle {
      color: #444;
      font-size: 7.5pt;
    }
    .qr {
      width: 44px;
      height: 44px;
    }
    """);
    } else {
      html.write("""
      padding-left: 0.156in;
    }
    .grid {
      display: grid;
      grid-template-columns: 4.0in 4.0in;
      grid-template-rows: repeat(5, 2.0in);
      column-gap: 0.1875in;
      row-gap: 0;
    }
    .label {
      width: 4.0in;
      height: 2.0in;
      box-sizing: border-box;
      padding: 12px 16px;
      border: 1px dashed #e0e0e0;
      display: flex;
      flex-direction: row;
      align-items: center;
      justify-content: space-between;
      overflow: hidden;
    }
    .label-empty {
      visibility: hidden;
    }
    .text-container {
      display: flex;
      flex-direction: column;
      justify-content: center;
      font-size: 10pt;
      line-height: 1.3;
      max-width: 2.4in;
    }
    .title {
      font-weight: bold;
      font-size: 11pt;
      margin-bottom: 4px;
      color: #000;
      text-transform: uppercase;
    }
    .subtitle {
      color: #444;
      font-size: 9pt;
    }
    .qr-container {
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .qr {
      width: 80px;
      height: 80px;
    }
    .qr-sub {
      font-size: 7pt;
      color: #666;
      margin-top: 2px;
    }
    """);
    }

    html.write("""
  </style>
</head>
<body>
""");

    for (int pageIdx = 0; pageIdx < pagesCount; pageIdx++) {
      html.write('  <div class="page">\n');
      html.write('    <div class="grid">\n');

      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          final int gridIdx = pageIdx * labelsPerPage + (r * cols + c);

          if (gridIdx >= startIndex && gridIdx < totalItems) {
            final reptileIdx = gridIdx - startIndex;
            final reptile = reptiles[reptileIdx];
            final String qrData = qrType == 'id'
                ? (reptile.id ?? '')
                : 'https://scalesyncpro.app/reptile/${reptile.id}';
            
            final String encodedQrData = Uri.encodeComponent(qrData);
            final String qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$encodedQrData';

            html.write('      <div class="label">\n');
            html.write('        <div class="text-container">\n');
            if (showName) {
              html.write('          <div class="title">${reptile.name}</div>\n');
            }
            if (showIdentifier) {
              final String? identifier = reptile.measurements['identifier'];
              if (identifier != null && identifier.isNotEmpty) {
                html.write('          <div class="title" style="font-size: ${is5160 ? "7.5pt" : "9.5pt"}; font-weight: bold;">ID: $identifier</div>\n');
              }
            }
            if (showSpecies) {
              html.write('          <div class="subtitle">Species: ${reptile.species}</div>\n');
            }
            if (showMorph && reptile.morph != null && reptile.morph!.isNotEmpty) {
              html.write('          <div class="subtitle">Morph: ${reptile.morph}</div>\n');
            }
            if (showGender) {
              html.write('          <div class="subtitle">Sex: ${reptile.gender}</div>\n');
            }
            if (showBirthDate && reptile.birthDate != null) {
              final formattedDate = DateFormat('yyyy-MM-dd').format(reptile.birthDate!);
              html.write('          <div class="subtitle">Hatched: $formattedDate</div>\n');
            }
            html.write('        </div>\n');
            
            if (is5160) {
              html.write('        <img class="qr" src="$qrUrl" alt="QR" />\n');
            } else {
              html.write('        <div class="qr-container">\n');
              html.write('          <img class="qr" src="$qrUrl" alt="QR" />\n');
              final idSub = reptile.id != null && reptile.id!.length > 8
                  ? reptile.id!.substring(0, 8).toUpperCase()
                  : (reptile.id?.toUpperCase() ?? '');
              html.write('          <div class="qr-sub">$idSub</div>\n');
              html.write('        </div>\n');
            }

            html.write('      </div>\n');
          } else {
            html.write('      <div class="label label-empty"></div>\n');
          }
        }
      }

      html.write('    </div>\n');
      html.write('  </div>\n');
    }

    html.write("""
</body>
</html>
""");

    return html.toString();
  }

  // =========================================================================
  // 2. INVENTORY REPORTS TAB
  // =========================================================================
  Widget _buildInventoryReportsView(bool isDark, ThemeData theme) {
    final reptilesAsync = ref.watch(_reportsReptilesProvider);

    return reptilesAsync.when(
      data: (reptiles) {
        if (reptiles.isEmpty) {
          return const Center(child: Text('No reptiles to analyze'));
        }

        // Metrics aggregation
        final totalCount = reptiles.length;
        final activeBreeders = reptiles.where((r) => r.status.toLowerCase() == 'breeding').length;

        // Species Breakdown
        final Map<String, int> speciesMap = {};
        for (var r in reptiles) {
          speciesMap[r.species] = (speciesMap[r.species] ?? 0) + 1;
        }
        final sortedSpecies = speciesMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Status Breakdown
        final Map<String, int> statusMap = {};
        for (var r in reptiles) {
          statusMap[r.status] = (statusMap[r.status] ?? 0) + 1;
        }

        // Gender Breakdown
        final Map<String, int> genderMap = {'Male': 0, 'Female': 0, 'Unknown': 0};
        for (var r in reptiles) {
          final g = r.gender.toLowerCase();
          if (g == 'male') {
            genderMap['Male'] = genderMap['Male']! + 1;
          } else if (g == 'female') {
            genderMap['Female'] = genderMap['Female']! + 1;
          } else {
            genderMap['Unknown'] = genderMap['Unknown']! + 1;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metric cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final useVerticalLayout = constraints.maxWidth < 600;
                  if (useVerticalLayout) {
                    return Column(
                      children: [
                        _buildMetricCard('Total Animals', '$totalCount', Icons.drag_indicator, isDark, theme),
                        const SizedBox(height: 12),
                        _buildMetricCard('Species Varieties', '${speciesMap.keys.length}', Icons.category, isDark, theme),
                        const SizedBox(height: 12),
                        _buildMetricCard('Active Breeders', '$activeBreeders', Icons.science, isDark, theme),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard('Total Animals', '$totalCount', Icons.drag_indicator, isDark, theme),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard('Species Varieties', '${speciesMap.keys.length}', Icons.category, isDark, theme),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard('Active Breeders', '$activeBreeders', Icons.science, isDark, theme),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Charts Layout
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width <= 1100 ? 1 : 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
                children: [
                  // Species Distribution
                  _buildPieChartCard(
                    title: 'Species Distribution',
                    data: sortedSpecies.map((e) => _PieData(e.key, e.value.toDouble())).toList(),
                    isDark: isDark,
                    theme: theme,
                  ),
                  // Status Breakdown
                  _buildPieChartCard(
                    title: 'Animal Status Breakdown',
                    data: statusMap.entries.map((e) => _PieData(e.key.toUpperCase(), e.value.toDouble())).toList(),
                    isDark: isDark,
                    theme: theme,
                  ),
                  // Gender breakdown
                  _buildPieChartCard(
                    title: 'Gender Ratio',
                    data: genderMap.entries
                        .where((e) => e.value > 0)
                        .map((e) => _PieData(e.key, e.value.toDouble()))
                        .toList(),
                    isDark: isDark,
                    theme: theme,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading inventory data: $err')),
    );
  }

  // =========================================================================
  // 3. EXPENSE REPORTS TAB
  // =========================================================================
  Widget _buildExpenseReportsView(bool isDark, ThemeData theme) {
    final expensesAsync = ref.watch(_reportsExpensesProvider);

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.money_off,
                      size: 64,
                      color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Expense Data Available',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log expenses in the Inventory screen to populate analytics.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Aggregate expense figures
        final totalSpending = expenses.fold<double>(0, (sum, item) => sum + item.cost);
        final avgExpense = expenses.isEmpty ? 0.0 : totalSpending / expenses.length;

        final now = DateTime.now();
        final thisMonthExpenses = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
        final thisMonthSpending = thisMonthExpenses.fold<double>(0, (sum, item) => sum + item.cost);

        // Group by Item Category (itemType)
        final Map<String, double> categoryMap = {};
        for (var e in expenses) {
          categoryMap[e.itemType] = (categoryMap[e.itemType] ?? 0.0) + e.cost;
        }
        final sortedCategories = categoryMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Group by month-year for the last 6 months (Trend)
        final List<DateTime> last6Months = [];
        for (int i = 5; i >= 0; i--) {
          last6Months.add(DateTime(now.year, now.month - i, 1));
        }

        final List<double> monthlySpent = List.filled(6, 0.0);
        for (var e in expenses) {
          for (int i = 0; i < 6; i++) {
            final targetMonth = last6Months[i];
            if (e.date.year == targetMonth.year && e.date.month == targetMonth.month) {
              monthlySpent[i] += e.cost;
              break;
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metric cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final useVerticalLayout = constraints.maxWidth < 600;
                  if (useVerticalLayout) {
                    return Column(
                      children: [
                        _buildMetricCard('Total Spent (All-Time)', '\$${totalSpending.toStringAsFixed(2)}', Icons.payments, isDark, theme),
                        const SizedBox(height: 12),
                        _buildMetricCard('Spent This Month', '\$${thisMonthSpending.toStringAsFixed(2)}', Icons.calendar_month, isDark, theme),
                        const SizedBox(height: 12),
                        _buildMetricCard('Average Cost / Entry', '\$${avgExpense.toStringAsFixed(2)}', Icons.analytics_outlined, isDark, theme),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard('Total Spent (All-Time)', '\$${totalSpending.toStringAsFixed(2)}', Icons.payments, isDark, theme),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard('Spent This Month', '\$${thisMonthSpending.toStringAsFixed(2)}', Icons.calendar_month, isDark, theme),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard('Average Cost / Entry', '\$${avgExpense.toStringAsFixed(2)}', Icons.analytics_outlined, isDark, theme),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 24),

              // Charts Layout
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width <= 1100 ? 1 : 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.5,
                children: [
                  // Spending by Category
                  _buildPieChartCard(
                    title: 'Spending by Category',
                    data: sortedCategories.map((e) => _PieData(e.key, e.value)).toList(),
                    isDark: isDark,
                    theme: theme,
                    valueFormatter: (v) => '\$${v.toStringAsFixed(2)}',
                  ),
                  // Monthly Trend (Bar Chart)
                  _buildMonthlyExpenseBarChart(monthlySpent, last6Months, isDark, theme),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading expense analytics: $err')),
    );
  }

  // =========================================================================
  // COMMON HELPER UI WIDGETS (Metrics & Charts)
  // =========================================================================
  Widget _buildMetricCard(String title, String value, IconData icon, bool isDark, ThemeData theme) {
    final primaryColor = isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor;

    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
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

  Widget _buildPieChartCard({
    required String title,
    required List<_PieData> data,
    required bool isDark,
    required ThemeData theme,
    String Function(double)? valueFormatter,
  }) {
    final colors = getPieChartColors(isDark);
    final total = data.fold<double>(0.0, (sum, item) => sum + item.value);

    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Expanded(
              child: Row(
                children: [
                  // Pie Chart
                  Expanded(
                    flex: 4,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: List.generate(data.length, (index) {
                          final item = data[index];
                          final percentage = total > 0 ? (item.value / total * 100).toStringAsFixed(1) : '0';
                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: item.value,
                            title: '$percentage%',
                            radius: 40,
                            titleStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Legend Column
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(data.length, (index) {
                          final item = data[index];
                          final color = colors[index % colors.length];
                          final labelValue = valueFormatter != null 
                              ? valueFormatter(item.value) 
                              : '${item.value.toInt()}';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  labelValue,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
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

  Widget _buildMonthlyExpenseBarChart(List<double> monthlySpent, List<DateTime> months, bool isDark, ThemeData theme) {
    final double maxVal = monthlySpent.fold<double>(0.0, (m, e) => e > m ? e : m);
    final double maxY = maxVal > 0 ? maxVal * 1.2 : 100;
    final primaryColor = isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor;

    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spend Trend',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  maxY: maxY,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${value.toInt()}',
                            style: TextStyle(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MMM').format(months[idx]),
                                style: TextStyle(
                                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: List.generate(monthlySpent.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: monthlySpent[index],
                          color: primaryColor,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> getPieChartColors(bool isDark) {
    if (isDark) {
      return [
        AppTheme.primaryColor,
        const Color(0xFF00D4FF),
        const Color(0xFFFFA500),
        const Color(0xFFFF5E7E),
        const Color(0xFFE040FB),
        const Color(0xFFFFFF00),
        const Color(0xFF00FF87),
      ];
    } else {
      return [
        AppTheme.lightPrimaryColor,
        const Color(0xFF2196F3),
        const Color(0xFFFF9800),
        const Color(0xFFE91E63),
        const Color(0xFF9C27B0),
        const Color(0xFF4CAF50),
        const Color(0xFFFFEB3B),
      ];
    }
  }
}

class _PieData {
  final String label;
  final double value;
  _PieData(this.label, this.value);
}

// =========================================================================
// NATIVE PDF GENERATION ENGINE
// =========================================================================
Future<Uint8List> generateAveryLabelsPdf({
  required List<Reptile> reptiles,
  required String template,
  required int startIndex,
  required bool showName,
  required bool showIdentifier,
  required bool showMorph,
  required bool showSpecies,
  required bool showGender,
  required bool showBirthDate,
  required String qrType,
}) async {
  final pdf = pw.Document();

  final bool is5160 = template == '5160';
  final int cols = is5160 ? 3 : 2;
  final int rows = is5160 ? 10 : 5;
  final int labelsPerPage = cols * rows;

  final double labelW = is5160 ? 189.0 : 288.0;
  final double labelH = is5160 ? 72.0 : 144.0;
  final double gapH = is5160 ? 9.0 : 13.5;
  final double gapV = 0.0;
  final double marginL = is5160 ? 13.5 : 11.25;
  final double marginT = 36.0;

  final totalItems = startIndex + reptiles.length;
  final pagesCount = (totalItems / labelsPerPage).ceil();

  for (int pageIdx = 0; pageIdx < pagesCount; pageIdx++) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          final List<pw.Widget> children = [];

          for (int r = 0; r < rows; r++) {
            for (int c = 0; c < cols; c++) {
              final int gridIdx = pageIdx * labelsPerPage + (r * cols + c);
              final double left = marginL + c * (labelW + gapH);
              final double top = marginT + r * (labelH + gapV);

              if (gridIdx >= startIndex && gridIdx < totalItems) {
                final reptileIdx = gridIdx - startIndex;
                final reptile = reptiles[reptileIdx];

                children.add(
                  pw.Positioned(
                    left: left,
                    top: top,
                    child: pw.Container(
                      width: labelW,
                      height: labelH,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      ),
                      child: _buildLabelContent(
                        reptile: reptile,
                        is5160: is5160,
                        showName: showName,
                        showIdentifier: showIdentifier,
                        showMorph: showMorph,
                        showSpecies: showSpecies,
                        showGender: showGender,
                        showBirthDate: showBirthDate,
                        qrType: qrType,
                      ),
                    ),
                  ),
                );
              }
            }
          }

          return pw.Stack(children: children);
        },
      ),
    );
  }

  return pdf.save();
}

pw.Widget _buildLabelContent({
  required Reptile reptile,
  required bool is5160,
  required bool showName,
  required bool showIdentifier,
  required bool showMorph,
  required bool showSpecies,
  required bool showGender,
  required bool showBirthDate,
  required String qrType,
}) {
  final String qrData = qrType == 'id'
      ? (reptile.id ?? '')
      : 'https://scalesyncpro.app/reptile/${reptile.id}';

  if (is5160) {
    // Avery 5160 (Small) - Side-by-side: text on left, QR code on right
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (showName)
                pw.Text(
                  reptile.name,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
              if (showIdentifier) ...[
                (() {
                  final String? identifier = reptile.measurements['identifier'];
                  if (identifier != null && identifier.isNotEmpty) {
                    return pw.Text(
                      'ID: $identifier',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                    );
                  }
                  return pw.SizedBox();
                })(),
              ],
              if (showSpecies)
                pw.Text(
                  reptile.species,
                  style: const pw.TextStyle(fontSize: 6.5),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
              if (showMorph && reptile.morph != null && reptile.morph!.isNotEmpty)
                pw.Text(
                  reptile.morph!,
                  style: pw.TextStyle(fontSize: 6.5, fontStyle: pw.FontStyle.italic),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
              if (showGender)
                pw.Text(
                  'Sex: ${reptile.gender}',
                  style: const pw.TextStyle(fontSize: 6.5),
                  maxLines: 1,
                  overflow: pw.TextOverflow.clip,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 4),
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: qrData,
          width: 44,
          height: 44,
        ),
      ],
    );
  } else {
    // Avery 5163 (Medium) - More space, left text, larger QR code right
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (showName)
                pw.Text(
                  reptile.name.toUpperCase(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                  maxLines: 1,
                ),
              if (showIdentifier) ...[
                (() {
                  final String? identifier = reptile.measurements['identifier'];
                  if (identifier != null && identifier.isNotEmpty) {
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'ID: $identifier',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
                          maxLines: 1,
                        ),
                      ],
                    );
                  }
                  return pw.SizedBox();
                })(),
              ],
              pw.SizedBox(height: 4),
              if (showSpecies)
                pw.Text(
                  'Species: ${reptile.species}',
                  style: const pw.TextStyle(fontSize: 8.5),
                  maxLines: 1,
                ),
              if (showMorph && reptile.morph != null && reptile.morph!.isNotEmpty)
                pw.Text(
                  'Morph: ${reptile.morph}',
                  style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic),
                  maxLines: 1,
                ),
              if (showGender)
                pw.Text(
                  'Gender: ${reptile.gender}',
                  style: const pw.TextStyle(fontSize: 8.5),
                  maxLines: 1,
                ),
              if (showBirthDate && reptile.birthDate != null)
                pw.Text(
                  'Hatch Date: ${DateFormat('yyyy-MM-dd').format(reptile.birthDate!)}',
                  style: const pw.TextStyle(fontSize: 8.5),
                  maxLines: 1,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: qrData,
              width: 88,
              height: 88,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              reptile.id?.substring(0, 8).toUpperCase() ?? '',
              style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }
}