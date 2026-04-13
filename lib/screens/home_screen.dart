import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'location_screen.dart';
import 'local_notif_screen.dart';
import 'push_notif_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      _Feature(
        title: 'Camera / Image Picker',
        subtitle: 'Take photos or pick from gallery',
        icon: Icons.camera_alt,
        color: Colors.deepPurple,
        screen: const CameraScreen(),
      ),
      _Feature(
        title: 'Device Location',
        subtitle: 'Get GPS coordinates',
        icon: Icons.location_on,
        color: Colors.teal,
        screen: const LocationScreen(),
      ),
      _Feature(
        title: 'Local Notifications',
        subtitle: 'Show in-app alerts',
        icon: Icons.notifications,
        color: Colors.orange,
        screen: const LocalNotifScreen(),
      ),
      _Feature(
        title: 'Push Notifications (FCM)',
        subtitle: 'Receive remote messages',
        icon: Icons.cloud_download,
        color: Colors.indigo,
        screen: const PushNotifScreen(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices — Lesson 8'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: features.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final f = features[i];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              leading: CircleAvatar(
                backgroundColor: f.color.withOpacity(0.12),
                child: Icon(f.icon, color: f.color),
              ),
              title: Text(
                f.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(f.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => f.screen),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Feature {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final Widget screen;
  const _Feature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });
}
