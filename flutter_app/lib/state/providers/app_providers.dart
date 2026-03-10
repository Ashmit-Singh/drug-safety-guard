import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';

// ─── Service Providers ────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

// ─── Auth State ───────────────────────────────────────
final authStateProvider = StreamProvider<bool>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.authStateChanges.map((state) => state.session != null);
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getUserProfile();
});

// ─── Dashboard Stats ──────────────────────────────────
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDashboardStats();
});

// ─── Patients ─────────────────────────────────────────
final patientProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPatient(id);
});

final patientPrescriptionsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPatientPrescriptions(id);
});

// ─── Drugs ────────────────────────────────────────────
final drugSearchProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final api = ref.watch(apiServiceProvider);
  return api.searchDrugs(query);
});

final drugsListProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDrugsList();
});

final drugDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDrug(id);
});

final drugIngredientsProvider = FutureProvider.family<List<dynamic>, String>((ref, drugId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDrugIngredients(drugId);
});

// ─── Prescriptions ────────────────────────────────────
final prescriptionProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPrescription(id);
});

final prescriptionSafetyProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.safetyCheck(id);
});

// ─── Alerts ───────────────────────────────────────────
final alertsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAlerts(
    limit: params['limit'] ?? 20,
    offset: params['offset'] ?? 0,
    severity: params['severity'],
    status: params['status'],
  );
});

final alertDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAlert(id);
});

// ─── Analytics ────────────────────────────────────────
final topInteractionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTopInteractions();
});

final alertTrendsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getAlertTrends();
});

final severityDistributionProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSeverityDistribution();
});

// ─── Prescription Builder State ───────────────────────

class PrescriptionBuilderState {
  final String? patientId;
  final String? patientName;
  final String? prescriptionId;
  final List<Map<String, dynamic>> selectedDrugs;
  final List<Map<String, dynamic>> interactions;
  final bool isLoading;
  final String? error;

  const PrescriptionBuilderState({
    this.patientId,
    this.patientName,
    this.prescriptionId,
    this.selectedDrugs = const [],
    this.interactions = const [],
    this.isLoading = false,
    this.error,
  });

  PrescriptionBuilderState copyWith({
    String? patientId,
    String? patientName,
    String? prescriptionId,
    List<Map<String, dynamic>>? selectedDrugs,
    List<Map<String, dynamic>>? interactions,
    bool? isLoading,
    String? error,
  }) {
    return PrescriptionBuilderState(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      selectedDrugs: selectedDrugs ?? this.selectedDrugs,
      interactions: interactions ?? this.interactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrescriptionBuilderNotifier extends StateNotifier<PrescriptionBuilderState> {
  final ApiService _api;

  PrescriptionBuilderNotifier(this._api) : super(const PrescriptionBuilderState());

  void setPatient(String id, String name) {
    state = state.copyWith(patientId: id, patientName: name);
  }

  Future<void> createPrescription(String doctorId, {String? diagnosis}) async {
    if (state.patientId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final body = <String, dynamic>{
        'patientId': state.patientId,
        'doctorId': doctorId,
      };
      if (diagnosis != null) body['diagnosis'] = diagnosis;
      final result = await _api.createPrescription(body);
      state = state.copyWith(
        prescriptionId: result['id'],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addDrug(Map<String, dynamic> drug, {String dosage = '1 tablet', String frequency = 'Once daily'}) async {
    if (state.prescriptionId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _api.addDrugToPrescription(state.prescriptionId!, {
        'drugId': drug['id'],
        'dosage': dosage,
        'frequency': frequency,
      });

      final updatedDrugs = [...state.selectedDrugs, drug];
      final alerts = (result['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final engineAlerts = (result['interactionCheck'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      state = state.copyWith(
        selectedDrugs: updatedDrugs,
        interactions: [...alerts, ...engineAlerts],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> removeDrug(String drugId) async {
    if (state.prescriptionId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.removeDrugFromPrescription(state.prescriptionId!, drugId);
      final updatedDrugs = state.selectedDrugs.where((d) => d['id'] != drugId).toList();
      state = state.copyWith(selectedDrugs: updatedDrugs, isLoading: false);

      // Re-check safety after removing
      if (updatedDrugs.length >= 2) {
        final safetyResult = await _api.safetyCheck(state.prescriptionId!);
        final interactions = (safetyResult['interactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        state = state.copyWith(interactions: interactions);
      } else {
        state = state.copyWith(interactions: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const PrescriptionBuilderState();
  }
}

final prescriptionBuilderProvider =
    StateNotifierProvider<PrescriptionBuilderNotifier, PrescriptionBuilderState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PrescriptionBuilderNotifier(api);
});
