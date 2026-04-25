import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/vaccine_repository.dart';
import '../../data/repositories/medication_repository.dart';
import '../../data/repositories/pet_repository.dart';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() =>
      _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  bool _notificationsEnabled = true;
  List<PendingNotificationRequest> _pendingNotifications = [];
  bool _loadingPending = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadPendingNotifications();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    if (value) {
      final granted = await NotificationService().requestPermission();
      if (!granted) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Please enable notifications in your device settings to receive alerts for appointments and vaccines.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
    } else {
      await NotificationService().cancelAllNotifications();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
    if (!value && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifications disabled')));
    }
  }

  Future<void> _loadPendingNotifications() async {
    setState(() {
      _loadingPending = true;
    });
    try {
      final pending = await NotificationService().notifications
          .pendingNotificationRequests();
      setState(() {
        _pendingNotifications = pending;
        _loadingPending = false;
      });
    } catch (e) {
      setState(() {
        _loadingPending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: const Text('Notifications')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(
                _notificationsEnabled
                    ? 'Receive push notifications'
                    : 'Notifications are disabled',
              ),
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 32),
            if (!_notificationsEnabled) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enable notifications to test and receive alerts',
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text('Tips:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(
                '• Immediate: Shows right away\n'
                '• 10 seconds: Wait for the notification\n'
                '• 1 minute: Wait for the notification\n'
                '• Cancel All: Removes all scheduled notifications',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _testImmediate(context),
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Immediate'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _test10s(context),
                    icon: const Icon(Icons.timer),
                    label: const Text('10 sec'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _test1m(context),
                    icon: const Icon(Icons.timer),
                    label: const Text('1 min'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _cancelNotifications(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Reminders',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Reschedule reminders for all your pets\' appointments, vaccines, and medications.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _rescheduleAllReminders(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Reschedule All Reminders'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Notifications',
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: _loadPendingNotifications,
                    icon: _loadingPending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_pendingNotifications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'No pending notifications',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pendingNotifications.length,
                    itemBuilder: (context, index) {
                      final pending = _pendingNotifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text(pending.title ?? 'No title'),
                          subtitle: Text(pending.body ?? 'No body'),
                          trailing: Text(
                            'ID: ${pending.id}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPendingNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Pending List'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _testImmediate(BuildContext ctx) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: 'Immediate Test',
      body: 'This notification appeared right away!',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test Notifications',
          channelDescription: 'Test notification channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Immediate notification fired!')),
      );
    }
  }

  void _test10s(BuildContext ctx) async {
    final notificationTime = DateTime.now().add(const Duration(seconds: 10));

    await NotificationService().notifications.zonedSchedule(
      id: 1,
      title: 'Scheduled (10s)',
      body: 'This notification was scheduled for 10 seconds from now',
      scheduledDate: tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test Notifications',
          channelDescription: 'Test notification channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Notification scheduled for 10 seconds!')),
      );
    }
  }

  void _test1m(BuildContext ctx) async {
    final notificationTime = DateTime.now().add(const Duration(minutes: 1));

    await NotificationService().notifications.zonedSchedule(
      id: 2,
      title: 'Scheduled (1m)',
      body: 'This notification was scheduled for 1 minute from now',
      scheduledDate: tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'test',
          'Test Notifications',
          channelDescription: 'Test notification channel',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Notification scheduled for 1 minute!')),
      );
    }
  }

  void _cancelNotifications(BuildContext ctx) async {
    await NotificationService().cancelAllNotifications();
    if (mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('All notifications cancelled!')),
      );
    }
  }

  Future<void> _rescheduleAllReminders(BuildContext ctx) async {
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Rescheduling reminders...')),
    );

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Please log in to reschedule reminders')),
        );
        return;
      }

      final appointments = await AppointmentRepository(supabase).getUpcomingAppointments();
      final vaccines = await VaccineRepository(supabase).getVaccines();
      final medications = await MedicationRepository(supabase).getMedications(activeOnly: true);
      final pets = await PetRepository(supabase).getPets();

      final petMap = {for (final p in pets) p.id: p.name};

      final aptData = appointments
          .where((a) => a.datetime.isAfter(DateTime.now()))
          .map((a) => {
                'id': a.id,
                'petName': petMap[a.petId] ?? 'Your pet',
                'title': a.title,
                'datetime': a.datetime,
              })
          .toList();

      final vacData = vaccines
          .where((v) => v.nextDueDate != null && v.nextDueDate!.isAfter(DateTime.now()))
          .map((v) => {
                'id': v.id,
                'petName': petMap[v.petId] ?? 'Your pet',
                'name': v.name,
                'dueDate': v.nextDueDate,
              })
          .toList();

      final medData = medications
          .where((m) => m.timeOfDay.isNotEmpty)
          .map((m) => {
                'id': m.id,
                'petName': petMap[m.petId] ?? 'Your pet',
                'name': m.name,
                'dosage': m.dosage,
                'timeOfDay': m.timeOfDay,
                'frequency': m.frequency,
                'startDate': m.startDate,
                'endDate': m.endDate,
              })
          .toList();

      await NotificationService().scheduleAllReminders(
        appointments: aptData,
        vaccines: vacData,
        medications: medData,
      );

      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Scheduled ${aptData.length} appointments, ${vacData.length} vaccines, ${medData.length} medications',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
