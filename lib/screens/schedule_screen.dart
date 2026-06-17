import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:scalesync_pro_ecosystem/models/task_schedule.dart';
import 'package:scalesync_pro_ecosystem/services/task_schedule_service.dart';
import 'package:scalesync_pro_ecosystem/widgets/add_task_modal.dart';
import 'package:scalesync_pro_ecosystem/utils/theme.dart';


class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final TaskScheduleService _scheduleService = TaskScheduleService();

  void _showAddTaskModal([TaskSchedule? schedule]) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddTaskModal(schedule: schedule),
    );
  }

  String _formatDaysOfWeek(List<int> days) {
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.map((d) => dayNames[d - 1]).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 768;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showAddTaskModal(),
              backgroundColor: isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
              foregroundColor: isDark ? Colors.black : Colors.white,
              child: const Icon(Icons.add_alarm),
            )
          : null,
      body: StreamBuilder<List<TaskSchedule>>(
        stream: _scheduleService.watchSchedules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Card(
                color: isDark ? AppTheme.bgPrimary : Colors.white,
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ),
            );
          }

          final schedules = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Header Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage tasks and feeding schedules',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isMobile)
                        ElevatedButton.icon(
                          onPressed: () => _showAddTaskModal(),
                          icon: const Icon(Icons.add_alarm, size: 18, color: Colors.white),
                          label: const Text('Add Schedule', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C5530),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content Section
              if (schedules.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 80,
                            color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No active schedules',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textPrimary : AppTheme.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Schedule feed, weight changes, and clean logs here.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddTaskModal(),
                            icon: const Icon(Icons.add_alarm, size: 18),
                            label: const Text('Create Schedule'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2C5530),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (screenWidth <= 1100 ? 2 : 3),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isMobile ? (screenWidth <= 400 ? 2.0 : 2.5) : 2.0,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final schedule = schedules[index];
                        return _buildScheduleCard(schedule, isDark, theme);
                      },
                      childCount: schedules.length,
                    ),
                  ),
                ),
              
              // Bottom safe padding for mobile scrolling without FAB overlap
              if (isMobile)
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleCard(TaskSchedule schedule, bool isDark, ThemeData theme) {
    return Card(
      elevation: isDark ? 0 : 2,
      color: isDark ? AppTheme.bgPrimary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        side: isDark ? const BorderSide(color: AppTheme.borderColor) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showAddTaskModal(schedule),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Actions Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      schedule.description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.primaryColor : const Color(0xFF2C5530)).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                    ),
                    child: Text(
                      '${schedule.actions.length} ${schedule.actions.length == 1 ? 'Action' : 'Actions'}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.primaryColor : const Color(0xFF2C5530),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Recurrence Text
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: 14,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Every ${schedule.intervalValue} ${schedule.intervalValue == 1 ? schedule.intervalUnit.replaceAll('s', '') : schedule.intervalUnit} on ${_formatDaysOfWeek(schedule.daysOfWeek)} at ${schedule.timeOfDay}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Starts On Text
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Starts on: ${DateFormat('dd-MM-yyyy').format(schedule.startDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Target and Edit Action Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Target Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.bgSecondary : const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                      border: Border.all(
                        color: isDark ? AppTheme.borderColor : AppTheme.lightBorderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          schedule.targetType == 'all' ? Icons.group : Icons.pets,
                          size: 12,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.targetType == 'all' ? 'All animals' : (schedule.reptileName ?? 'Single animal'),
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: isDark ? AppTheme.textLight : AppTheme.lightTextLight,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}