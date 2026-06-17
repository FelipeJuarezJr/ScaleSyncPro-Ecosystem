import 'package:flutter_test/flutter_test.dart';
import 'package:scalesync_pro_ecosystem/models/reptile.dart';
import 'package:scalesync_pro_ecosystem/models/task_schedule.dart';
import 'package:scalesync_pro_ecosystem/utils/task_utils.dart';

void main() {
  group('calculateTodayTasks tests', () {
    final testReptiles = [
      Reptile(name: 'Reptile 1', species: 'Gekko gecko', gender: 'Male'),
      Reptile(name: 'Reptile 2', species: 'Python regius', gender: 'Female'),
    ];

    test('should not include tasks scheduled in the future', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final schedules = [
        TaskSchedule(
          description: 'Future Feeding',
          timeOfDay: '08:00',
          startDate: futureDate,
          intervalValue: 1,
          intervalUnit: 'Days',
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          actions: ['Feeding'],
          targetType: 'single',
        ),
      ];

      final count = calculateTodayTasks(schedules, testReptiles);
      expect(count, 0);
    });

    test('should include daily tasks matching today', () {
      final today = DateTime.now();
      final schedules = [
        TaskSchedule(
          description: 'Daily Cleaning',
          timeOfDay: '09:00',
          startDate: today.subtract(const Duration(days: 2)),
          intervalValue: 1,
          intervalUnit: 'Days',
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          actions: ['Cleaned (spot)'],
          targetType: 'single',
        ),
      ];

      final count = calculateTodayTasks(schedules, testReptiles);
      expect(count, 1);
    });

    test('should scale targetType all tasks by the number of reptiles', () {
      final today = DateTime.now();
      final schedules = [
        TaskSchedule(
          description: 'Feed All',
          timeOfDay: '10:00',
          startDate: today.subtract(const Duration(days: 1)),
          intervalValue: 1,
          intervalUnit: 'Days',
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
          actions: ['Feeding'],
          targetType: 'all',
        ),
      ];

      final count = calculateTodayTasks(schedules, testReptiles);
      expect(count, 2); // 1 action * 2 reptiles = 2
    });

    test('should not include weekly tasks on other weeks if intervalValue > 1', () {
      // Monday 2026-06-15
      final baseDate = DateTime(2026, 6, 15);
      final schedules = [
        TaskSchedule(
          description: 'Bi-weekly feed',
          timeOfDay: '12:00',
          startDate: baseDate,
          intervalValue: 2,
          intervalUnit: 'Weeks',
          daysOfWeek: [1], // Monday
          actions: ['Feeding'],
          targetType: 'single',
        ),
      ];

      // Evaluation on same day (week 0 offset) -> should count
      expect(calculateTodayTasks(schedules, testReptiles, evaluationDate: baseDate), 1);

      // Evaluation next Monday (week 1 offset) -> should NOT count (interval is 2)
      expect(calculateTodayTasks(schedules, testReptiles, evaluationDate: baseDate.add(const Duration(days: 7))), 0);

      // Evaluation in 2 Mondays (week 2 offset) -> should count
      expect(calculateTodayTasks(schedules, testReptiles, evaluationDate: baseDate.add(const Duration(days: 14))), 1);
    });
  });
}
