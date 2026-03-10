import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // ─── Auth ───────────────────────────────────────────

  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  bool get isAuthenticated => currentSession != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // ─── User Profile ──────────────────────────────────

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;

    final response = await client
        .from('users')
        .select('*')
        .eq('auth_id', currentUser!.id)
        .maybeSingle();

    return response;
  }

  // ─── Realtime Subscriptions ─────────────────────────

  RealtimeChannel subscribeToAlerts({
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    return client
        .channel('interaction_alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'interaction_alerts',
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToPrescriptionAlerts({
    required String prescriptionId,
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    return client
        .channel('prescription_alerts_$prescriptionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'interaction_alerts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'prescription_id',
            value: prescriptionId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
  }

  void unsubscribe(RealtimeChannel channel) {
    client.removeChannel(channel);
  }
}
