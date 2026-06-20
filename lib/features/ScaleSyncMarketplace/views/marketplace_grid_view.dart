import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/services/theme_service.dart';
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
      for (final e in (data['verifiedPedigreeSnapshot'] as List)) {
        if (e is num) {
          parsedPedigree.add(e.toDouble());
        }
        // Non-numeric entries (e.g. null, String) are silently skipped.
      }
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
List<MarketplaceListing> _getMockListings() {
  return [
    MarketplaceListing(
      listingId: 'mock_1',
      sellerId: 'seller_1',
      sellerName: 'ReptileRanch',
      animalId: 'anim_1',
      title: 'Ball Python',
      price: 450.0,
      morphs: ['Pastel Clown'],
      imageUrls: ['https://images.unsplash.com/photo-1531386151447-fd76ad50012f?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 2)),
      verifiedPedigreeSnapshot: [1.2, 1.5, 1.8],
    ),
    MarketplaceListing(
      listingId: 'mock_2',
      sellerId: 'seller_2',
      sellerName: 'GeckoGuild',
      animalId: 'anim_2',
      title: 'Crested Gecko',
      price: 185.0,
      morphs: ['Flame Pinstripe'],
      imageUrls: ['https://images.unsplash.com/photo-1504450758481-7338ecc7524a?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 4)),
      verifiedPedigreeSnapshot: [0.8, 0.9],
    ),
    MarketplaceListing(
      listingId: 'mock_3',
      sellerId: 'seller_3',
      sellerName: 'SkinkSource',
      animalId: 'anim_3',
      title: 'Blue Tongue Skink',
      price: 320.0,
      morphs: ['Northern BTS'],
      imageUrls: ['https://images.unsplash.com/photo-1629157257475-2735b48e4c56?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 6)),
      verifiedPedigreeSnapshot: [],
    ),
    MarketplaceListing(
      listingId: 'mock_4',
      sellerId: 'seller_4',
      sellerName: 'ChromaCham',
      animalId: 'anim_4',
      title: 'Panther Chameleon',
      price: 780.0,
      morphs: ['Ambilobe'],
      imageUrls: ['https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 8)),
      verifiedPedigreeSnapshot: [2.1],
    ),
    MarketplaceListing(
      listingId: 'mock_5',
      sellerId: 'seller_5',
      sellerName: 'TortoiseTown',
      animalId: 'anim_5',
      title: 'Sulcata Tortoise',
      price: 210.0,
      morphs: ['Standard'],
      imageUrls: ['https://images.unsplash.com/photo-1508817628294-5a453fa0b8fb?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 10)),
      verifiedPedigreeSnapshot: [],
    ),
    MarketplaceListing(
      listingId: 'mock_6',
      sellerId: 'seller_6',
      sellerName: 'LeoLair',
      animalId: 'anim_6',
      title: 'Leopard Gecko',
      price: 95.0,
      morphs: ['Tangerine Tremper'],
      imageUrls: ['https://images.unsplash.com/photo-1551085254-e96b210db58a?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 12)),
      verifiedPedigreeSnapshot: [0.5, 0.6],
    ),
    MarketplaceListing(
      listingId: 'mock_7',
      sellerId: 'seller_7',
      sellerName: 'SerpentineStudio',
      animalId: 'anim_7',
      title: 'Corn Snake',
      price: 140.0,
      morphs: ['Tessera Motley'],
      imageUrls: ['https://images.unsplash.com/photo-1604608684575-0497c3a5270c?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 14)),
      verifiedPedigreeSnapshot: [],
    ),
    MarketplaceListing(
      listingId: 'mock_8',
      sellerId: 'seller_8',
      sellerName: 'ExoticEdge',
      animalId: 'anim_8',
      title: 'Blue Iguana',
      price: 1200.0,
      morphs: ['Lesser Antilles'],
      imageUrls: ['https://images.unsplash.com/photo-1546182990-dffeafbe841d?auto=format&fit=crop&q=80&w=600'],
      listingDate: DateTime.now().subtract(const Duration(hours: 16)),
      verifiedPedigreeSnapshot: [1.5],
    ),
  ];
}

final marketplaceListingsProvider = StreamProvider.autoDispose<List<MarketplaceListing>>((ref) {
  return FirebaseFirestore.instance
      .collection('marketplace_listings')
      .snapshots()
      .map((snapshot) {
        // Parse each document individually so one bad doc never crashes the entire stream.
        final docs = <MarketplaceListing>[];
        for (final doc in snapshot.docs) {
          try {
            docs.add(MarketplaceListing.fromFirestore(doc.data()));
          } catch (e) {
            // Skip this document — it may have an unexpected schema.
            // ignore: avoid_print
            print('[MarketplaceProvider] Skipped malformed doc ${doc.id}: $e');
          }
        }
        if (docs.isEmpty) {
          // No live docs (or all failed to parse) — show demo data.
          return _getMockListings();
        }
        return docs;
      })
      .handleError((_) {
        // On Firestore permission or network errors, fall back to mock data
        // so the grid is never left blank.
        return _getMockListings();
      });
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
  String _selectedCategory = 'All';
  bool _onlyVerified = false;
  String _sortBy = 'Newest';
  int _activeBottomTab = 1; // Default to 'Browse' (index 1)
  final Set<String> _favoritedListings = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listingsAsync = ref.watch(marketplaceListingsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
      bottomNavigationBar: isDesktop ? null : _buildBottomNavigationBar(isDark),
      body: Stack(
        children: [
          // Background layout with premium radial gradients (orbs)
          _buildBackgroundOrbs(isDark),
          
          // Main layout content
          SafeArea(
            child: Column(
              children: [
                // Sticky Top Nav
                _buildTopNav(isDark),
                
                // Scrollable main content viewport
                Expanded(
                  child: listingsAsync.when(
                    data: (listings) {
                      // Apply search, price, verified, category, and SAVED filter
                      final filteredListings = listings.where((item) {
                        if (_activeBottomTab == 3) {
                          if (!_favoritedListings.contains(item.listingId)) {
                            return false;
                          }
                        }
                        
                        final matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            item.morphs.any((m) => m.toLowerCase().contains(_searchQuery.toLowerCase())) ||
                            item.sellerName.toLowerCase().contains(_searchQuery.toLowerCase());
                            
                        final matchesPrice = _maxPrice == null || item.price <= _maxPrice!;
                        
                        final matchesVerified = !_onlyVerified || item.verifiedPedigreeSnapshot.isNotEmpty;
                        
                        bool matchesCategory = true;
                        if (_selectedCategory != 'All') {
                          final catLower = _selectedCategory.toLowerCase();
                          final titleLower = item.title.toLowerCase();
                          if (catLower == 'snakes') {
                            matchesCategory = titleLower.contains('python') || titleLower.contains('snake') || titleLower.contains('boa');
                          } else if (catLower == 'geckos') {
                            matchesCategory = titleLower.contains('gecko');
                          } else if (catLower == 'lizards') {
                            matchesCategory = titleLower.contains('lizard') || titleLower.contains('skink') || titleLower.contains('chameleon') || titleLower.contains('gecko');
                          } else if (catLower == 'tortoises') {
                            matchesCategory = titleLower.contains('tortoise') || titleLower.contains('turtle') || titleLower.contains('sulcata');
                          } else if (catLower == 'chameleons') {
                            matchesCategory = titleLower.contains('chameleon') || titleLower.contains('panther');
                          }
                        }
                        
                        return matchesSearch && matchesPrice && matchesVerified && matchesCategory;
                      }).toList();

                      // Apply sorting
                      if (_sortBy == 'Price: Low to High') {
                        filteredListings.sort((a, b) => a.price.compareTo(b.price));
                      } else if (_sortBy == 'Price: High to Low') {
                        filteredListings.sort((a, b) => b.price.compareTo(a.price));
                      } else {
                        // Newest
                        filteredListings.sort((a, b) => b.listingDate.compareTo(a.listingDate));
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(marketplaceListingsProvider);
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Search input (mobile only)
                              if (MediaQuery.of(context).size.width <= 900) ...[
                                _buildSearchField(isDark),
                                const SizedBox(height: 12),
                              ],
                              
                              // Hero promotional banner
                              _buildHeroBanner(isDark),
                              const SizedBox(height: 16),
                              
                              // Category pills
                              _buildCategoryPills(isDark),
                              const SizedBox(height: 16),

                              // Features Grid
                              _buildFeaturesGrid(isDark),
                              const SizedBox(height: 16),
                              
                              // Results Header
                              _buildResultsHeader(filteredListings.length, isDark),
                              const SizedBox(height: 12),

                              // Filters & Sort Bar
                              _buildFilterControls(isDark),
                              const SizedBox(height: 12),
                              
                              // Main listings grid or empty state
                              filteredListings.isEmpty
                                  ? _buildEmptyState(theme, isDark)
                                  : _buildResponsiveGrid(filteredListings, theme, isDark),
                              
                              const SizedBox(height: 20),
                              
                              // Pagination
                              _buildPagination(isDark),
                            ],
                          ),
                        ),
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
        ],
      ),
    );
  }

  // ==========================================
  // Layout Helper Widgets & Styling
  // ==========================================

  Widget _buildBackgroundOrbs(bool isDark) {
    if (!isDark) {
      return Container(color: AppTheme.lightBgSecondary);
    }
    return Stack(
      children: [
        Container(
          color: AppTheme.bgPrimary,
        ),
        // Glowing Orb 1 (Top-Left)
        Positioned(
          top: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x1F00D2FF), // AppTheme.primaryLight (cyan) with 12% opacity
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Glowing Orb 2 (Bottom-Right)
        Positioned(
          bottom: -200,
          right: -200,
          child: Container(
            width: 600,
            height: 600,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0x1F00E676), // AppTheme.primaryColor (green) with 12% opacity
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopNav(bool isDark) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final isLoggedIn = authService.isAuthenticated;
    final userData = authService.userData;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    if (isDesktop) {
      return Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF0F100D), // dark background matching mockup
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Left: Logo and Brand Name
            Row(
              children: [
                Icon(
                  Icons.drag_indicator,
                  size: 32,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'ScaleSync Marketplace',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),

            // Search Bar
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 380,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1D17), // very dark background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.grey.shade500,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search reptiles, breeds, sellers...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Navigation Links
            Row(
              children: [
                _buildNavLink('Browse', () {
                  setState(() {
                    _activeBottomTab = 0; // Browse/Home
                  });
                }),
                _buildNavLink('Sell', () {
                  _showSellDialog(isDark);
                }),
                _buildNavLink('Community', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Navigating to community feed...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }),
                _buildNavLink('Help', () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('For support, contact support@scalesync.com'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(width: 8),

            // Vertical divider
            Container(
              height: 24,
              width: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            const SizedBox(width: 16),

            // List Animal Button
            ElevatedButton.icon(
              onPressed: () {
                _showSellDialog(isDark);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5E644),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              icon: const Icon(Icons.add, size: 14, color: Colors.black),
              label: const Text(
                'List Animal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Avatar circle menu button
            if (isLoggedIn)
              _MarketplaceUserMenuButton(
                userData: userData,
                themeService: themeService,
                authService: authService,
              )
            else
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MarketLoginView()),
                  );
                },
                icon: const Icon(Icons.login, size: 16, color: Color(0xFFA5E644)),
                label: const Text(
                  'Sign In',
                  style: TextStyle(color: Color(0xFFA5E644), fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    // Mobile fallback top bar
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary,
        boxShadow: AppTheme.shadowSm,
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.drag_indicator,
                    size: 24,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ScaleSync Marketplace',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isLoggedIn)
                    _MarketplaceUserMenuButton(
                      userData: userData,
                      themeService: themeService,
                      authService: authService,
                    )
                  else
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MarketLoginView()),
                        );
                      },
                      icon: const Icon(Icons.login),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161810) : AppTheme.lightBgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderColor.withOpacity(0.5) : AppTheme.lightBorderColor,
        ),
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style: TextStyle(
          color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search reptiles, morphs, sellers...',
          hintStyle: TextStyle(
            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
            size: 20,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 768;

    return Container(
      height: isDesktop ? 360 : 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: const DecorationImage(
          image: AssetImage('assets/images/snake_scales_hero_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Premium dark gradient mask overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 40 : 20,
              vertical: isDesktop ? 20 : 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Live badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA5E644).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFA5E644), width: 1),
                      ),
                      child: const Text(
                        'LIVE ANIMALS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA5E644),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '2,400+ verified listings',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: isDesktop ? 38 : 22,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                      color: Colors.white,
                    ),
                    children: const [
                      TextSpan(text: 'Find Your Next\n'),
                      TextSpan(
                        text: 'Exotic Companion',
                        style: TextStyle(
                          color: Color(0xFFA5E644), // light green accent
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : 6),
                Container(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 500 : 300),
                  child: Text(
                    'Ethically sourced reptiles from verified breeders across the country. Every animal health-checked and documented.',
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 11,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 20 : 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA5E644),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 20 : 12,
                          vertical: isDesktop ? 16 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Browse Listings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade600),
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 20 : 12,
                          vertical: isDesktop ? 16 : 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'How It Works',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPills(bool isDark) {
    final categories = [
      {'label': 'All', 'count': '2.4k', 'icon': '✨'},
      {'label': 'Snakes', 'count': '840', 'icon': '🐍'},
      {'label': 'Geckos', 'count': '610', 'icon': '🦎'},
      {'label': 'Lizards', 'count': '390', 'icon': '🦎'},
      {'label': 'Tortoises', 'count': '210', 'icon': '🐢'},
      {'label': 'Chameleons', 'count': '140', 'icon': '🦎'},
      {'label': 'Monitors', 'count': '95', 'icon': '🦎'},
      {'label': 'Iguanas', 'count': '72', 'icon': '🦎'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['label'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat['label']!;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFA5E644)
                    : (isDark ? const Color(0xFF141511) : AppTheme.lightBgPrimary),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFA5E644)
                      : (isDark ? AppTheme.borderColor.withOpacity(0.15) : AppTheme.lightBorderColor),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    cat['icon']!,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label']!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.black
                          : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cat['count']!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.black.withOpacity(0.7)
                          : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturesGrid(bool isDark) {
    final features = [
      {
        'icon': Icons.verified_outlined,
        'title': 'Verified Breeders',
        'desc': 'Every seller vetted',
      },
      {
        'icon': Icons.favorite_border_rounded,
        'title': 'Health Guarantee',
        'desc': 'Backed by our policy',
      },
      {
        'icon': Icons.local_shipping_outlined,
        'title': 'Safe Live Delivery',
        'desc': 'Live arrival guaranteed',
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Full Lineage History',
        'desc': 'Morphs, lineage, age',
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: features.map((f) => _buildFeatureCard(f, isDark, true)).toList(),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth / 300,
          children: features.map((f) => _buildFeatureCard(f, isDark, false)).toList(),
        );
      },
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> f, bool isDark, bool isMobile) {
    return Container(
      width: isMobile ? 220 : null,
      margin: isMobile ? const EdgeInsets.only(right: 8) : EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141511) : AppTheme.lightBgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppTheme.borderColor.withOpacity(0.15) : AppTheme.lightBorderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            f['icon'] as IconData,
            color: const Color(0xFFA5E644),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  f['title'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  f['desc'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    final filterPills = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter Tune Pill
        _buildFilterPill(
          label: 'Filters',
          icon: Icons.tune,
          isSelected: _onlyVerified || _maxPrice != null,
          onTap: () => _showFilterOptionsDialog(isDark),
          isDark: isDark,
        ),
        const SizedBox(width: 8),
        
        // Price Pill
        PopupMenuButton<double?>(
          initialValue: _maxPrice,
          onSelected: (val) {
            setState(() {
              _maxPrice = val;
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: null, child: Text('Any Price')),
            const PopupMenuItem(value: 100.0, child: Text('Under \$100')),
            const PopupMenuItem(value: 250.0, child: Text('Under \$250')),
            const PopupMenuItem(value: 500.0, child: Text('Under \$500')),
            const PopupMenuItem(value: 1000.0, child: Text('Under \$1000')),
          ],
          child: _buildFilterPill(
            label: _maxPrice == null ? 'Price' : '<\$${_maxPrice!.toInt()}',
            icon: Icons.keyboard_arrow_down,
            isSelected: _maxPrice != null,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),

        // Age Pill
        PopupMenuButton<String>(
          initialValue: 'Any Age',
          onSelected: (val) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Filter by age: $val'), behavior: SnackBarBehavior.floating),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Any Age', child: Text('Any Age')),
            const PopupMenuItem(value: 'Baby', child: Text('Baby')),
            const PopupMenuItem(value: 'Juvenile', child: Text('Juvenile')),
            const PopupMenuItem(value: 'Adult', child: Text('Adult')),
          ],
          child: _buildFilterPill(
            label: 'Age',
            icon: Icons.keyboard_arrow_down,
            isSelected: false,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),

        // Sex Pill
        PopupMenuButton<String>(
          initialValue: 'Any Sex',
          onSelected: (val) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Filter by sex: $val'), behavior: SnackBarBehavior.floating),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Any Sex', child: Text('Any Sex')),
            const PopupMenuItem(value: 'Male', child: Text('Male')),
            const PopupMenuItem(value: 'Female', child: Text('Female')),
            const PopupMenuItem(value: 'Unknown', child: Text('Unknown')),
          ],
          child: _buildFilterPill(
            label: 'Sex',
            icon: Icons.keyboard_arrow_down,
            isSelected: false,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 8),
        
        // Verified Pill
        _buildFilterPill(
          label: 'Verified Only',
          icon: _onlyVerified ? Icons.check : Icons.keyboard_arrow_down,
          isSelected: _onlyVerified,
          onTap: () {
            setState(() {
              _onlyVerified = !_onlyVerified;
            });
          },
          isDark: isDark,
        ),
      ],
    );

    final sortDropdown = PopupMenuButton<String>(
      initialValue: _sortBy,
      onSelected: (val) {
        setState(() {
          _sortBy = val;
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Newest', child: Text('Newest')),
        const PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
        const PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sort: ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
            ),
          ),
          Text(
            _sortBy,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: filterPills)),
          const SizedBox(width: 16),
          sortDropdown,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: filterPills,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: sortDropdown,
          ),
        ],
      );
    }
  }

  Widget _buildFilterPill({
    required String label,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
    required bool isDark,
  }) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? AppTheme.primaryColor.withOpacity(0.15) : AppTheme.lightPrimaryColor.withOpacity(0.1))
            : (isDark ? const Color(0xFF141511) : AppTheme.lightBgPrimary),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
              : (isDark ? AppTheme.borderColor.withOpacity(0.15) : AppTheme.lightBorderColor),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
                  : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            icon,
            size: 13,
            color: isSelected
                ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
                : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  void _showFilterOptionsDialog(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusLg)),
                border: Border.all(
                  color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filter Options',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Verified only toggle
                  SwitchListTile(
                    title: const Text('Verified Tracking logs only'),
                    subtitle: const Text('Only show reptiles with direct incubator/scale updates'),
                    value: _onlyVerified,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _onlyVerified = val;
                      });
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Price slider or options
                  const Text(
                    'Price Limit',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_maxPrice == null ? 'Any Price' : 'Under \$${_maxPrice!.toInt()}'),
                      if (_maxPrice != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _maxPrice = null;
                            });
                            setModalState(() {});
                          },
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  Slider(
                    value: _maxPrice ?? 1500.0,
                    min: 50.0,
                    max: 1500.0,
                    divisions: 29,
                    activeColor: AppTheme.primaryColor,
                    label: _maxPrice == null ? 'Any' : '\$${_maxPrice!.toInt()}',
                    onChanged: (val) {
                      setState(() {
                        _maxPrice = val == 1500.0 ? null : val;
                      });
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildResultsHeader(int count, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'All Listings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Row(
            children: [
              Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFFA5E644),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward,
                color: Color(0xFFA5E644),
                size: 14,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPaginationButton('<', false, isDark),
            const SizedBox(width: 8),
            _buildPaginationButton('1', true, isDark),
            const SizedBox(width: 8),
            _buildPaginationButton('2', false, isDark),
            const SizedBox(width: 8),
            _buildPaginationButton('3', false, isDark),
            const SizedBox(width: 8),
            _buildPaginationButton('...', false, isDark, isDots: true),
            const SizedBox(width: 8),
            _buildPaginationButton('24', false, isDark),
            const SizedBox(width: 8),
            _buildPaginationButton('>', false, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationButton(String label, bool isActive, bool isDark, {bool isDots = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFA5E644)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: !isActive && !isDots
            ? Border.all(
                color: isDark ? AppTheme.borderColor.withOpacity(0.15) : AppTheme.lightBorderColor,
              )
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.black
                : (isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
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
              _activeBottomTab == 3 ? 'No Saved Listings' : 'No Public Listings Found',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _activeBottomTab == 3 
                  ? 'Tap the heart icon on any reptile card to save it here.'
                  : 'Try adjusting your search queries or listing prices.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<MarketplaceListing> listings, ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 768) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.70, // Fits bottom card layout details perfectly
          ),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, listings[index], theme, isDark);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, MarketplaceListing listing, ThemeData theme, bool isDark) {
    final formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(listing.price);
    final hasImage = listing.imageUrls.isNotEmpty;
    final hasPedigree = listing.verifiedPedigreeSnapshot.isNotEmpty;
    final isFavorited = _favoritedListings.contains(listing.listingId);

    // Stable mock location based on seller name
    final String location = _getStableLocation(listing.sellerName);

    // Categories and morph formatting
    final primaryMorph = listing.morphs.isNotEmpty ? listing.morphs.first : 'Normal';
    final speciesType = _inferSpecies(listing.title);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderColor.withOpacity(0.6) : AppTheme.lightBorderColor,
          width: 1,
        ),
        boxShadow: isDark ? AppTheme.shadowSm : null,
      ),
      child: InkWell(
        onTap: () => _showListingDetails(context, listing, isDark),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Area (4:3 ratio)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: hasImage
                        ? Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(isDark),
                          )
                        : _buildImagePlaceholder(isDark),
                  ),
                  
                  // Featured Badge (Top-Left)
                  if (hasPedigree)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor, // Premium orange
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  
                  // Favorite Button (Top-Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFavorited) {
                            _favoritedListings.remove(listing.listingId);
                          } else {
                            _favoritedListings.add(listing.listingId);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.4),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorited),
                            size: 16,
                            color: isFavorited ? Colors.red : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title and Price info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                speciesType,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.15,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedPrice,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          primaryMorph,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    
                    // Separator line
                    Divider(
                      height: 12,
                      color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor,
                    ),
                    
                    // Footer (Location & Seller Name)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Location (Map pin)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 11,
                                color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Seller Name with verified check icon
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 11,
                              color: isDark ? AppTheme.primaryColor.withOpacity(0.8) : AppTheme.lightPrimaryLight,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              listing.sellerName,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                              ),
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

  String _getStableLocation(String sellerName) {
    final list = [
      'Austin, TX',
      'Miami, FL',
      'Denver, CO',
      'Dallas, TX',
      'Phoenix, AZ',
      'Orlando, FL',
      'San Jose, CA',
      'Atlanta, GA',
    ];
    final hash = sellerName.hashCode.abs();
    return list[hash % list.length];
  }

  String _inferSpecies(String title) {
    final lowercase = title.toLowerCase();
    if (lowercase.contains('python') || lowercase.contains('snake') || lowercase.contains('boa')) {
      return 'Ball Python';
    } else if (lowercase.contains('gecko')) {
      return 'Gecko';
    } else if (lowercase.contains('skink') || lowercase.contains('lizard')) {
      return 'Lizard';
    } else if (lowercase.contains('tortoise') || lowercase.contains('turtle')) {
      return 'Tortoise';
    } else if (lowercase.contains('chameleon')) {
      return 'Chameleon';
    }
    return 'Reptile';
  }

  Widget _buildLoadMoreButton(int count, bool isDark) {
    if (count == 0) return const SizedBox.shrink();
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'Showing $count of $count results',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All available listings have been loaded.'),
                  backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF161810) : AppTheme.lightBgPrimary,
              foregroundColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
              side: BorderSide(
                color: isDark ? AppTheme.borderColor.withOpacity(0.5) : AppTheme.lightBorderColor,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Load More',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Bottom Navigation Bar Implementation
  // ==========================================

  Widget _buildBottomNavigationBar(bool isDark) {
    final tabs = [
      {'label': 'Home', 'icon': Icons.home_outlined, 'activeIcon': Icons.home},
      {'label': 'Browse', 'icon': Icons.explore_outlined, 'activeIcon': Icons.explore},
      {'label': 'Sell', 'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle},
      {'label': 'Saved', 'icon': Icons.favorite_border, 'activeIcon': Icons.favorite},
      {'label': 'Profile', 'icon': Icons.person_outline, 'activeIcon': Icons.person},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgPrimary.withOpacity(0.9) : AppTheme.lightBgPrimary.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.borderColor.withOpacity(0.3) : AppTheme.lightBorderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isActive = _activeBottomTab == index;
              
              return GestureDetector(
                onTap: () {
                  _onBottomTabTapped(index, isDark);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (isActive ? tab['activeIcon'] : tab['icon']) as IconData,
                      size: 22,
                      color: isActive
                          ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
                          : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive
                            ? (isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor)
                            : (isDark ? AppTheme.textLight : AppTheme.lightTextLight),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  void _onBottomTabTapped(int index, bool isDark) {
    if (index == 1) {
      // Browse
      setState(() {
        _activeBottomTab = 1;
        _selectedCategory = 'All';
      });
      return;
    }
    
    if (index == 2) {
      // Sell
      final authService = legacy_provider.Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to list animals on the marketplace.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MarketLoginView()),
        );
      } else {
        _showSellDialog(isDark);
      }
      return;
    }

    if (index == 3) {
      // Saved tab (Favorites)
      setState(() {
        _activeBottomTab = 3;
      });
      return;
    }

    if (index == 4) {
      // Profile
      final authService = legacy_provider.Provider.of<AuthService>(context, listen: false);
      _showProfileOptions(authService.isAuthenticated, authService, isDark);
      return;
    }

    if (index == 0) {
      // Home tab
      setState(() {
        _activeBottomTab = 0;
        _selectedCategory = 'All';
        _searchQuery = '';
        _maxPrice = null;
        _onlyVerified = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Back to Home - filters cleared.'),
          backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }
  }

  void _showSellDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor),
        ),
        title: const Text('Sell Reptiles'),
        content: const Text(
          'To list an animal for sale, go to your Collection rack inventory, select the reptile, and click the "List on Marketplace" button.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showProfileOptions(bool isLoggedIn, AuthService authService, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusLg)),
            border: Border.all(
              color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isLoggedIn ? 'Account Center' : 'Welcome to ScaleMarket',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isLoggedIn) ...[
                Text(
                  'Signed in as: ${authService.currentUser?.email ?? "Certified Breeder"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await authService.signOut();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Successfully signed out.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                  label: const Text('Sign Out', style: TextStyle(color: AppTheme.dangerColor)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.dangerColor),
                  ),
                ),
              ] else ...[
                Text(
                  'Sign in to list your inventory and message buyers/sellers.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MarketLoginView()),
                    );
                  },
                  child: const Text('Sign In to Account'),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // Detailed Product Modal Popup
  // ==========================================

  void _showListingDetails(BuildContext context, MarketplaceListing listing, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        final formattedPrice = NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(listing.price);
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
                  // Image header with Close Button
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

                  // Detail Body Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Seller Row info
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

                        // Listing Title
                        Text(
                          listing.title,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        // Listing Price
                        Text(
                          formattedPrice,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Genetics/Morphs list
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
                              const Icon(Icons.verified, size: 18, color: AppTheme.successColor),
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
                                gridData: const FlGridData(show: false),
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
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                                    barWidth: 3.5,
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.successColor.withOpacity(0.25),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                    dotData: FlDotData(
                                      show: true,
                                      getDotPainter: (spot, percent, barData, index) {
                                        return FlDotCirclePainter(
                                          radius: 4,
                                          color: AppTheme.successColor,
                                          strokeWidth: 2,
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
                            child: const Row(
                              children: [
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

class _MarketplaceUserMenuButton extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final ThemeService themeService;
  final AuthService authService;

  const _MarketplaceUserMenuButton({
    required this.userData,
    required this.themeService,
    required this.authService,
  });

  @override
  State<_MarketplaceUserMenuButton> createState() => _MarketplaceUserMenuButtonState();
}

class _MarketplaceUserMenuButtonState extends State<_MarketplaceUserMenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    final showHovered = isMobile || _isHovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<String>(
        offset: const Offset(0, 36),
        icon: Icon(
          Icons.account_circle,
          size: 24,
          color: showHovered ? const Color(0xFF00FF00) : AppTheme.textSecondary,
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData?['name'] ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.userData?['email'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 8),
                Text('Profile'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings, size: 16),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'help',
            child: Row(
              children: [
                Icon(Icons.help, size: 16),
                SizedBox(width: 8),
                Text('Help'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'theme',
            child: Row(
              children: [
                Icon(
                  widget.themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(widget.themeService.isDarkMode ? 'Switch to Light' : 'Switch to Dark'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 16),
                SizedBox(width: 8),
                Text('Sign Out'),
              ],
            ),
          ),
        ],
        onSelected: (value) async {
          switch (value) {
            case 'theme':
              widget.themeService.toggleTheme();
              break;
            case 'logout':
              await widget.authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MarketLoginView()),
                  (route) => false,
                );
              }
              break;
            case 'profile':
            case 'settings':
            case 'help':
              // Handle other actions here
              break;
          }
        },
      ),
    );
  }
}
