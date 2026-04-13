import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  String _latitude = '-';
  String _longitude = '-';
  String _accuracy = '-';
  String _status = 'Press the button to get your location';
  bool _isLoading = false;

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching location...';
    });

    try {
      // Step 1: Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = 'Location services are disabled. Please enable GPS.';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = 'Location permission denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status =
              'Location permission permanently denied. Enable it in settings.';
          _isLoading = false;
        });
        return;
      }

      // Step 3: Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude.toStringAsFixed(6);
        _longitude = position.longitude.toStringAsFixed(6);
        _accuracy = '${position.accuracy.toStringAsFixed(1)} m';
        _status = 'Location fetched successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Location'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('successfully')
                    ? Colors.green.shade50
                    : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _status.contains('successfully')
                      ? Colors.green.shade200
                      : Colors.teal.shade200,
                ),
              ),
              child: Text(
                _status,
                style: TextStyle(
                  color: _status.contains('successfully')
                      ? Colors.green.shade800
                      : Colors.teal.shade800,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Coordinates cards
            _buildInfoCard('Latitude', _latitude, Icons.explore),
            const SizedBox(height: 12),
            _buildInfoCard('Longitude', _longitude, Icons.explore_outlined),
            const SizedBox(height: 12),
            _buildInfoCard('Accuracy', _accuracy, Icons.gps_fixed),

            const Spacer(),

            // Get location button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.location_on),
                label: Text(_isLoading ? 'Fetching...' : 'Get My Location'),
                onPressed: _isLoading ? null : _getLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Emulator tip
            const Text(
              'Tip: On emulator go to the three dots (...) → Location tab to set a fake GPS location.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade50,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.shade50,
            child: Icon(icon, color: Colors.teal, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
