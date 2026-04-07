import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';

class TestNotificationsScreen extends StatefulWidget {
  const TestNotificationsScreen({super.key});

  @override
  State<TestNotificationsScreen> createState() => _TestNotificationsScreenState();
}

class _TestNotificationsScreenState extends State<TestNotificationsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications disabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              subtitle: Text(_notificationsEnabled ? 'Receive push notifications' : 'Notifications are disabled'),
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
                        style: TextStyle(color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                'Test different notification types:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: () => _showImmediateNotification(context),
                icon: const Icon(Icons.flash_on),
                label: const Text('1. Immediate Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => _showScheduled10s(context),
                icon: const Icon(Icons.timer),
                label: const Text('2. Schedule in 10 seconds'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => _showScheduled1m(context),
                icon: const Icon(Icons.timer_outlined),
                label: const Text('3. Schedule in 1 minute'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () => _cancelAll(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel All Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Tips:',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '• Immediate: Shows right away\n'
                '• 10 seconds: Wait for the notification\n'
                '• 1 minute: Wait for the notification\n'
                '• Cancel All: Removes all scheduled notifications',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showImmediateNotification(BuildContext context) async {
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Immediate notification fired!')),
      );
    }
  }

  Future<void> _showScheduled10s(BuildContext context) async {
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification scheduled for 10 seconds!')),
      );
    }
  }

  Future<void> _showScheduled1m(BuildContext context) async {
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification scheduled for 1 minute!')),
      );
    }
  }

  Future<void> _cancelAll(BuildContext context) async {
    await NotificationService().cancelAllNotifications();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cancelled!')),
      );
    }
  }
}
