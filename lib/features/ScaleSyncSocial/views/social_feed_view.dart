import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'package:scalesync_pro_ecosystem/services/theme_service.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncSocial/views/social_login_view.dart';

class SocialFeedView extends StatefulWidget {
  const SocialFeedView({super.key});

  @override
  State<SocialFeedView> createState() => _SocialFeedViewState();
}

class _SocialFeedViewState extends State<SocialFeedView> {
  String _feedFilter = 'All'; // 'All' | 'Media' | 'Text'
  final TextEditingController _broadcastController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final List<String> _myPosts = [];

  // Likes state tracking
  final Set<int> _likedPostIndices = {};

  @override
  void dispose() {
    _broadcastController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void _focusPostComposer() {
    _composerFocusNode.requestFocus();
  }

  void _showMobilePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Broadcast',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _broadcastController,
                maxLines: 4,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: "What's happening in your terrarium?",
                  hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14),
                  fillColor: Colors.transparent,
                  filled: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_broadcastController.text.trim().isEmpty) return;
                      setState(() {
                        _myPosts.insert(0, _broadcastController.text.trim());
                        _broadcastController.clear();
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Publish'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
        breederName: 'ArborealMaster',
        avatarText: 'AM',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAH2HlNAj5IGHCTDASrsdxHflXVOQn36zgtJXeig9PJ7hFs0jsBuoSA0Gan2kpxC5_xkDRVzI1zRrbUhMpFniUudiFgRHBLlymJ-SJ-MDW5Ip7Y5SPWbGL6BBsaydw2BUMerLD7J7pjXULIwWAm6VvSk6dl7N83aQbMZ-F0Ui_D0CZt8i7MqFSD5aqRLpQ16WejYNagGPlDJ-s-oDLa5TnzUgk7ZrI2E7qivZ_gLDl1xni4zA-VPjqQrkPNYiRpAQ7Rb2nhkJ9wXMM',
        timeAgo: '2h ago',
        subtitle: 'Morelia viridis',
        morphTitle: 'Morning glow on the Biak.',
        morphContent: 'Just look at that contrast! This Biak locality is finally starting to show those deep yellows and high-contrast greens after its last shed. Maintaining 82% humidity and a steady 84°F hotspot.',
        morphTags: ['GreenTreePython', 'BiakLocality'],
        likes: 1200,
        comments: 84,
        shares: 5,
        hasMedia: true,
        mediaUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC8A00HI6-gr9_6JK-4AXyAgsjZLGk6BgG2WZm-UFT4R4LsDMFaMTfFpBxaVPLHuIauRfPI4Wizx6QzPTg7KfpopNS_bR9JdoVHCIAchR2Ra5mX5ESL7FLTFTZ3-MWW90vr8T9dgNQVyI_0rXkXIWttjhVu1o_KfrQ8V7gfsc2wmjnJBL-4YHiXkuIEWOPdUglpaQf22uAtB0y29wZmlESMND9SffvtUmNpGDRez0SA0UsVTqCeW72YPtFl43zYxEi9nFSITM-ZsRk',
      ),
      _MorphUpdatePost(
        breederName: 'DesertDragon92',
        avatarText: 'DD',
        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHXU_6BWFTCLD97Cl1Gf2cp9lSUcuTHwz5KwH6wkunSPpHQ712LU6UPFZQHlXJ8HhSadCsIxLCBXtMFss6__YFtcPVH6eFAs7DedjretZe_zibjEHpIGh4MQHL57VelVYxCowhR4yRksRxzKyoeoMnoeL_neeoxHk7wp1FwWe4AYV7F0_jrkDWaZt2oBPE6IjY1IlYfjwFAVMXsUoKBlOs2lZjNdGEVCMwKzRfz34btJtxgqU2t0UQoseCtX7XXcYaz3ZZNUSftOk',
        timeAgo: '5h ago',
        subtitle: 'Feeding Time',
        morphTitle: 'Lunch time for Spike!',
        morphContent: "Lunch time for Spike! Watching the hunt drive in these animals never gets old. He's up to 450g now and looking healthy.",
        morphTags: ['BeardedDragon', 'Feeding'],
        likes: 345,
        comments: 28,
        shares: 2,
        hasMedia: true,
        mediaUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAs3nf7fxWMGVUs0HwBaCyRiyQzgQcQ8CUXfl0m4_rSJH4fjPpX0wMf-8C04Tf4ouMa8unIcCYSb5FK6MOtXL9ZP1O0Rp903RKoUHUeeQ0aDTMoEp_0pHE204uJ9poibAJVcNqbhqfIHeDv-C9vG5-ACRRhnMRFursKDc30yXDI9MR4F-h4JuaAQwoj4Xe80niwm8vbjWxr5YtawpqsErSmfF59m6O2IQ7xs0KHsNMXOJk22TNEbbHZUCOelqJdO-9N_uB3x60cXyg',
        isVideo: true,
        stats: {
          'Temperature': '105°F',
          'Humidity': '15%',
          'Supplement': 'Ca + D3',
        },
      ),
      _MorphUpdatePost(
        breederName: 'NewKeeper_Leo',
        avatarText: 'NL',
        avatarIcon: Icons.help_outline,
        timeAgo: '8h ago',
        subtitle: 'Husbandry Question',
        morphTitle: 'Struggling with night-time temp drops for my Ball Python...',
        morphContent: "I'm using a 100W CHE on a thermostat, but the ambient temps in the cool side are dropping to 72°F at night. My house is drafty. Is a secondary under-tank heater necessary, or should I insulate the enclosure better?",
        morphTags: ['BallPython', 'EnclosureDesign', 'HusbandryHelp'],
        likes: 18,
        comments: 12,
        shares: 1,
        hasMedia: false,
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
          subtitle: 'Broadcast Node',
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
      backgroundColor: AppTheme.bgPrimary,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showMobilePostSheet(context),
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.edit_square, color: Colors.white),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation & Brand Header
            _buildHeader(context, authService, isLoggedIn, isMobile),

            // Main Columns Section
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SidebarNavigation(
                          isTablet: false,
                          onPostPressed: _focusPostComposer,
                        ),
                        Expanded(
                          child: _buildFeedColumn(filteredPosts, false),
                        ),
                        const _RightSidebar(),
                      ],
                    );
                  } else if (isTablet) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SidebarNavigation(
                          isTablet: true,
                          onPostPressed: _focusPostComposer,
                        ),
                        Expanded(
                          child: _buildFeedColumn(filteredPosts, false),
                        ),
                      ],
                    );
                  } else {
                    return _buildFeedColumn(filteredPosts, true);
                  }
                },
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

  // --- Column 2: Feed Column ---
  Widget _buildFeedColumn(List<_MorphUpdatePost> posts, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Title & Filter Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Terrarium Feed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Segmented Filter Control
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: ['All', 'Media', 'Text'].map((filter) {
                    final isSelected = _feedFilter == filter;
                    return InkWell(
                      onTap: () => setState(() => _feedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.bgTertiary : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textLight,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Scrollable List
          Expanded(
            child: ListView.builder(
              itemCount: posts.length + (isMobile ? 0 : 1),
              itemBuilder: (context, index) {
                if (!isMobile) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _PostComposerCard(
                        controller: _broadcastController,
                        focusNode: _composerFocusNode,
                        onPublish: () {
                          if (_broadcastController.text.trim().isEmpty) return;
                          setState(() {
                            _myPosts.insert(0, _broadcastController.text.trim());
                            _broadcastController.clear();
                          });
                        },
                        avatarUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDvfta9v30KVAVz2SlBVXmJPSQ_8oU-K-vzRn58YYbuuLeywC-MDkfuoh4M23GoYae2UukM2_M3ht8-lSHWBf4CwCEIyIRS2Nns8-LuqClcmmzU8FZ_x0LJxzvK_jv3Hzoq5wT73s2Eed8KWeZ-wpTXyTnpQd2anMmRS71HAyXAQy7Ezk8ph4QkYog5xlWJSaAyG8GCXpvWSv-FWarDXpUNVg0iMMwDTWYNaHLVCNfHcYOJ_-mtUl9bUb80xxSVQixen1dKjUCmYBQ',
                      ),
                    );
                  }
                  final post = posts[index - 1];
                  final liked = _likedPostIndices.contains(index - 1);
                  return _SocialPostCard(
                    post: post,
                    isLiked: liked,
                    onLikeToggle: () {
                      setState(() {
                        if (liked) {
                          _likedPostIndices.remove(index - 1);
                        } else {
                          _likedPostIndices.add(index - 1);
                        }
                      });
                    },
                  );
                } else {
                  final post = posts[index];
                  final liked = _likedPostIndices.contains(index);
                  return _SocialPostCard(
                    post: post,
                    isLiked: liked,
                    onLikeToggle: () {
                      setState(() {
                        if (liked) {
                          _likedPostIndices.remove(index);
                        } else {
                          _likedPostIndices.add(index);
                        }
                      });
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Left Navigation Sidebar ---
class _SidebarNavigation extends StatelessWidget {
  final bool isTablet;
  final VoidCallback onPostPressed;

  const _SidebarNavigation({
    required this.isTablet,
    required this.onPostPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isTablet ? 200 : 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(
          right: BorderSide(color: Color(0xFF222222), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildNavItem('Home', Icons.home, true),
          _buildNavItem('Discover', Icons.explore, false),
          _buildNavItem('Notifications', Icons.notifications_none, false, badgeCount: 2),
          _buildNavItem('Messages', Icons.chat_bubble_outline, false),
          _buildNavItem('Profile', Icons.person_outline, false),
          _buildNavItem('Settings', Icons.settings_outlined, false),
          const Spacer(),
          ElevatedButton(
            onPressed: onPostPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_outline, size: 18),
                if (!isTablet) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Post Specimen',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, bool isActive, {int badgeCount = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              if (!isTablet)
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (badgeCount > 0 && !isTablet)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Right Sidebar ---
class _RightSidebar extends StatefulWidget {
  const _RightSidebar();

  @override
  State<_RightSidebar> createState() => _RightSidebarState();
}

class _RightSidebarState extends State<_RightSidebar> {
  final Set<String> _followedBreeders = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trending Section
            _buildTrendingSection(),
            const SizedBox(height: 20),
            // Top Tier Breeders
            _buildBreedersSection(),
            const SizedBox(height: 20),
            // Activity Heatmap
            _buildActivitySection(),
            const SizedBox(height: 20),
            // Footer
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Trending Herps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTrendingItem('Species Spotlight', '#LeopardGeckoCare', '2.4k posts this week'),
          _buildTrendingItem('Genetics', '#BallPythonMorphs', '1.8k posts this week'),
          _buildTrendingItem('Bioactive', '#TerrariumDesign', '940 posts this week'),
          _buildTrendingItem('Conservation', '#AustralianAgamids', '520 posts this week'),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Show more',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingItem(String category, String hashtag, String stats) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              hashtag,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stats,
              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreedersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Tier Breeders',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _buildBreederRow(
            'Apex Herpetics',
            'Specializing in Boas',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAaK-o3mJDY-DkX-foC9845d-SnkR4GwfEA5ode1xOA-dDnFURa5UM1gHzk5JVh-1S80WiJf4R3yu1qKtBZL-U_dbe-i8CgSRpyVtWY2rY6Aazq25i4372bcMzJfZsRj8SmgdKr69A2GuIUNpKkdfQe-KGiEv-UVCwIMMJ-znr5L3iSpguskbXW-eyzpKmm1jZrr2E2lJ66OxNqLhCRwwrphrzVZh0kU4hFJnpMCBcUncXM_OA3aL30UYB2mdZrM_nbc2IBqUinH2U',
          ),
          const SizedBox(height: 12),
          _buildBreederRow(
            'Jewel Geckos',
            'Rare Phelsuma lines',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDMnO5al9AKLtljtP7de1KIzJvmDyGPcbOJqy8sQjVHcYNnhs2mg_rJvfuOGP-VYQPe0E6OWh2M8hWp1YBhpLuLZsdkseGpxqXZnCGIfuTE6SE-Hz5PmsTQM9F8aTvAmsNPNvyB6CTHk-LcuaqJ9nDiga4Q5ZRhf1W0Mh165akm2k4zUDIW9kiCQSae2GEYU6lzv5A2l2tx_UAXuiszkeZoYNMVe0ljn6EBpT0Vlhucbagot33Cv9kJLt0fdIK3MkJT8pwnHAIdYJM',
          ),
        ],
      ),
    );
  }

  Widget _buildBreederRow(String name, String specialty, String imageUrl) {
    final isFollowing = _followedBreeders.contains(name);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppTheme.bgTertiary,
              child: const Icon(Icons.business, color: Colors.white, size: 16),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                specialty,
                style: const TextStyle(color: AppTheme.textLight, fontSize: 10),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (isFollowing) {
                _followedBreeders.remove(name);
              } else {
                _followedBreeders.add(name);
              }
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? AppTheme.bgTertiary : Colors.white,
            foregroundColor: isFollowing ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Community Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Bar Chart simulated
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActivityBar(0.3),
                _buildActivityBar(0.6),
                _buildActivityBar(0.45),
                _buildActivityBar(0.9),
                _buildActivityBar(1.0),
                _buildActivityBar(0.7),
                _buildActivityBar(0.55),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Community growth is up 12% this week. Keep sharing your setups!',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(double fraction) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: FractionallySizedBox(
          heightFactor: fraction,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(fraction == 1.0 ? 1.0 : (fraction * 0.8)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildFooterLink('Terms'),
              _buildFooterLink('Privacy'),
              _buildFooterLink('Ethics Guide'),
              _buildFooterLink('Breeder Standards'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2026 ScaleSync Social',
            style: TextStyle(color: AppTheme.textLight, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label) {
    return InkWell(
      onTap: () {},
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 10,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

// --- Post Composer Card ---
class _PostComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPublish;
  final String? avatarUrl;

  const _PostComposerCard({
    required this.controller,
    required this.focusNode,
    required this.onPublish,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_circle,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  )
                : const Icon(
                    Icons.account_circle,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: null,
                  minLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: "What's happening in your terrarium?",
                    hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 13),
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF333333), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildComposerAction(Icons.image_outlined, 'Photo'),
                    const SizedBox(width: 12),
                    _buildComposerAction(Icons.videocam_outlined, 'Video'),
                    const SizedBox(width: 12),
                    _buildComposerAction(Icons.thermostat_outlined, 'Stats'),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: onPublish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Publish',
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

  Widget _buildComposerAction(IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textLight, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Social Post Card ---
class _SocialPostCard extends StatefulWidget {
  final _MorphUpdatePost post;
  final bool isLiked;
  final VoidCallback onLikeToggle;

  const _SocialPostCard({
    required this.post,
    required this.isLiked,
    required this.onLikeToggle,
  });

  @override
  State<_SocialPostCard> createState() => _SocialPostCardState();
}

class _SocialPostCardState extends State<_SocialPostCard> {
  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            post.breederName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (post.avatarIcon == null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: AppTheme.primaryColor,
                              size: 13,
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${post.timeAgo} • ${post.subtitle}',
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: AppTheme.textLight),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Media Section
          if (post.hasMedia && post.mediaUrl != null) _buildMediaSection(),

          // Post Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.morphTitle.isNotEmpty && post.morphTitle != 'Broadcast Update') ...[
                  Text(
                    post.morphTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontStyle: post.avatarIcon != null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  post.morphContent,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                // Stats Section
                if (post.stats != null && post.stats!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildStatsRow(),
                ],

                // Tags Section
                if (post.morphTags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: post.morphTags.map((tag) => _buildTag(tag)).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(color: Color(0xFF333333), height: 1),
                const SizedBox(height: 10),

                // Actions Footer
                _buildActionsFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final post = widget.post;
    if (post.avatarIcon != null) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(post.avatarIcon, color: AppTheme.accentColor, size: 18),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: post.isVideo ? AppTheme.accentColor : AppTheme.primaryColor,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: post.avatarUrl != null
          ? Image.network(
              post.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackAvatarText(),
            )
          : _buildFallbackAvatarText(),
    );
  }

  Widget _buildFallbackAvatarText() {
    return Container(
      color: AppTheme.bgTertiary,
      alignment: Alignment.center,
      child: Text(
        widget.post.avatarText,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    final post = widget.post;
    return AspectRatio(
      aspectRatio: post.isVideo ? 16 / 9 : 1.0,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            post.mediaUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, color: AppTheme.textLight, size: 32),
            ),
          ),
          if (post.isVideo) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Simulating video playback...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '4K VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
          if (!post.isVideo && post.morphTags.isNotEmpty) ...[
            Positioned(
              bottom: 12,
              left: 12,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      post.morphTags.first,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (post.morphTags.length > 1) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        post.morphTags[1],
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = widget.post.stats!;
    return Row(
      children: stats.entries.map((entry) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 9),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.value,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionsFooter() {
    final post = widget.post;
    final isLiked = widget.isLiked;
    
    if (post.avatarIcon != null) {
      return Row(
        children: [
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening replies stream...'),
                  duration: Duration(milliseconds: 1500),
                ),
              );
            },
            child: const Row(
              children: [
                Icon(Icons.forum_outlined, color: AppTheme.primaryColor, size: 18),
                SizedBox(width: 6),
                Text(
                  '12 Expert Replies',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Like Button
        InkWell(
          onTap: widget.onLikeToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? AppTheme.primaryColor : AppTheme.textLight,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likes + (isLiked ? 1 : 0)}',
                  style: TextStyle(
                    color: isLiked ? AppTheme.primaryColor : AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        
        // Comment Button
        InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppTheme.textLight,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.comments}',
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        
        // Share Button
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppTheme.textLight, size: 18),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link copied to clipboard!'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

// --- Post Model Class ---
class _MorphUpdatePost {
  final String breederName;
  final String avatarText;
  final String? avatarUrl;
  final IconData? avatarIcon;
  final String timeAgo;
  final String subtitle;
  final String morphTitle;
  final String morphContent;
  final List<String> morphTags;
  final int likes;
  final int comments;
  final int shares;
  final bool hasMedia;
  final String? mediaUrl;
  final bool isVideo;
  final Map<String, String>? stats;

  _MorphUpdatePost({
    required this.breederName,
    required this.avatarText,
    this.avatarUrl,
    this.avatarIcon,
    required this.timeAgo,
    required this.subtitle,
    required this.morphTitle,
    required this.morphContent,
    required this.morphTags,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.hasMedia,
    this.mediaUrl,
    this.isVideo = false,
    this.stats,
  });
}

// --- User Menu Button ---
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
          transform: Matrix4.identity()..scale(showHovered ? 1.15 : 1.0),
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
