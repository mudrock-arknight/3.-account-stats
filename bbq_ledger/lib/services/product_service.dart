// lib/services/product_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> getAll() async {
    final response = await _client
        .from('products')
        .select()
        .order('name');
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  Future<Product> create(String name, String unit) async {
    final response = await _client.from('products').insert({
      'name': name,
      'unit': unit,
    }).select().single();
    return Product.fromJson(response);
  }

  Future<void> delete(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<double?> getLastPrice(String customerId, String productId) async {
    final response = await _client
        .from('customer_product_prices')
        .select('unit_price')
        .eq('customer_id', customerId)
        .eq('product_id', productId)
        .maybeSingle();

    if (response == null) return null;
    return (response['unit_price'] as num).toDouble();
  }

  Future<void> savePrice(String customerId, String productId, double price) async {
    await _client.from('customer_product_prices').upsert({
      'customer_id': customerId,
      'product_id': productId,
      'unit_price': price,
    });
  }
}