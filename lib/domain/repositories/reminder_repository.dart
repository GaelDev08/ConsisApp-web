import 'package:consis_app/domain/entities/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getAll();
  Stream<List<Reminder>> watchAll();
  Future<void> save(Reminder reminder);
  Future<void> delete(String id);
  String newId();
}
