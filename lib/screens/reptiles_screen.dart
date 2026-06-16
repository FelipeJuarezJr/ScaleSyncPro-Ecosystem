import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/reptile.dart';
import '../services/reptile_service.dart';
import '../widgets/add_reptile_modal.dart';
import '../utils/theme.dart';
import 'animal_detail_screen.dart';


class ReptilesScreen extends StatefulWidget {
  const ReptilesScreen({super.key});

  @override
  State<ReptilesScreen> createState() => _ReptilesScreenState();
}

class _ReptilesScreenState extends State<ReptilesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ReptileService _reptileService = ReptileService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddReptileModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AddReptileModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      body: StreamBuilder<List<Reptile>>(
        stream: _reptileService.watchReptiles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Card(
                color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Reptiles',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final reptiles = snapshot.data ?? [];
          final filteredReptiles = reptiles.where((reptile) {
            final query = _searchQuery.toLowerCase();
            return reptile.name.toLowerCase().contains(query) ||
                reptile.species.toLowerCase().contains(query) ||
                (reptile.morph ?? '').toLowerCase().contains(query);
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final padding = width > 600 ? 24.0 : 16.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Add Button Row
                  Padding(
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reptiles',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your reptile collection',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddReptileModal,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add Reptile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppTheme.primaryColor : const Color(0xFF4A7C59),
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search reptiles by name, species or morph...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),

                  Expanded(
                    child: filteredReptiles.isEmpty
                        ? _buildEmptyState(context, reptiles.isEmpty)
                        : _buildGridView(context, filteredReptiles, width, padding),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isCollectionEmpty) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCollectionEmpty ? Icons.pets : Icons.search_off,
              size: 72,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
            ),
            const SizedBox(height: 20),
            Text(
              isCollectionEmpty ? 'No reptiles in your collection' : 'No matching reptiles found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isCollectionEmpty
                  ? 'Add your first reptile to get started tracking its logs.'
                  : 'Try adjusting your search criteria.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCollectionEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddReptileModal,
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Reptile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppTheme.primaryColor : const Color(0xFF4A7C59),
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(BuildContext context, List<Reptile> list, double width, double padding) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int crossAxisCount = 1;
    if (width > 1200) {
      crossAxisCount = 4;
    } else if (width > 850) {
      crossAxisCount = 3;
    } else if (width > 550) {
      crossAxisCount = 2;
    }

    double childAspectRatio = 0.85;
    if (width > 1400) {
      childAspectRatio = 0.88;
    } else if (width > 1200) {
      childAspectRatio = 0.78;
    } else if (width > 850) {
      childAspectRatio = 0.82;
    } else if (width > 550) {
      childAspectRatio = 0.88;
    } else {
      childAspectRatio = 1.3; // Horizontal-ish feel on tiny screens if we want, or standard card aspect
    }

    // Adjust aspect ratio for portrait/landscape feel
    if (crossAxisCount == 1) {
      childAspectRatio = 1.8; // Wide card for mobile list style
    }

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final reptile = list[index];
        return _buildReptileCard(context, reptile, isDark, theme, crossAxisCount == 1);
      },
    );
  }

  Widget _buildReptileCard(BuildContext context, Reptile reptile, bool isDark, ThemeData theme, bool isMobileRow) {
    final cardColor = isDark ? AppTheme.bgSecondary : AppTheme.lightBgPrimary;

    Widget cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image
        Expanded(
          flex: 5,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (reptile.photoUrls.isNotEmpty)
                Image.network(
                  reptile.photoUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(reptile.species, isDark),
                )
              else
                _buildPlaceholderImage(reptile.species, isDark),
              // Gender badge
              Positioned(
                top: 8,
                left: 8,
                child: _buildGenderBadge(reptile.gender),
              ),
              // Status badge
              Positioned(
                top: 8,
                right: 8,
                child: _buildStatusBadge(reptile.status, isDark),
              ),
            ],
          ),
        ),
        // Details
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reptile.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (reptile.measurements['identifier'] != null &&
                            reptile.measurements['identifier'].toString().isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withAlpha(38),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withAlpha(76),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              reptile.measurements['identifier'].toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reptile.species,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    if (reptile.morph != null && reptile.morph!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reptile.morph!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                        ),
                      ),
                    ],
                  ],
                ),
                Column(
                  children: [
                    const Divider(height: 8, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMeasurementChip(
                          icon: Icons.straighten,
                          value: '${reptile.measurements['length'] ?? 0} ${reptile.measurements['lengthUnit'] ?? 'cm'}',
                          isDark: isDark,
                          theme: theme,
                        ),
                        _buildMeasurementChip(
                          icon: Icons.scale,
                          value: '${reptile.measurements['weight'] ?? 0} ${reptile.measurements['weightUnit'] ?? 'gr'}',
                          isDark: isDark,
                          theme: theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isMobileRow) {
      // Horizontal card layout for mobile list feel
      cardBody = Row(
        children: [
          // Image Left
          SizedBox(
            width: 130,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (reptile.photoUrls.isNotEmpty)
                  Image.network(
                    reptile.photoUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(reptile.species, isDark),
                  )
                else
                  _buildPlaceholderImage(reptile.species, isDark),
                Positioned(
                  top: 6,
                  left: 6,
                  child: _buildGenderBadge(reptile.gender),
                ),
              ],
            ),
          ),
          // Content Right
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                reptile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ),
                            if (reptile.measurements['identifier'] != null &&
                                reptile.measurements['identifier'].toString().isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withAlpha(38),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor).withAlpha(76),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  reptile.measurements['identifier'].toString(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(reptile.status, isDark),
                    ],
                  ),
                  Text(
                    reptile.species,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                  if (reptile.morph != null && reptile.morph!.isNotEmpty)
                    Text(
                      reptile.morph!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                      ),
                    ),
                  Row(
                    children: [
                      _buildMeasurementChip(
                        icon: Icons.straighten,
                        value: '${reptile.measurements['length'] ?? 0} ${reptile.measurements['lengthUnit'] ?? 'cm'}',
                        isDark: isDark,
                        theme: theme,
                      ),
                      const SizedBox(width: 16),
                      _buildMeasurementChip(
                        icon: Icons.scale,
                        value: '${reptile.measurements['weight'] ?? 0} ${reptile.measurements['weightUnit'] ?? 'gr'}',
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnimalDetailScreen(reptile: reptile),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      child: Card(
        color: cardColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          side: BorderSide(
            color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
            width: 1,
          ),
        ),
        child: cardBody,
      ),
    );
  }

  Map<String, dynamic> _getAnimalIconDetails(String speciesName) {
    final name = speciesName.toLowerCase();
    
    // 1. Turtles & Tortoises
    if (name.contains('tortoise') || 
        name.contains('turtle') || 
        name.contains('slider') || 
        name.contains('terrapin') || 
        name.contains('stinkpot') || 
        name.contains('cooter')) {
      return {
        'icon': Icons.shield_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFF5D4037), Color(0xFF3E2723)], // Earthy Browns
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'label': 'Chelonian',
      };
    }
    
    // 2. Amphibians
    if (name.contains('axolotl') || 
        name.contains('frog') || 
        name.contains('toad') ||
        name.contains('dumpy')) {
      return {
        'icon': Icons.water_drop_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFF00796B), Color(0xFF004D40)], // Deep Teal/Aquatic
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'label': 'Amphibian',
      };
    }
    
    // 3. Invertebrates
    if (name.contains('tarantula') || 
        name.contains('isopod') || 
        name.contains('scorpion') || 
        name.contains('mantis') || 
        name.contains('red knee') || 
        name.contains('greenbottle') ||
        (name.contains('black') && name.contains('brazilian')) ||
        name.contains('curly hair')) {
      return {
        'icon': Icons.bug_report_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)], // Deep Purple/Exotic
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'label': 'Invertebrate',
      };
    }
    
    // 4. Snakes (Pythons, Boas, Colubrids, etc.)
    if (name.contains('python') || 
        name.contains('boa') || 
        name.contains('snake') || 
        name.contains('kingsnake') || 
        name.contains('hognose') || 
        name.contains('gopher') || 
        name.contains('bullsnake') || 
        name.contains('garter') ||
        name.contains('papuan') ||
        name.contains('spilota') ||
        name.contains('harrisoni') ||
        name.contains('cheynei') ||
        name.contains('mcdowelli')) {
      return {
        'icon': Icons.gesture, // Winding serpentine look
        'gradient': const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)], // Jungle Green
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'label': 'Snake',
      };
    }
    
    // 5. Lizards (Geckos, Monitors, Tegus, Chameleons, Iguanas, Skinks, Bearded Dragon)
    if (name.contains('gecko') || 
        name.contains('lizard') || 
        name.contains('dragon') || 
        name.contains('skink') || 
        name.contains('monitor') || 
        name.contains('tegu') || 
        name.contains('uromastyx') || 
        name.contains('chameleon') || 
        name.contains('iguana') ||
        name.contains('leachianus') ||
        name.contains('chahoua')) {
      return {
        'icon': Icons.emoji_nature_outlined,
        'gradient': const LinearGradient(
          colors: [Color(0xFFEF6C00), Color(0xFFE65100)], // Desert Orange/Gold
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'label': 'Lizard',
      };
    }

    // Default fallback (generic animal/pet)
    return {
      'icon': Icons.pets_outlined,
      'gradient': const LinearGradient(
        colors: [Color(0xFF455A64), Color(0xFF263238)], // Grey/Neutral Slate
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      'label': 'Reptile',
    };
  }

  Widget _buildPlaceholderImage(String species, bool isDark) {
    final details = _getAnimalIconDetails(species);
    final iconData = details['icon'] as IconData;
    final gradient = details['gradient'] as Gradient;
    final label = details['label'] as String;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            iconData,
            size: 40,
            color: Colors.white.withOpacity(0.25),
          ),
          Positioned(
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderBadge(String gender) {
    IconData icon;
    Color color;
    if (gender.toLowerCase() == 'male') {
      icon = Icons.male;
      color = Colors.blue;
    } else if (gender.toLowerCase() == 'female') {
      icon = Icons.female;
      color = Colors.pink;
    } else {
      icon = Icons.question_mark;
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 14,
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color color = isDark ? AppTheme.successColor : AppTheme.lightSuccessColor;
    if (status.toLowerCase() == 'breeding') {
      color = isDark ? AppTheme.warningColor : AppTheme.lightWarningColor;
    } else if (status.toLowerCase() == 'sold' || status.toLowerCase() == 'deceased') {
      color = isDark ? AppTheme.dangerColor : AppTheme.lightDangerColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMeasurementChip({
    required IconData icon,
    required String value,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}