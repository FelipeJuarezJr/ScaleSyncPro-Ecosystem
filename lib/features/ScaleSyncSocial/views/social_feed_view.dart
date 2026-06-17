import 'package:flutter/material.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';

class SocialFeedView extends StatelessWidget {
  const SocialFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgSecondary : AppTheme.lightBgSecondary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View Title Header
              Text(
                'ScaleSync Social',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect, share genetics, and explore breeder networks worldwide.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Premium "Coming Soon" Hero Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
                  border: Border.all(
                    color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                  ),
                  boxShadow: isDark ? AppTheme.shadowMd : AppTheme.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Vibrant status circle
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightSecondaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? AppTheme.primaryColor : AppTheme.lightSecondaryColor).withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'FEATURE STATUS: UNDER DEVELOPMENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ScaleSync Social: Coming Soon',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We are currently designing a dedicated social feed for reptile breeders. Soon, you will be able to follow top hubs, post breeding success updates, track pedigree lineages publicly, and chat with buyers directly from the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Thank you for your interest! Notification preference saved.'),
                            backgroundColor: isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary,
                            behavior: SnackBarBehavior.floating,
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                              onPressed: () {},
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text('Notify Me on Launch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.primaryColor : AppTheme.lightPrimaryColor,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Blur/Skeleton list preview for social feed post cards
              Text(
                'Social Feed Preview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              
              // Skeleton 1
              _buildPostSkeleton(context, isDark),
              const SizedBox(height: 16),
              // Skeleton 2
              _buildPostSkeleton(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostSkeleton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: (isDark ? AppTheme.bgPrimary : AppTheme.lightBgPrimary).withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: (isDark ? AppTheme.borderColor : AppTheme.lightBorderColor).withOpacity(0.5),
        ),
      ),
      child: Opacity(
        opacity: 0.3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isDark ? AppTheme.bgTertiary : AppTheme.lightBgTertiary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 60,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 180,
              height: 12,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
