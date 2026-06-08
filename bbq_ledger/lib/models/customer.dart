// lib/models/customer.dart
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: (json['phone'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
    };
  }
}