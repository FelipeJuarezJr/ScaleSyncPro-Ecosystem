import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/activity_item.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/add_reptile_modal.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    final isWeb = kIsWeb;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      body: isWeb 
        ? _buildWebLayout(context)
        : _buildMobileLayout(screenHeight, screenWidth, isMobile, bottomPadding),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileBrowser = screenWidth <= 768;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Text(
            'Welcome back!',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s an overview of your reptile collection.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Stats Grid - Responsive web layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobileBrowser ? 1 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobileBrowser
                ? 4.0
                : (screenWidth <= 1050
                    ? 2.0   // narrow desktop: cells ~85px, content needs ~76px
                    : (screenWidth <= 1800
                        ? 2.2 // medium: cells ~110px at 1050px, content needs ~100px
                        : 3.04)),
            children: const [
              StatCard(
                icon: Icons.drag_indicator,
                title: 'Total Reptiles',
                value: '47',
                change: '+3 this month',
                isPositive: true,
              ),
              StatCard(
                icon: Icons.science,
                title: 'Active Breeding',
                value: '8',
                change: '2 clutches expected',
                isPositive: null,
              ),
              StatCard(
                icon: Icons.check_circle,
                title: 'Today\'s Tasks',
                value: '12',
                change: '3 overdue',
                isPositive: null,
              ),
              StatCard(
                icon: Icons.attach_money,
                title: 'Monthly Costs',
                value: '284',
                change: '+\$45 vs last month',
                isPositive: false,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Activity - Responsive web layout
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobileBrowser ? 16 : 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: isMobileBrowser ? 18 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: const [
                      ActivityItem(
                        icon: Icons.restaurant,
                        iconColor: AppTheme.successColor,
                        title: 'Feeding - Ball Python #BP001',
                        description: 'Fed 1 medium rat (150g)',
                        time: '2 hours ago',
                      ),
                      SizedBox(height: 15),
                      ActivityItem(
                        icon: Icons.science,
                        iconColor: AppTheme.infoColor,
                        title: 'Breeding - Leopard Gecko Pair',
                        description: 'Successful pairing recorded',
                        time: '1 day ago',
                      ),
                      SizedBox(height: 15),
                      ActivityItem(
                        icon: Icons.favorite,
                        iconColor: AppTheme.warningColor,
                        title: 'Health Check - Bearded Dragon',
                        description: 'Weight: 450g, Length: 18"',
                        time: '3 days ago',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Growth Chart - Responsive web layout
          Text(
            'Growth Tracking',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weight Progress (Last 6 Months)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: isMobileBrowser ? 150 : 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}g',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
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
                                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                if (value.toInt() >= 0 && value.toInt() < months.length) {
                                  return Text(
                                    months[value.toInt()],
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
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
                            spots: const [
                              FlSpot(0, 120),
                              FlSpot(1, 135),
                              FlSpot(2, 142),
                              FlSpot(3, 158),
                              FlSpot(4, 165),
                              FlSpot(5, 180),
                            ],
                            isCurved: true,
                            color: AppTheme.primaryColor,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: AppTheme.primaryColor,
                                  strokeWidth: 2,
                                  strokeColor: AppTheme.bgPrimary,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Quick Actions - Responsive web layout
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: isMobileBrowser ? 2 : 4,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: isMobileBrowser ? 2.0 : (screenWidth <= 1050 ? 2.0 : 2.33),
                    children: [
                      _buildActionButton(
                        icon: Icons.add,
                        label: 'Add Reptile',
                        onTap: () {
                          _showModal('addReptileModal');
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.restaurant,
                        label: 'Log Feeding',
                        onTap: () {
                          _showModal('addFeedingModal');
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.science,
                        label: 'New Breeding',
                        onTap: () {
                          _showModal('addBreedingModal');
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.add_alarm,
                        label: 'Schedule Task',
                        onTap: () {
                          _showModal('addTaskModal');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(double screenHeight, double screenWidth, bool isMobile, double bottomPadding) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20, 
          20, 
          20, 
          20 + bottomPadding, // Add bottom padding for safe area
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Here\'s an overview of your reptile collection.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Stats Grid - Mobile optimized (1x4 layout)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 4.0,
              children: const [
                StatCard(
                  icon: Icons.drag_indicator,
                  title: 'Total Reptiles',
                  value: '47',
                  change: '+3 this month',
                  isPositive: true,
                ),
                StatCard(
                  icon: Icons.science,
                  title: 'Active Breeding',
                  value: '8',
                  change: '2 clutches expected',
                  isPositive: null,
                ),
                StatCard(
                  icon: Icons.check_circle,
                  title: 'Today\'s Tasks',
                  value: '12',
                  change: '3 overdue',
                  isPositive: null,
                ),
                StatCard(
                  icon: Icons.attach_money,
                  title: 'Monthly Costs',
                  value: '284',
                  change: '+\$45 vs last month',
                  isPositive: false,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Activity - Mobile optimized
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: const [
                        ActivityItem(
                          icon: Icons.restaurant,
                          iconColor: AppTheme.successColor,
                          title: 'Feeding - Ball Python #BP001',
                          description: 'Fed 1 medium rat (150g)',
                          time: '2 hours ago',
                        ),
                        SizedBox(height: 15),
                        ActivityItem(
                          icon: Icons.science,
                          iconColor: AppTheme.infoColor,
                          title: 'Breeding - Leopard Gecko Pair',
                          description: 'Successful pairing recorded',
                          time: '1 day ago',
                        ),
                        SizedBox(height: 15),
                        ActivityItem(
                          icon: Icons.favorite,
                          iconColor: AppTheme.warningColor,
                          title: 'Health Check - Bearded Dragon',
                          description: 'Weight: 450g, Length: 18"',
                          time: '3 days ago',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Growth Chart - Mobile optimized
            Text(
              'Growth Tracking',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weight Progress (Last 6 Months)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: screenHeight * 0.25, // Responsive height for mobile
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}g',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
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
                                  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                                  if (value.toInt() >= 0 && value.toInt() < months.length) {
                                    return Text(
                                      months[value.toInt()],
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
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
                              spots: const [
                                FlSpot(0, 120),
                                FlSpot(1, 135),
                                FlSpot(2, 142),
                                FlSpot(3, 158),
                                FlSpot(4, 165),
                                FlSpot(5, 180),
                              ],
                              isCurved: true,
                              color: AppTheme.primaryColor,
                              barWidth: 3,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 2,
                                    strokeColor: AppTheme.bgPrimary,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Quick Actions - Mobile optimized
            Container(
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.8, // More compact for mobile
                      children: [
                        _buildActionButton(
                          icon: Icons.add,
                          label: 'Add Reptile',
                          onTap: () {
                            _showModal('addReptileModal');
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.restaurant,
                          label: 'Log Feeding',
                          onTap: () {
                            _showModal('addFeedingModal');
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.science,
                          label: 'New Breeding',
                          onTap: () {
                            _showModal('addBreedingModal');
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.add_alarm,
                          label: 'Schedule Task',
                          onTap: () {
                            _showModal('addTaskModal');
                          },
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return QuickActionButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }

  void _showModal(String modalType) {
    if (modalType == 'addReptileModal') {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const AddReptileModal(),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening $modalType modal...'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 