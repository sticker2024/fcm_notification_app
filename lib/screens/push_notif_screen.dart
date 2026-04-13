import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background message handler (works when app is terminated)
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.notification?.title}');

  // Show notification when app is in background
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
    iOS: DarwinInitializationSettings(),
  );

  await localNotifications.initialize(settings);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'fcm_channel',
    'Firebase Notifications',
    channelDescription: 'Channel for push notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await localNotifications.show(
    DateTime.now().millisecond,
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? 'You have a new message',
    notificationDetails,
  );
}

class PushNotifScreen extends StatefulWidget {
  const PushNotifScreen({super.key});

  @override
  State<PushNotifScreen> createState() => _PushNotifScreenState();
}

class _PushNotifScreenState extends State<PushNotifScreen> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String _token = 'Fetching token...';
  String _lastMessage = 'No message received yet';
  final List<Map<String, String>> _messageHistory = [];
  bool _isLoading = true;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp();

    // Initialize local notifications
    await _initLocalNotifications();

    // Request permission
    await _requestPermission();

    // Get FCM token
    await _getToken();

    // Setup message handlers
    _setupMessageHandlers();

    // Check for initial message (app opened from terminated state)
    await _checkInitialMessage();

    setState(() => _isLoading = false);
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_channel',
      'Firebase Notifications',
      description: 'Channel for Firebase push notifications',
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    setState(() {
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    });

    if (_permissionGranted) {
      print('✅ Permission granted for notifications');
    } else {
      print('❌ Permission denied for notifications');
    }
  }

  Future<void> _getToken() async {
    try {
      String? token = await _messaging.getToken();
      setState(() {
        _token = token ?? 'Could not get token';
      });
      print('📱 FCM Token: $_token');

      // Subscribe to a topic (optional - for testing without token)
      await _messaging.subscribeToTopic('all_devices');
      print('✅ Subscribed to topic: all_devices');
    } catch (e) {
      print('Error getting token: $e');
      setState(() {
        _token = 'Error getting token. Check Firebase setup.';
      });
    }
  }

  void _setupMessageHandlers() {
    // 1. Foreground messages (app is open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received');
      _handleNewMessage(message);
      _showLocalNotification(message);
      _showPopupDialog(message);
    });

    // 2. App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 App opened from background notification');
      _handleNewMessage(message);

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opened from: ${message.notification?.title ?? 'Notification'}',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('📨 App opened from terminated state via notification');
      _handleNewMessage(initialMessage);
    }
  }

  void _handleNewMessage(RemoteMessage message) {
    String title = message.notification?.title ?? 'No title';
    String body = message.notification?.body ?? 'No body';
    String fullMessage = '$title: $body';
    String timestamp = DateTime.now().toString().substring(0, 19);

    setState(() {
      _lastMessage = fullMessage;
      _messageHistory.insert(0, {
        'title': title,
        'body': body,
        'timestamp': timestamp,
        'full': fullMessage,
      });
      // Keep only last 20 messages
      if (_messageHistory.length > 20) _messageHistory.removeLast();
    });

    print('📨 New message: $fullMessage at $timestamp');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fcm_channel',
          'Firebase Notifications',
          channelDescription: 'Channel for Firebase push notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      details,
    );
  }

  void _showPopupDialog(RemoteMessage message) {
    String title = message.notification?.title ?? 'Notification Received';
    String body = message.notification?.body ?? 'You have a new message';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.indigo),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body),
              const SizedBox(height: 12),
              const Divider(),
              Text(
                'Received at: ${DateTime.now().toString().substring(0, 19)}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _copyToken() {
    // Copy token to clipboard
    Clipboard.setData(ClipboardData(text: _token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Token copied to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearHistory() {
    setState(() {
      _messageHistory.clear();
      _lastMessage = 'No message received yet';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message history cleared'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);
    await _getToken();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Push Notifications (FCM)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshToken,
            tooltip: 'Refresh Token',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _messageHistory.isNotEmpty ? _clearHistory : null,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission Status
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _permissionGranted
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _permissionGranted
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _permissionGranted
                              ? Icons.check_circle
                              : Icons.warning,
                          color: _permissionGranted ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _permissionGranted
                              ? '✅ Notifications enabled'
                              : '⚠️ Permission denied - enable in settings',
                          style: TextStyle(
                            color: _permissionGranted
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Token Section
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.vpn_key, color: Colors.indigo),
                              const SizedBox(width: 8),
                              const Text(
                                'Device FCM Token',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: SelectableText(
                            _token,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.copy, size: 18),
                                  label: const Text('Copy Token'),
                                  onPressed: _copyToken,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Last Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📨 Last Received Message:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastMessage,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Message History
                  if (_messageHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '📜 Message History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearHistory,
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _messageHistory.length,
                      itemBuilder: (context, index) {
                        final msg = _messageHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: Text(
                                '${_messageHistory.length - index}',
                                style: TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              msg['title'] ?? 'No title',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg['body'] ?? 'No body'),
                                const SizedBox(height: 4),
                                Text(
                                  msg['timestamp'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.notifications,
                              color: Colors.indigo,
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'How to test push notifications:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('1. 📋 Copy the token above'),
                        const Text(
                          '2. 🔥 Go to Firebase Console → Cloud Messaging',
                        ),
                        const Text('3. ✏️ Click "Send your first message"'),
                        const Text('4. 📝 Enter title and message body'),
                        const Text('5. 🔑 Click "Send test message"'),
                        const Text('6. 📱 Paste your device token'),
                        const Text('7. 🚀 Click "Test" and check your device!'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.blue),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Test with app OPEN (popup + notification) or BACKGROUND (notification only)',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
