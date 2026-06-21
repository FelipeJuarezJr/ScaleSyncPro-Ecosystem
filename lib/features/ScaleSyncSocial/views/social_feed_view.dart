import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/services/theme_service.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'social_login_view.dart';
import 'dart:math' as math;

class SocialFeedView extends StatefulWidget {
  const SocialFeedView({super.key});

  @override
  State<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<SocialFeedView> {
  String _activeMobileTab = 'Feed'; // 'Feed' | 'Analytics' | 'Control'
  String _feedFilter = 'All'; // 'All' | 'Media' | 'Text'
  final TextEditingController _broadcastController = TextEditingController();
  final List<String> _myPosts = [];

  // Likes state tracking
  final Set<int> _likedPostIndices = {};

  @override
  void dispose() {
    _broadcastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth > 768 && screenWidth <= 1024;
    final isMobile = screenWidth <= 768;

    final mockUpdates = [
      _MorphUpdatePost(
        breederName: 'MorphLabs Geneticist',
        avatarText: 'ML',
        timeAgo: '12m ago',
        morphTitle: 'Super Pastel Pied Clutch Hatched!',
        morphContent: 'Incredible success today with our Pied lines. Out of 6 eggs, 4 hatched with full visual expression. High-white patterns and bright yellow coloration are showing exceptional high-contrast marks. Pedigree logging synced.',
        morphTags: ['Super Pastel', 'Piebald', 'Verified Lineage'],
        likes: 42,
        comments: 8,
        shares: 15,
        hasMedia: true,
      ),
      _MorphUpdatePost(
        breederName: 'Krypton Reptiles',
        avatarText: 'KR',
        timeAgo: '1h ago',
        morphTitle: 'Banana Clown Weight Log Verified',
        morphContent: 'Just updated our official facility rack log. Our primary male has officially hit 980g, showing stable growth curves. View the verified lineage path under ScaleSync Pro network code nodes.',
        morphTags: ['Banana Clown', 'Rack Logs', 'Pedigree Sync'],
        likes: 29,
        comments: 3,
        shares: 4,
        hasMedia: false,
      ),
      _MorphUpdatePost(
        breederName: 'Desert Herps',
        avatarText: 'DH',
        timeAgo: '4h ago',
        morphTitle: 'Albino Green Tree Python Update',
        morphContent: 'First shed complete! The neon yellow phase is extremely vivid. We have logged their shed records and temperatures successfully into the blockchain tracker for buyers to inspect.',
        morphTags: ['Albino GTP', 'First Shed', 'Public Incubator'],
        likes: 56,
        comments: 12,
        shares: 22,
        hasMedia: true,
      ),
    ];

    // Combine local user custom broadcasts into the feed list
    final List<_MorphUpdatePost> allPosts = [];
    
    // Add user's custom posts first
    for (int i = 0; i < _myPosts.length; i++) {
      allPosts.add(
        _MorphUpdatePost(
          breederName: authService.currentUser?.email?.split('@').first ?? 'You',
          avatarText: 'U',
          timeAgo: 'Just now',
          morphTitle: 'Broadcast Update',
          morphContent: _myPosts[i],
          morphTags: ['Broadcast', 'LiveFeed'],
          likes: 0,
          comments: 0,
          shares: 0,
          hasMedia: false,
        ),
      );
    }
    
    allPosts.addAll(mockUpdates);

    // Apply Filter
    final filteredPosts = allPosts.where((post) {
      if (_feedFilter == 'Media') return post.hasMedia;
      if (_feedFilter == 'Text') return !post.hasMedia;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary, // Obsidian dark
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Brand Header
            _buildHeader(context, authService, isLoggedIn, isMobile),

            // Telemetry stats row (always visible on top, wrapping dynamically)
            _buildStatsStrip(allPosts, isMobile),

            // Segmented Tab switcher for mobile viewports
            if (isMobile) _buildMobileTabsSelector(),

            // Main Columns Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Builder(
                  builder: (context) {
                    if (isDesktop) {
                      // 3-Column Layout: Feed | Charts | Control Deck
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 12,
                            child: _buildFeedColumn(filteredPosts),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 10,
                            child: _buildAnalyticsColumn(allPosts.length),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 10,
                            child: _buildControlColumn(),
                          ),
                        ],
                      );
                    } else if (isTablet) {
                      // 2-Column Layout: Feed | Right Panel (Analytics + Control)
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildFeedColumn(filteredPosts),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildAnalyticsColumn(allPosts.length),
                                  const SizedBox(height: 20),
                                  _buildControlColumn(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile View: Renders only active tab
                      switch (_activeMobileTab) {
                        case 'Analytics':
                          return SingleChildScrollView(
                            child: _buildAnalyticsColumn(allPosts.length),
                          );
                        case 'Control':
                          return SingleChildScrollView(
                            child: _buildControlColumn(),
                          );
                        case 'Feed':
                        default:
                          return _buildFeedColumn(filteredPosts);
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context, AuthService authService, bool isLoggedIn, bool isMobile) {
    final themeService = legacy_provider.Provider.of<ThemeService>(context);
    final userData = authService.userData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          bottom: BorderSide(color: Color(0xFF222222), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.drag_indicator,
                size: 28,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'ScaleSync Social',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Pro Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                ),
                child: const Text(
                  'Pro',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // User Name
              Text(
                userData?['name'] ?? authService.currentUser?.displayName ?? authService.currentUser?.email?.split('@')[0] ?? 'Gecko1',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 15),
              _SocialUserMenuButton(
                userData: userData,
                themeService: themeService,
                authService: authService,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Telemetry Stats Strip ---
  Widget _buildStatsStrip(List<_MorphUpdatePost> posts, bool isMobile) {
    final totalLikes = posts.fold(0, (sum, p) => sum + p.likes) + _likedPostIndices.length;
    final mediaCount = posts.where((p) => p.hasMedia).length;
    final mediaRatio = posts.isNotEmpty ? (mediaCount / posts.length * 100).round() : 0;
    final reach = posts.length * 145 + 320;
    final engagement = posts.isNotEmpty ? ((totalLikes / posts.length) * 0.8 + 2.1).toStringAsFixed(1) : '0.0';

    if (isMobile) {
      // In mobile, display compact stats grid layout
      return Container(
        padding: const EdgeInsets.all(12),
        color: const Color(0xFF131313),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildStatItem('Reach', reach.toString(), '+12.4%', Icons.visibility, Colors.green),
            _buildStatItem('Likes', totalLikes.toString(), '+8.2%', Icons.favorite, AppTheme.primaryLight),
            _buildStatItem('Engagement', '$engagement%', '+0.5%', Icons.analytics, AppTheme.accentColor),
            _buildStatItem('Media Ratio', '$mediaRatio%', '$mediaCount/posts', Icons.photo_library, Colors.purple),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: const Color(0xFF131313),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Total Reach', reach.toString(), '+12.4%', Icons.visibility, Colors.green)),
          const SizedBox(width: 15),
          Expanded(child: _buildStatItem('Total Likes', totalLikes.toString(), '+8.2%', Icons.favorite, AppTheme.primaryLight)),
          const SizedBox(width: 15),
          Expanded(child: _buildStatItem('Engagement', '$engagement%', '+0.5%', Icons.analytics, AppTheme.accentColor)),
          const SizedBox(width: 15),
          Expanded(child: _buildStatItem('Media Ratio', '$mediaRatio%', '$mediaCount of ${posts.length} posts', Icons.photo_library, Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String subText, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 10, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Text(
            subText,
            style: TextStyle(
              color: subText.startsWith('+') ? Colors.green : AppTheme.textLight,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Mobile Tab bar ---
  Widget _buildMobileTabsSelector() {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: Row(
        children: ['Feed', 'Analytics', 'Control'].map((tab) {
          final isActive = _activeMobileTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeMobileTab = tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textLight,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Column 1: Telemetry Feed ---
  Widget _buildFeedColumn(List<_MorphUpdatePost> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column Header with filters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.rss_feed, color: AppTheme.primaryLight, size: 18),
                SizedBox(width: 8),
                Text(
                  'Telemetry Feed',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
              ),
              child: Row(
                children: ['All', 'Media', 'Text'].map((filter) {
                  final active = _feedFilter == filter;
                  return InkWell(
                    onTap: () => setState(() => _feedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.bgTertiary.withOpacity(0.5) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: active ? Colors.white : AppTheme.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // Posts List
        Expanded(
          child: posts.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
                  ),
                  child: const Text('No telemetry feed items matched this filter.', style: TextStyle(color: AppTheme.textLight)),
                )
              : ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final liked = _likedPostIndices.contains(index);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF1E1E1E),
                                child: Text(
                                  post.avatarText,
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.breederName,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      post.timeAgo,
                                      style: const TextStyle(color: AppTheme.textLight, fontSize: 9, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.verified, color: AppTheme.primaryColor, size: 14),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (post.morphTitle != 'Broadcast Update')
                            Text(
                              post.morphTitle,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            post.morphContent,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          if (post.hasMedia)
                            Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildMediaPlaceholder(post.morphTitle),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: post.morphTags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: AppTheme.primaryColor),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFF222222)),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (liked) {
                                      _likedPostIndices.remove(index);
                                    } else {
                                      _likedPostIndices.add(index);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        liked ? Icons.favorite : Icons.favorite_border,
                                        color: liked ? AppTheme.primaryColor : AppTheme.textLight,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${post.likes + (liked ? 1 : 0)} Likes',
                                        style: TextStyle(
                                          color: liked ? AppTheme.primaryColor : AppTheme.textLight,
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Row(
                                children: [
                                  const Icon(Icons.mode_comment_outlined, color: AppTheme.textLight, size: 16),
                                  const SizedBox(width: 6),
                                  Text('${post.comments} Comments', style: const TextStyle(color: AppTheme.textLight, fontSize: 11, fontFamily: 'monospace')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMediaPlaceholder(String title) {
    // Elegant SVG-like design using Flutter layout widgets to look highly premium without broken URL images
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A1E), Color(0xFF0D1E0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.bubble_chart, size: 120, color: AppTheme.primaryColor.withOpacity(0.06)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: AppTheme.primaryColor.withOpacity(0.4), size: 32),
                const SizedBox(height: 8),
                Text(
                  'TELEMETRY DATA VERIFIED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: AppTheme.primaryColor.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Column 2: Analytics Terminal ---
  Widget _buildAnalyticsColumn(int postsCount) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.primaryLight, size: 18),
              SizedBox(width: 8),
              Text(
                'Analytics Terminal',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart custom painter
          const Text('Engagement Growth Curve', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
            ),
            child: CustomPaint(
              painter: _EngagementCurvePainter(),
            ),
          ),
          const SizedBox(height: 25),

          // Donut chart custom painter
          const Text('Content Distribution Ratio', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _DonutChartPainter(ratio: 0.4),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, color: AppTheme.primaryLight),
                        const SizedBox(width: 8),
                        const Text('Media Nodes (40%)', style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(width: 8, height: 8, color: AppTheme.borderColor),
                        const SizedBox(width: 8),
                        const Text('Text Nodes (60%)', style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Telemetry Node Status Detail lines
          _buildTerminalInfoLine('Telemetry System Status', 'ACTIVE // ONLINE', Colors.green),
          _buildTerminalInfoLine('Database Sync Nodes', 'REALTIME', Colors.white),
          _buildTerminalInfoLine('Active Node Feeds', '$postsCount Count', AppTheme.primaryLight),
        ],
      ),
    );
  }

  Widget _buildTerminalInfoLine(String label, String value, Color valColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: valColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // --- Column 3: Control Center ---
  Widget _buildControlColumn() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_customize, color: AppTheme.accentColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Control Deck',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Quick broadcast posting form
          const Text('Quick Broadcast Update', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: _broadcastController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Type message to broadcast live...',
              hintStyle: const TextStyle(color: AppTheme.textLight, fontSize: 12),
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.borderColor.withOpacity(0.4)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_broadcastController.text.trim().isEmpty) return;
              setState(() {
                _myPosts.insert(0, _broadcastController.text.trim());
                _broadcastController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 14),
                SizedBox(width: 8),
                Text('Broadcast Node', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Signal Log Streams
          Row(
            children: [
              _buildPulseIndicator(),
              const SizedBox(width: 8),
              const Text('Realtime Signals log', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),

          _buildSignalLogNode(Icons.favorite, 'GargoyleBreeder liked your photolink', '1m ago', Colors.red),
          _buildSignalLogNode(Icons.person_add, 'PythonKing followed your updates', '12m ago', AppTheme.primaryLight),
          _buildSignalLogNode(Icons.bolt, 'System: database node synchronized', '1h ago', AppTheme.accentColor),
          _buildSignalLogNode(Icons.campaign, 'Notice: Marketplace pricing report', '2h ago', AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.primaryLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: AppTheme.primaryLight, blurRadius: 4, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildSignalLogNode(IconData icon, String message, String timeAgo, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 9, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Custom Painters for Charts ---

class _EngagementCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Draw horizontal grids
    for (int i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw curve path
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.7,
      size.width * 0.4,
      size.height * 0.8,
    );
    path.cubicTo(
      size.width * 0.6,
      size.height * 0.9,
      size.width * 0.75,
      size.height * 0.4,
      size.width,
      size.height * 0.2,
    );

    // Gradient fill paint
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      colors: [AppTheme.primaryLight.withOpacity(0.35), Colors.transparent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Line stroke paint
    final strokePaint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, strokePaint);

    // Data circles
    final pointPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    final cyanPointPaint = Paint()
      ..color = AppTheme.primaryLight
      ..style = PaintingStyle.fill;

    // Draw circles at specific positions
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 4.5, pointPaint);
    canvas.drawCircle(Offset(size.width * 0.73, size.height * 0.46), 4.5, cyanPointPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.2), 4.5, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DonutChartPainter extends CustomPainter {
  final double ratio;
  _DonutChartPainter({required this.ratio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.15;

    // Draw full track circle (Text Nodes)
    final trackPaint = Paint()
      ..color = AppTheme.borderColor.withOpacity(0.3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    // Draw value arc (Media Nodes)
    final arcPaint = Paint()
      ..color = AppTheme.primaryLight
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * ratio;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Model post class
class _MorphUpdatePost {
  final String breederName;
  final String avatarText;
  final String timeAgo;
  final String morphTitle;
  final String morphContent;
  final List<String> morphTags;
  final int likes;
  final int comments;
  final int shares;
  final bool hasMedia;

  _MorphUpdatePost({
    required this.breederName,
    required this.avatarText,
    required this.timeAgo,
    required this.morphTitle,
    required this.morphContent,
    required this.morphTags,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.hasMedia,
  });
}

class _SocialUserMenuButton extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final ThemeService themeService;
  final AuthService authService;

  const _SocialUserMenuButton({
    required this.userData,
    required this.themeService,
    required this.authService,
  });

  @override
  State<_SocialUserMenuButton> createState() => _SocialUserMenuButtonState();
}

class _SocialUserMenuButtonState extends State<_SocialUserMenuButton> {
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
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity() ..scale(showHovered ? 1.15 : 1.0),
          child: const Icon(
            Icons.account_circle,
            size: 24,
            color: AppTheme.primaryColor,
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userData?['name'] ?? widget.authService.currentUser?.displayName ?? widget.authService.currentUser?.email?.split('@')[0] ?? 'Gecko1',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  widget.userData?['email'] ?? widget.authService.currentUser?.email ?? 'gecko1@scalesync.pro',
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
                  MaterialPageRoute(builder: (_) => const SocialLoginView()),
                  (route) => false,
                );
              }
              break;
            case 'profile':
            case 'settings':
            case 'help':
              break;
          }
        },
      ),
    );
  }
}
