import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for interacting with Supabase to query user data
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  
  SupabaseService._();
  
  /// Get the Supabase client (uses global Supabase instance)
  SupabaseClient get client => Supabase.instance.client;
  
  /// Query user by NFC card UID
  /// Returns the user's balance if found, null otherwise
  Future<double?> getUserBalance(String cardUid) async {
    try {
      final response = await client
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
      print('Debug: Querying users table for card_uid: $cardUid');
      final response = await client
          .from('users')
          .select()
          .eq('card_uid', cardUid);
      
      print('Debug: Query returned ${response.length} rows');
      if (response.isNotEmpty) {
        print('Debug: First row: ${response[0]}');
        return response[0];
      }
      
      print('Debug: No matching user found');
      return null;
    } catch (e) {
      print('Debug: Query failed with error: $e');
      // User not found or other error
      return null;
    }
  }
  
  /// Get all users (for debugging)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      print('Debug: Querying all users from database');
      print('Debug: Using anon key - this might be blocked by RLS policies');
      final response = await client
          .from('users')
          .select();
      
      print('Debug: Found ${response.length} users in database');
      for (var user in response) {
        print('Debug: User - card_uid: ${user['card_uid']}, name: ${user['name']}, balance: ${user['balance']}');
      }
      
      return response;
    } catch (e) {
      print('Debug: Failed to get all users: $e');
      print('Debug: This is likely due to RLS policies blocking anon key access');
      return [];
    }
  }
  
  /// Check if table exists and get table info (for debugging)
  Future<void> debugCheckTables() async {
    try {
      print('Debug: Checking available tables in database');
      // Try to get table information from information_schema
      final response = await client
          .rpc('get_tables');
      
      print('Debug: Tables response: $response');
    } catch (e) {
      print('Debug: Failed to check tables: $e');
      print('Debug: This might be due to RLS policies or missing RPC function');
      
      // Try alternative approach - list from different possible table names
      final possibleTables = ['users', 'user', 'cards', 'card', 'nfc_users', 'nfc_cards'];
      for (var tableName in possibleTables) {
        try {
          print('Debug: Trying table: $tableName');
          final testQuery = await client
              .from(tableName)
              .select()
              .limit(1);
          print('Debug: Table $tableName exists and has data');
          break;
        } catch (e) {
          print('Debug: Table $tableName does not exist or no access: ${e.toString()}');
        }
      }
    }
  }
}
