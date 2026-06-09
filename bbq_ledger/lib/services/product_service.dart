// lib/services/product_service.dart
import 'dart:convert';
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

  Future<List<Product>> search(String query) async {
    final response = await _client
        .from('products')
        .select()
        .ilike('name', '%$query%')
        .order('name');
    return (response as List).map((e) => Product.fromJson(e)).toList();
  }

  /// Get the last used unit and price for a (customer, product) pair.
  /// Returns (unit, price) — both are nullable.
  Future<({String? unit, double? price})> getLastUnitPrice(
    String customerId,
    String productId,
  ) async {
    // Try the customer's notes JSON first (stores unit+price per product)
    final notesJson = await _getCustomerNotes(customerId);
    if (notesJson != null) {
      final prefs = notesJson['product_prefs'];
      if (prefs is Map<String, dynamic>) {
        final entry = prefs[productId];
        if (entry is Map<String, dynamic>) {
          final unit = entry['unit'] as String?;
          final price = (entry['price'] as num?)?.toDouble();
          return (unit: unit, price: price);
        }
      }
    }

    // Fallback: look up the customer_product_prices table for price only
    final priceResp = await _client
        .from('customer_product_prices')
        .select('unit_price')
        .eq('customer_id', customerId)
        .eq('product_id', productId)
        .maybeSingle();

    final price = priceResp != null
        ? (priceResp['unit_price'] as num).toDouble()
        : null;
    return (unit: null, price: price);
  }

  /// Save the last used unit and price for a (customer, product) pair.
  Future<void> saveUnitPrice(
    String customerId,
    String productId,
    String unit,
    double price,
  ) async {
    // Save to customer_product_prices (existing price table)
    await _client.from('customer_product_prices').upsert({
      'customer_id': customerId,
      'product_id': productId,
      'unit_price': price,
    });

    // Also save to customer notes for unit+price memory
    final notesJson = await _getCustomerNotes(customerId) ?? <String, dynamic>{};
    final prefs = (notesJson['product_prefs'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    prefs[productId] = {'unit': unit, 'price': price};
    notesJson['product_prefs'] = prefs;

    await _client
        .from('customers')
        .update({'notes': jsonEncode(notesJson)})
        .eq('id', customerId);
  }

  /// Get the last used unit for a (customer, product) pair.
  Future<String?> getLastUnit(String customerId, String productId) async {
    final result = await getLastUnitPrice(customerId, productId);
    return result.unit;
  }

  // --- Legacy API (for backward compatibility) ---

  Future<double?> getLastPrice(String customerId, String productId) async {
    final result = await getLastUnitPrice(customerId, productId);
    return result.price;
  }

  Future<void> savePrice(String customerId, String productId, double price) async {
    await _client.from('customer_product_prices').upsert({
      'customer_id': customerId,
      'product_id': productId,
      'unit_price': price,
    });
  }

  // --- Helpers ---

  Future<Map<String, dynamic>?> _getCustomerNotes(String customerId) async {
    final resp = await _client
        .from('customers')
        .select('notes')
        .eq('id', customerId)
        .maybeSingle();

    if (resp == null) return null;
    final notes = (resp['notes'] as String?) ?? '';
    if (notes.isEmpty) return null;
    try {
      final decoded = jsonDecode(notes);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }
}