// lib/screens/location_picker_screen.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

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
  // WGS-84 coordinates (stored, real GPS)
  late double _lat;
  late double _lng;
  // GCJ-02 coordinates (display only, for Amap tiles alignment)
  LatLng? _pickedGcj;
  final _searchController = TextEditingController();
  bool _searching = false;
  bool _locating = true;
  String _statusText = '正在获取当前位置...';
  List<_SearchResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat ?? 39.9042;
    _lng = widget.initialLng ?? 116.4074;
    if (widget.initialLat != null) {
      _pickedGcj = _wgs84ToGcj02(_lat, _lng);
      _locating = false;
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _setStatus('正在请求定位权限...');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          _setStatus('已拒绝定位权限，将使用默认位置');
          setState(() => _locating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setStatus('定位权限被永久拒绝，请在系统设置中开启');
        setState(() => _locating = false);
        return;
      }

      _setStatus('正在获取GPS位置...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _pickedGcj = _wgs84ToGcj02(_lat, _lng);
          _locating = false;
        });
      }
    } catch (e) {
      _setStatus('GPS获取失败($e)，使用默认位置');
      if (mounted) setState(() => _locating = false);
    }
  }

  void _setStatus(String msg) {
    if (mounted) setState(() => _statusText = msg);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
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
        if (mounted) {
          setState(() {
            _searchResults = list.map((item) => _SearchResult(
                  name: item['display_name'] ?? '',
                  lat: double.parse(item['lat'].toString()),
                  lng: double.parse(item['lon'].toString()),
                )).toList();
            _searching = false;
          });
        }
      } else {
        if (mounted) setState(() => _searching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  void _goTo(double wgsLat, double wgsLng) {
    setState(() {
      _lat = wgsLat;
      _lng = wgsLng;
      _pickedGcj = _wgs84ToGcj02(wgsLat, wgsLng);
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _confirm() {
    if (_pickedGcj != null) {
      Navigator.pop(context, {'lat': _lat, 'lng': _lng});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Map center in GCJ-02 for display alignment with Amap tiles
    final centerGcj = _wgs84ToGcj02(_lat, _lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _pickedGcj != null ? _confirm : null,
            child: const Text('确认', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
      body: _locating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusText),
                ],
              ),
            )
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: centerGcj,
                    initialZoom: 16.0,
                    onTap: (tapPosition, point) {
                      // point is in GCJ-02 (aligned with Amap tiles)
                      // Convert back to WGS-84 for storage
                      final wgs = _gcj02ToWgs84(point.latitude, point.longitude);
                      setState(() {
                        _lat = wgs.latitude;
                        _lng = wgs.longitude;
                        _pickedGcj = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      // Amap (高德) tiles — works in China
                      urlTemplate: 'https://webrd0{s}.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
                      subdomains: const ['1', '2', '3', '4'],
                      userAgentPackageName: 'com.bbq.ledger',
                    ),
                    if (_pickedGcj != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedGcj!,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => setState(() {
                                      _searchController.clear();
                                      _searchResults = [];
                                    }),
                                  )
                                : null,
                      ),
                      onChanged: _search,
                    ),
                  ),
                ),
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
                // Center crosshair hint
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('点击地图选择位置，或使用搜索框', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ===== GCJ-02 / WGS-84 conversion =====

  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  static bool _outOfChina(double lat, double lng) {
    return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }

  static double _transformLat(double x, double y) {
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }

  static LatLng _wgs84ToGcj02(double lat, double lng) {
    if (_outOfChina(lat, lng)) return LatLng(lat, lng);
    double dLat = _transformLat(lng - 105.0, lat - 35.0);
    double dLng = _transformLng(lng - 105.0, lat - 35.0);
    double radLat = lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * pi);
    return LatLng(lat + dLat, lng + dLng);
  }

  static LatLng _gcj02ToWgs84(double lat, double lng) {
    if (_outOfChina(lat, lng)) return LatLng(lat, lng);
    // Newton's method reverse iteration
    double gLat = lat, gLng = lng;
    for (int i = 0; i < 5; i++) {
      final wgs = _wgs84ToGcj02(gLat, gLng);
      gLat += lat - wgs.latitude;
      gLng += lng - wgs.longitude;
    }
    return LatLng(gLat, gLng);
  }
}

class _SearchResult {
  final String name;
  final double lat;
  final double lng;
  const _SearchResult({required this.name, required this.lat, required this.lng});
}