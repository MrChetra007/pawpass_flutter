import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _permissionKey = 'notification_permission_requested';

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen based on payload
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final ios = notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<bool> shouldRequestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionKey) != true;
  }

  Future<void> markPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionKey, true);
  }

  Future<void> scheduleAppointmentReminder({
    required String appointmentId,
    required String petName,
    required String title,
    required DateTime appointmentDate,
  }) async {
    final notificationDate = appointmentDate.subtract(
      const Duration(hours: 24),
    );

    if (notificationDate.isBefore(DateTime.now())) return;

    await notifications.zonedSchedule(
      id: _generateId('apt', appointmentId),
      title: 'Appointment Reminder',
      body: '$petName - $title is tomorrow!',
      scheduledDate: tz.TZDateTime.from(notificationDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments',
          'Appointments',
          channelDescription: 'Appointment reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'appointment:$appointmentId',
    );
  }

  Future<void> scheduleVaccineReminder({
    required String vaccineId,
    required String petName,
    required String vaccineName,
    required DateTime dueDate,
  }) async {
    final notificationDate = dueDate.subtract(const Duration(days: 7));

    if (notificationDate.isBefore(DateTime.now())) return;

    await notifications.zonedSchedule(
      id: _generateId('vac', vaccineId),
      title: 'Vaccine Due Soon',
      body: '$petName - $vaccineName is due in 7 days',
      scheduledDate: tz.TZDateTime.from(notificationDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'vaccines',
          'Vaccines',
          channelDescription: 'Vaccine reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'vaccine:$vaccineId',
    );
  }

  Future<void> cancelAppointmentReminder(String appointmentId) async {
    await notifications.cancel(id: _generateId('apt', appointmentId));
  }

  Future<void> cancelVaccineReminder(String vaccineId) async {
    await notifications.cancel(id: _generateId('vac', vaccineId));
  }

  Future<void> scheduleMedicationReminder({
    required String medicationId,
    required String petName,
    required String medicationName,
    required String? dosage,
    required List<String> timeOfDay,
    required String frequency,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await cancelMedicationReminder(medicationId);

    final now = DateTime.now();
    final start = startDate ?? now;
    DateTime? nextNotificationDate;

    for (final timeSlot in timeOfDay) {
      final time = _parseTimeOfDay(timeSlot);
      if (time == null) continue;

      DateTime scheduledDate = DateTime(
        start.year,
        start.month,
        start.day,
        time.hour,
        time.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (endDate != null && scheduledDate.isAfter(endDate)) continue;

      nextNotificationDate ??= scheduledDate;

      await notifications.zonedSchedule(
        id: _generateId('med_$timeSlot', medicationId),
        title: 'Medication Reminder',
        body: _buildMedicationBody(petName, medicationName, dosage, timeSlot),
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'medications',
            'Medications',
            channelDescription: 'Medication reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: frequency == 'daily'
            ? DateTimeComponents.time
            : (frequency == 'weekly'
                  ? DateTimeComponents.dayOfWeekAndTime
                  : DateTimeComponents.time),
        payload: 'medication:$medicationId',
      );
    }
  }

  String _buildMedicationBody(
    String petName,
    String medicationName,
    String? dosage,
    String timeSlot,
  ) {
    final timeLabel = _timeSlotLabel(timeSlot);
    final dosageText = dosage != null ? ' ($dosage)' : '';
    return '$petName - $medicationName$dosageText is due at $timeLabel';
  }

  String _timeSlotLabel(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return 'morning';
      case 'afternoon':
        return 'afternoon';
      case 'evening':
        return 'evening';
      case 'night':
        return 'night';
      default:
        return timeSlot;
    }
  }

  ({int hour, int minute})? _parseTimeOfDay(String timeSlot) {
    switch (timeSlot) {
      case 'morning':
        return (hour: 8, minute: 0);
      case 'afternoon':
        return (hour: 12, minute: 0);
      case 'evening':
        return (hour: 18, minute: 0);
      case 'night':
        return (hour: 21, minute: 0);
      default:
        return null;
    }
  }

  Future<void> cancelMedicationReminder(String medicationId) async {
    final prefixes = ['morning', 'afternoon', 'evening', 'night'];
    for (final prefix in prefixes) {
      await notifications.cancel(id: _generateId('med_$prefix', medicationId));
    }
  }

  Future<void> scheduleAllReminders({
    required List<Map<String, dynamic>> appointments,
    required List<Map<String, dynamic>> vaccines,
    required List<Map<String, dynamic>> medications,
  }) async {
    await notifications.cancelAll();

    for (final apt in appointments) {
      await scheduleAppointmentReminder(
        appointmentId: apt['id'] as String,
        petName: apt['petName'] as String,
        title: apt['title'] as String,
        appointmentDate: apt['datetime'] as DateTime,
      );
    }

    for (final vac in vaccines) {
      await scheduleVaccineReminder(
        vaccineId: vac['id'] as String,
        petName: vac['petName'] as String,
        vaccineName: vac['name'] as String,
        dueDate: vac['dueDate'] as DateTime,
      );
    }

    for (final med in medications) {
      await scheduleMedicationReminder(
        medicationId: med['id'] as String,
        petName: med['petName'] as String,
        medicationName: med['name'] as String,
        dosage: med['dosage'] as String?,
        timeOfDay: (med['timeOfDay'] as List<String>).toList(),
        frequency: med['frequency'] as String? ?? 'daily',
        startDate: med['startDate'] as DateTime?,
        endDate: med['endDate'] as DateTime?,
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    await notifications.cancelAll();
  }

  int _generateId(String prefix, String id) {
    return '${prefix}_$id'.hashCode.abs() % 2147483647;
  }
}
