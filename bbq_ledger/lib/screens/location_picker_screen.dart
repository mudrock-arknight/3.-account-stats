// lib/screens/location_picker_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

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
  late double _lat;
  late double _lng;
  LatLng? _picked;
  final _searchController = TextEditingController();
  bool _searching = false;
  List<_SearchResult> _searchResults = [];

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {'q': query, 'format': 'json', 'limit': '5', 'countrycodes': 'cn'},
      );
      final response = await http.get(uri, headers: {'User-Agent': 'BBQLedger/1.0'});
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        setState(() {
          _searchResults = list.map((item) => _SearchResult(
                name: item['display_name'] ?? '',
                lat: double.parse(item['lat']),
                lng: double.parse(item['lon']),
              )).toList();
          _searching = false;
        });
      }
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  void _goTo(double lat, double lng) {
    setState(() {
      _lat = lat;
      _lng = lng;
      _picked = LatLng(lat, lng);
      _searchResults = [];
      _searchController.clear();
    });
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
      body: Stack(
        children: [
          FlutterMap(
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
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 40),
                          Text('已选位置', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold, backgroundColor: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Search bar
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '搜索地址...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  suffixIcon: _searching
                      ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() { _searchController.clear(); _searchResults = []; }))
                          : null,
                ),
                onChanged: _search,
              ),
            ),
          ),
          // Search results
          if (_searchResults.isNotEmpty)
            Positioned(
              top: 60,
              left: 10,
              right: 10,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = _searchResults[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, color: Colors.blue),
                        title: Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                        onTap: () => _goTo(r.lat, r.lng),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchResult {
  final String name;
  final double lat;
  final double lng;
  const _SearchResult({required this.name, required this.lat, required this.lng});
}