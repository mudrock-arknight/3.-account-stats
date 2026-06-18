import 'dart:convert';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final double? latitude;
  final double? longitude;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    this.latitude,
    this.longitude,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    final (lat, lng) = _parseCoords((json['notes'] as String?) ?? '');
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'notes': _buildNotes(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'notes': _buildNotes(),
    };
  }

  String _buildNotes() {
    final map = <String, dynamic>{};
    // Parse existing notes if it's valid JSON — preserve all keys
    if (notes.isNotEmpty) {
      try {
        final existing = jsonDecode(notes);
        if (existing is Map<String, dynamic>) {
          map.addAll(existing);
        } else {
          map['text'] = notes;
        }
      } catch (_) {
        // Not JSON, store as text note
        map['text'] = notes;
      }
    }
    // Update coords (always fresh)
    if (latitude != null) map['lat'] = latitude;
    if (longitude != null) map['lng'] = longitude;
    return map.isEmpty ? '' : jsonEncode(map);
  }

  static (double?, double?) _parseCoords(String notes) {
    if (notes.isEmpty) return (null, null);
    try {
      final map = jsonDecode(notes) as Map<String, dynamic>;
      final lat = map['lat'];
      final lng = map['lng'];
      return (
        lat is num ? lat.toDouble() : null,
        lng is num ? lng.toDouble() : null,
      );
    } catch (_) {
      return (null, null);
    }
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? address,
    String? notes,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      latitude: clearLocation ? null : (latitude ?? this.latitude),
      longitude: clearLocation ? null : (longitude ?? this.longitude),
    );
  }
}