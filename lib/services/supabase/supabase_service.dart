import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for interacting with Supabase to query user data
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  late final SupabaseClient _client;
  
  /// Initialize Supabase with the provided URL and anon key
  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  /// Get the Supabase client
  SupabaseClient get client => _client;
  
  /// Query user by NFC card UID
  /// Returns the user's balance if found, null otherwise
  Future<double?> getUserBalance(String cardUid) async {
    try {
      final response = await _client
          .from('users')
          .select('balance')
          .eq('card_uid', cardUid)
          .single();
      
      final balance = response['balance'];
      if (balance is num) {
        return balance.toDouble();
      }
      
      return null;
    } catch (e) {
      // User not found or other error
      return null;
    }
  }
  
  /// Get user information by NFC card UID
  /// Returns user data if found, null otherwise
  Future<Map<String, dynamic>?> getUserByCardUid(String cardUid) async {
    try {
      final response = await _client
          .from('users')
          .select()
          .eq('card_uid', cardUid)
          .single();
      
      return response;
    } catch (e) {
      // User not found or other error
      return null;
    }
  }
}
