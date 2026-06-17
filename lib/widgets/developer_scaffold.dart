import 'package:flutter/material.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncPro/views/dashboard_view.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncMarketplace/views/marketplace_grid_view.dart';
import 'package:scalesync_pro_ecosystem/features/ScaleSyncSocial/views/social_feed_view.dart';
import 'package:scalesync_pro_ecosystem/screens/main_app_screen.dart';

class DeveloperScaffold extends StatefulWidget {
  const DeveloperScaffold({super.key});

  @override
  State<DeveloperScaffold> createState() => _DeveloperScaffoldState();
}

class _DeveloperScaffoldState extends State<DeveloperScaffold> {
  String _activeMode = 'ScaleSyncPro-Firestore';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Premium dark-mode environment switcher bar at the very top
          Container(
            width: double.infinity,
            color: const Color(0xFF0F0F0F), // Fixed dark background for the switcher
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF00),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00FF00).withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DEVELOPER PORTAL SWITCHER',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.8,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF2E2E2E)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Dynamically calculate width for each option
                        final double totalWidth = constraints.maxWidth;
                        final double buttonWidth = (totalWidth - 6) / 3;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSegmentButton('ScaleSyncPro-Firestore', buttonWidth),
                            _buildSegmentButton('ScaleSyncMarketplace-Firestore', buttonWidth),
                            _buildSegmentButton('ScaleSyncSocial-Firestore', buttonWidth),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Active view viewport container
          Expanded(
            child: _buildActiveViewport(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String mode, double width) {
    final isActive = _activeMode == mode;
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeMode = mode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF00FF00) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF00FF00).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              mode,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.black : const Color(0xFFBBBBBB),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveViewport() {
    switch (_activeMode) {
      case 'ScaleSyncPro-Firestore':
        return const MainAppScreen();
      case 'ScaleSyncMarketplace-Firestore':
        return const MarketplaceGridView();
      case 'ScaleSyncSocial-Firestore':
        return const SocialFeedView();
      default:
        return const MainAppScreen();
    }
  }
}
