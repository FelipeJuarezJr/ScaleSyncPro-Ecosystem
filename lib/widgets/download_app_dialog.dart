import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';
import 'package:scalesync_pro_ecosystem/core/network/domain_guard.dart';
import 'package:scalesync_pro_ecosystem/utils/pwa_helper.dart' as pwa;

class DownloadAppDialog extends StatefulWidget {
  const DownloadAppDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const DownloadAppDialog(),
    );
  }

  @override
  State<DownloadAppDialog> createState() => _DownloadAppDialogState();
}

class _DownloadAppDialogState extends State<DownloadAppDialog> {
  bool _canInstallDirectly = false;
  bool _isAlreadyInstalled = false;

  @override
  void initState() {
    super.initState();
    _checkPwaState();
    // Register callback for when install prompt is received asynchronously
    pwa.registerInstallableCallback(() {
      if (mounted) {
        setState(() {
          _canInstallDirectly = true;
        });
      }
    });
  }

  void _checkPwaState() {
    setState(() {
      _isAlreadyInstalled = pwa.isPwaInstalled();
      // On web we check if the browser installer is deferred.
      // If we don't have direct trigger yet, we still show instructions.
      _canInstallDirectly = kIsWeb && !_isAlreadyInstalled; 
    });
  }

  @override
  Widget build(BuildContext context) {
    final target = DomainGuard.currentTarget;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Harmonized palette based on current active ecosystem portal
    Color themeColor;
    String portalName;
    String portalDesc;
    IconData portalIcon;

    switch (target) {
      case AppViewTarget.market:
        themeColor = const Color(0xFF00D4FF); // Market Cyan
        portalName = 'ScaleSync Marketplace';
        portalDesc = 'Buy, sell, and track premium genetics on the go.';
        portalIcon = Icons.storefront;
        break;
      case AppViewTarget.social:
        themeColor = const Color(0xFFAF40FF); // Social Purple
        portalName = 'ScaleSync Social';
        portalDesc = 'Connect with breeders, share broadcasts, and chat in real-time.';
        portalIcon = Icons.forum;
        break;
      case AppViewTarget.pro:
      default:
        themeColor = const Color(0xFF00FF00); // Pro Green
        portalName = 'ScaleSync Pro';
        portalDesc = 'Manage collection analytics, tasks, breeding charts, and reports.';
        portalIcon = Icons.analytics;
        break;
    }

    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isMobile = isIOS || isAndroid;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E201A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with matching background gradient
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // App Icon Emblem
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161713) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      portalIcon,
                      color: themeColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Get the App',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    portalName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: themeColor,
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  Text(
                    portalDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textSecondary : Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isAlreadyInstalled) ...[
                    // Case 1: Already Installed
                    _buildStatusAlert(
                      icon: Icons.check_circle,
                      title: 'App is Installed',
                      desc: 'You are currently running the standalone app wrapper for $portalName.',
                      color: AppTheme.successColor,
                    ),
                  ] else if (isIOS) ...[
                    // Case 2: iOS-specific PWA installation guide
                    _buildIOSGuide(isDark, themeColor),
                  ] else ...[
                    // Case 3: Android/Desktop guide
                    _buildGenericGuide(isDark, themeColor, isMobile),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Footer actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondary : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!_isAlreadyInstalled && _canInstallDirectly) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final success = pwa.triggerPwaInstall();
                        if (success) {
                          Navigator.of(context).pop();
                        } else {
                          // Fallback explanation
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Installation prompted! Please confirm in your browser window.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.download, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Install Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAlert({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSGuide(bool isDark, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Install on iPhone / iPad:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildStepRow('1', 'Open Safari and navigate to this website.'),
        _buildStepRow('2', 'Tap the Share button at the bottom of Safari (represented by a square with an upward arrow).'),
        _buildStepRow('3', 'Scroll down the share list and select "Add to Home Screen".'),
        _buildStepRow('4', 'Tap "Add" in the top-right corner to complete installation.'),
      ],
    );
  }

  Widget _buildGenericGuide(bool isDark, Color themeColor, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isMobile ? 'How to Install on Android:' : 'How to Install on Desktop:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile) ...[
          _buildStepRow('1', 'Tap the "Install Now" button below (or tap the three dots in Chrome\'s top-right menu).'),
          _buildStepRow('2', 'Select "Add to Home Screen" or "Install App".'),
          _buildStepRow('3', 'Confirm the prompt, and the app icon will appear on your device screen.'),
        ] else ...[
          _buildStepRow('1', 'Click the "Install" icon (represented by a screen with a downward arrow) in the browser\'s URL address bar.'),
          _buildStepRow('2', 'Or, click the three-dot browser menu and choose "Save and share" > "Install ScaleSync".'),
          _buildStepRow('3', 'Confirm installation to launch the portal in its own dedicated, clean app window.'),
        ],
      ],
    );
  }

  Widget _buildStepRow(String stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF1B1D17),
              shape: BoxShape.circle,
            ),
            child: Text(
              stepNumber,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
