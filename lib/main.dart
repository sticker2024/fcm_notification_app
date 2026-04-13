import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/home_screen.dart';

// ✅ Add this background handler BEFORE using it
@pragma('vm:entry-point')
Future<void> backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message received:');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(backgroundHandler);

  // Request notification permissions on startup
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyDevicesApp());
}

class MyDevicesApp extends StatelessWidget {
  const MyDevicesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Added the missing '{' here
    return MaterialApp(
      title: 'My Devices',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
