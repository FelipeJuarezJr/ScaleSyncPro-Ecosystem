import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'market_login_view.dart';

// ==========================================
// Marketplace Listing Model
// ==========================================
class MarketplaceListing {
  final String listingId;
  final String sellerId;
  final String sellerName;
  final String animalId;
  final String title;
  final double price;
  final List<String> morphs;
  final List<String> imageUrls;
  final DateTime listingDate;
  final List<double> verifiedPedigreeSnapshot;

  MarketplaceListing({
    required this.listingId,
    required this.sellerId,
    required this.sellerName,
    required this.animalId,
    required this.title,
    required this.price,
    required this.morphs,
    required this.imageUrls,
    required this.listingDate,
    required this.verifiedPedigreeSnapshot,
  });

  factory MarketplaceListing.fromFirestore(Map<String, dynamic> data) {
    // Parse price safely
    double parsedPrice = 0.0;
    if (data['price'] is num) {
      parsedPrice = (data['price'] as num).toDouble();
    }

    // Parse morphs safely
    List<String> parsedMorphs = [];
    if (data['morphs'] is List) {
      parsedMorphs = List<String>.from(data['morphs']);
    } else if (data['genetics'] is List) {
      parsedMorphs = List<String>.from(data['genetics']);
    }

    // Parse imageUrls safely
    List<String> parsedImages = [];
    if (data['imageUrls'] is List) {
      parsedImages = List<String>.from(data['imageUrls']);
    }

    // Parse date safely
    DateTime parsedDate = DateTime.now();
    if (data['listingDate'] is Timestamp) {
      parsedDate = (data['listingDate'] as Timestamp).toDate();
    }

    // Parse pedigree safely
    List<double> parsedPedigree = [];
    if (data['verifiedPedigreeSnapshot'] is List) {
      parsedPedigree = (data['verifiedPedigreeSnapshot'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return MarketplaceListing(
      listingId: data['listingId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Unknown Seller',
      animalId: data['animalId'] ?? '',
      title: data['title'] ?? 'Unnamed Reptile',
      price: parsedPrice,
      morphs: parsedMorphs,
      imageUrls: parsedImages,
      listingDate: parsedDate,
      verifiedPedigreeSnapshot: parsedPedigree,
    );
  }
}

// ==========================================
// Riverpod Data Providers
// ==========================================
final marketplaceListingsProvider = StreamProvider.autoDispose<List<MarketplaceListing>>((ref) {
  return FirebaseFirestore.instance
      .collection('marketplace_listings')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => MarketplaceListing.fromFirestore(doc.data()))
          .toList());
});

// ==========================================
// Main Marketplace Grid View
// ==========================================
class MarketplaceGridView extends ConsumerStatefulWidget {
  const MarketplaceGridView({super.key});

  @override
  ConsumerState<MarketplaceGridView> createState() => _MarketplaceGridViewState();
}

class _MarketplaceGridViewState extends ConsumerState<MarketplaceGridView> {
  String _searchQuery = '';
  double? _maxPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listingsAsync = ref.watch(marketplaceListingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeader(theme, isDark),
              const SizedBox(height: 20),

              // Filter/Search Row
              _buildFilterControls(isDark),
              const SizedBox(height: 24),

              // Listings Section
              Expanded(
                child: listingsAsync.when(
                  data: (listings) {
                    // Apply search and price filter
                    final filteredListings = listings.where((item) {
                      final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          item.morphs.any((m) => m.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                          item.sellerName.toLowerCase().contains(_searchQuery.toLowerCase());
                      final matchesPrice = _maxPrice == null || item.price <= _maxPrice!;
                      return matchesSearch && matchesPrice;
                    }).toList();

                    if (filteredListings.isEmpty) {
                      return _buildEmptyState(theme, isDark);
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 1200) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 768) {
                          crossAxisCount = 3;
                        }

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.76,
                          ),
                          itemCount: filteredListings.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(context, filteredListings[index], theme, isDark);
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Failed to load marketplace: $error',
                      style: const TextStyle(color: AppTheme.dangerColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GLOBAL STOREFRONT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ScaleSync Marketplace',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Browse and purchase premium verified genetics from certified breeders.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () async {
            if (isLoggedIn) {
              await authService.signOut();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MarketLoginView()),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: AppTheme.primaryColor,
            elevation: 0,
            side: const BorderSide(color: Color(0xFF2E2E2E)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            isLoggedIn ? '[ SIGN_OUT ]' : '[ SIGN_IN_TO_LIST ]',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search morphs, genetics, breeders...',
              prefixIcon: const Icon(Icons.search),
              fillColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<double?>(
          icon: Icon(
            Icons.filter_list,
            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
          ),
          onSelected: (val) {
            setState(() {
              _maxPrice = val;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: null,
              child: Text('Any Price'),
            ),
            const PopupMenuItem(
              value: 100.0,
              child: Text('Under \$100'),
            ),
            const PopupMenuItem(
              value: 250.0,
              child: Text('Under \$250'),
            ),
            const PopupMenuItem(
              value: 500.0,
              child: Text('Under \$500'),
            ),
            const PopupMenuItem(
              value: 1000.0,
              child: Text('Under \$1000'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary).withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Public Listings Found',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search queries or listing prices.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, MarketplaceListing listing, ThemeData theme, bool isDark) {
    final formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(listing.price);
    final hasImage = listing.imageUrls.isNotEmpty;
    final hasPedigree = listing.verifiedPedigreeSnapshot.isNotEmpty;

    return Card(
      color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        side: BorderSide(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
        ),
      ),
      child: InkWell(
        onTap: () => _showListingDetails(context, listing, isDark),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusLg)),
                    child: hasImage
                        ? Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(isDark),
                          )
                        : _buildImagePlaceholder(isDark),
                  ),
                  // Pedigree Verification Tag
                  if (hasPedigree)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified, size: 10, color: Colors.black),
                            SizedBox(width: 3),
                            Text(
                              'VERIFIED TRACKING',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Area
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breeder / Seller Info
                  Row(
                    children: [
                      Icon(
                        Icons.storefront,
                        size: 11,
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          listing.sellerName,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    listing.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Morphs list
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: listing.morphs.take(2).map((morph) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.primaryColor : AppTheme.lightSecondaryColor).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: (isDark ? AppTheme.primaryColor : AppTheme.lightSecondaryColor).withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          morph,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const Divider(height: 16),

                  // Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 11,
                        color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
      child: Icon(
        Icons.photo_outlined,
        size: 32,
        color: (isDark ? AppTheme.textLight : AppTheme.lightTextLight).withOpacity(0.5),
      ),
    );
  }

  // Show detailed listing modal with verified pedigree weight graph
  void _showListingDetails(BuildContext context, MarketplaceListing listing, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        final formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(listing.price);
        final theme = Theme.of(context);
        
        return Dialog(
          backgroundColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
            side: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image header
                  Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: listing.imageUrls.isNotEmpty
                            ? Image.network(
                                listing.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => _buildImagePlaceholder(isDark),
                              )
                            : _buildImagePlaceholder(isDark),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Detail Body
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller Row
                        Row(
                          children: [
                            Icon(Icons.storefront, size: 14, color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor),
                            const SizedBox(width: 6),
                            Text(
                              'Listed by ${listing.sellerName}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          listing.title,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Price tag
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Morphs
                        Text(
                          'Genetics / Morphs',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: listing.morphs.map((morph) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isDark ? AppTheme.primaryColor : AppTheme.lightSecondaryColor).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                                border: Border.all(
                                  color: (isDark ? AppTheme.primaryColor : AppTheme.lightSecondaryColor).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                morph,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // Verified Pedigree Weight Snapshot Graph
                        if (listing.verifiedPedigreeSnapshot.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.verified, size: 18, color: AppTheme.successColor),
                              const SizedBox(width: 8),
                              Text(
                                'Verified Facility Pedigree Weight Timeline',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This pedigree shows real, unmodified data directly streamed from the breeder\'s incubator/rack facility logs.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 160,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              border: Border.all(
                                color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                              ),
                            ),
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) => Text(
                                        '${value.toInt()}g',
                                        style: TextStyle(
                                          color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index >= 0 && index < listing.verifiedPedigreeSnapshot.length) {
                                          return Text(
                                            'P$index',
                                            style: TextStyle(
                                              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                                              fontSize: 9,
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                borderData: FlBorderData(show: false),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: listing.verifiedPedigreeSnapshot
                                        .asMap()
                                        .entries
                                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                                        .toList(),
                                    isCurved: true,
                                    color: AppTheme.successColor,
                                    barWidth: 3,
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 3,
                                          color: AppTheme.successColor,
                                          strokeWidth: 1.5,
                                          strokeColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No historical pedigree weights logged for this animal.',
                                    style: TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Contacting ${listing.sellerName} to purchase genetics...'),
                                  backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment, color: Colors.black),
                            label: const Text('Acquire Genetics', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
