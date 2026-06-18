class Product {
  final String id;
  final String name;
  final String unit;

  const Product({
    required this.id,
    required this.name,
    this.unit = '包',
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      unit: (json['unit'] as String?) ?? '包',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
    };
  }
}