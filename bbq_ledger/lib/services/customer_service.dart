import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

class CustomerService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Customer>> getAll() async {
    final response = await _client
        .from('customers')
        .select()
        .order('name');
    return (response as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> create(String name, {String phone = '', String address = '', String notes = '', double? latitude, double? longitude}) async {
    final customer = Customer(
      id: '',
      name: name,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
    final response = await _client.from('customers').insert(customer.toJson()).select().single();
    return Customer.fromJson(response);
  }

  Future<void> update(Customer customer) async {
    await _client.from('customers').update(customer.toUpdateJson()).eq('id', customer.id);
  }

  Future<void> delete(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  Future<List<Customer>> search(String query) async {
    final response = await _client
        .from('customers')
        .select()
        .ilike('name', '%$query%')
        .order('name');
    return (response as List).map((e) => Customer.fromJson(e)).toList();
  }
}