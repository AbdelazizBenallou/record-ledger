import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../db/repositories/customer_repository.dart';
import '../models/customer.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final CustomerRepository _customerRepo = CustomerRepository();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> checkDuePayments(String storeId) async {
    final dueToday = await _customerRepo.getDueToday(storeId);
    final overdue = await _customerRepo.getOverdue(storeId);

    // Group overdue by day for cleaner notifications
    final overdueToday = <Customer>[];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    for (final c in overdue) {
      if (c.nextDueDate != null) {
        final dueDay = DateTime(
          c.nextDueDate!.year,
          c.nextDueDate!.month,
          c.nextDueDate!.day,
        );
        if (dueDay == todayStart) {
          overdueToday.add(c);
        }
      }
    }

    final allDue = {...dueToday, ...overdueToday}.toList();
    if (allDue.isEmpty) return;

    final title = dueToday.isNotEmpty
        ? '${dueToday.length} ${dueToday.length == 1 ? 'payment' : 'payments'} due today'
        : 'Overdue payments';

    final body = allDue.take(3).map((c) => c.name).join(', ');
    final suffix = allDue.length > 3 ? ' and ${allDue.length - 3} more' : '';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: '$body$suffix',
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'due_payments',
      'Due Payments',
      channelDescription: 'Notifications for customers with due payments',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}
