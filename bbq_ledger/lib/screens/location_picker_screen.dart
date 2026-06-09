// lib/screens/location_picker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String title;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = '选择位置',
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default to Beijing center if no initial location
  late double _lat;
  late double _lng;
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat ?? 39.9042;
    _lng = widget.initialLng ?? 116.4074;
    if (widget.initialLat != null) {
      _picked = LatLng(_lat, _lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _picked != null
                ? () => Navigator.pop(context, {'lat': _picked!.latitude, 'lng': _picked!.longitude})
                : null,
            child: const Text('确认', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(_lat, _lng),
          initialZoom: 15.0,
          onTap: (tapPosition, point) {
            setState(() => _picked = point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.bbq.ledger',
          ),
          if (_picked != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _picked!,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
        ],
      ),
    );
  }
}