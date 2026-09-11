import 'package:consis_app/core/services/notification_service.dart';
import 'package:consis_app/data/local/hive_manager.dart';
import 'package:consis_app/data/models/reminder_model.dart';
import 'package:consis_app/domain/entities/reminder.dart';
import 'package:consis_app/domain/repositories/reminder_repository.dart';
import 'package:uuid/uuid.dart';

class HiveReminderRepository implements ReminderRepository {
  final _uuid = const Uuid();

  @override
  String newId() => _uuid.v4();

  @override
  Future<List<Reminder>> getAll() async {
    return HiveManager.reminders.values
        .whereType<ReminderModel>()
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Stream<List<Reminder>> watchAll() async* {
    yield await getAll();
    yield* HiveManager.reminders.watch().map(
          (_) => HiveManager.reminders.values
              .whereType<ReminderModel>()
              .map((m) => m.toEntity())
              .toList(),
        );
  }

  @override
  Future<void> save(Reminder reminder) async {
    final model = ReminderModel.fromEntity(reminder);
    await HiveManager.reminders.put(reminder.id, model);

    if (reminder.enabled && reminder.time.isNotEmpty) {
      await NotificationService.scheduleGoalReminder(
        goalId: reminder.id,
        title: reminder.title,
        time: reminder.time,
      );
    } else {
      await NotificationService.cancelGoalReminder(reminder.id);
    }
  }

  @override
  Future<void> delete(String id) async {
    await HiveManager.reminders.delete(id);
    await NotificationService.cancelGoalReminder(id);
  }
}
