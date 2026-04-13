import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotifScreen extends StatefulWidget {
  const LocalNotifScreen({super.key});

  @override
  State<LocalNotifScreen> createState() => _LocalNotifScreenState();
}

class _LocalNotifScreenState extends State<LocalNotifScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String _lastNotification = 'No notification sent yet';
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (mounted) {
          setState(() {
            _lastNotification =
                'Notification tapped!\nPayload: ${response.payload ?? 'none'}';
          });
        }
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'main_channel',
      'Main Notifications',
      description: 'This is the main notification channel',
      importance: Importance.max,
    );

    // ✅ FIXED: Changed . to < and added >
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(channel);

    if (mounted) setState(() => _initialized = true);
  }

  Future<void> _showSimpleNotification() async {
    _notificationCount++;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'main_channel',
          'Main Notifications',
          channelDescription: 'This is the main notification channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      _notificationCount,
      'Hello from My Devices!',
      'This is local notification #$_notificationCount',
      details,
      payload: 'notification_$_notificationCount',
    );

    if (mounted) {
      setState(() {
        _lastNotification =
            'Sent: "Hello from My Devices!"\nLocal notification #$_notificationCount';
      });
    }
  }

  Future<void> _showCustomNotification(String title, String body) async {
    _notificationCount++;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'main_channel',
          'Main Notifications',
          channelDescription: 'This is the main notification channel',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      _notificationCount,
      title,
      body,
      details,
      payload: 'custom_$_notificationCount',
    );

    if (mounted) {
      setState(() {
        _lastNotification = 'Sent: "$title"\n$body';
      });
    }
  }

  final TextEditingController _titleController = TextEditingController(
    text: 'My Custom Title',
  );
  final TextEditingController _bodyController = TextEditingController(
    text: 'My Custom Message',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notifications'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      // ✅ FIXED: Wrap with SingleChildScrollView to prevent overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _initialized
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _initialized
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _initialized ? Icons.check_circle : Icons.hourglass_empty,
                    color: _initialized ? Colors.green : Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _initialized ? 'Notifications ready!' : 'Initializing...',
                    style: TextStyle(
                      color: _initialized
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Simple Notification',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.notifications),
                label: const Text('Send Simple Notification'),
                onPressed: _initialized ? _showSimpleNotification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Custom Notification',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Send Custom Notification'),
                onPressed: _initialized
                    ? () => _showCustomNotification(
                        _titleController.text,
                        _bodyController.text,
                      )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ✅ REMOVED: Spacer() was causing the overflow
            // Now content will scroll naturally
            const SizedBox(height: 24), // Added spacing before last section

            const Text(
              'Last notification:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _lastNotification,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 20), // Extra bottom padding
          ],
        ),
      ),
    );
  }
}
