import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:scalesync_pro_ecosystem/services/auth_service.dart';
import 'social_login_view.dart';

class SocialFeedView extends StatelessWidget {
  const SocialFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = legacy_provider.Provider.of<AuthService>(context);
    final isLoggedIn = authService.isAuthenticated;

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
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black, // Sleek black aesthetic for the social platform
      body: SafeArea(
        child: Column(
          children: [
            // Top Header Bar
            Container(
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SCALESYNC SOCIAL',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00FF00),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (isLoggedIn) {
                        await authService.signOut();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SocialLoginView()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF00FF00),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFF00FF00), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: Text(
                      isLoggedIn ? '[ SIGN_OUT ]' : '[ JOIN_COMMUNITY ]',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Timeline Stream
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: mockUpdates.length,
                itemBuilder: (context, index) {
                  final post = mockUpdates[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF222222)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Breeder Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF1A1A1A),
                              child: Text(
                                post.avatarText,
                                style: const TextStyle(
                                  color: Color(0xFF00FF00),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.breederName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    post.timeAgo,
                                    style: const TextStyle(
                                      color: Color(0xFF555555),
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF00FF00),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          post.morphTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Content
                        Text(
                          post.morphContent,
                          style: const TextStyle(
                            color: Color(0xFFBBBBBB),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: post.morphTags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF003300).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF005500)),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: Color(0xFF00FF00),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF222222)),
                        const SizedBox(height: 8),

                        // Actions Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionButton(Icons.favorite_border, '${post.likes} Likes'),
                            _buildActionButton(Icons.mode_comment_outlined, '${post.comments} Comments'),
                            _buildActionButton(Icons.repeat, '${post.shares} Reposts'),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF666666), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

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
  });
}
