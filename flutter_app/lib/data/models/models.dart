import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

/// ─── Drug ─────────────────────────────────────────────
@freezed
class Drug with _$Drug {
  const factory Drug({
    required String id,
    @JsonKey(name: 'brand_name') required String brandName,
    @JsonKey(name: 'generic_name') required String genericName,
    @JsonKey(name: 'drug_class') String? drugClass,
    String? strength,
    String? manufacturer,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Drug;

  factory Drug.fromJson(Map<String, dynamic> json) => _$DrugFromJson(json);
}

/// ─── Patient ──────────────────────────────────────────
@freezed
class Patient with _$Patient {
  const factory Patient({
    required String id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    @JsonKey(name: 'date_of_birth') required String dateOfBirth,
    String? gender,
    @JsonKey(name: 'blood_type') String? bloodType,
    @Default([]) List<String> allergies,
    @JsonKey(name: 'medical_conditions') @Default([]) List<String> medicalConditions,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Patient;

  factory Patient.fromJson(Map<String, dynamic> json) => _$PatientFromJson(json);
}

/// ─── Doctor ───────────────────────────────────────────
@freezed
class Doctor with _$Doctor {
  const factory Doctor({
    required String id,
    @JsonKey(name: 'first_name') required String firstName,
    @JsonKey(name: 'last_name') required String lastName,
    String? specialization,
    @JsonKey(name: 'license_number') String? licenseNumber,
    String? department,
  }) = _Doctor;

  factory Doctor.fromJson(Map<String, dynamic> json) => _$DoctorFromJson(json);
}

/// ─── Prescription ─────────────────────────────────────
@freezed
class Prescription with _$Prescription {
  const factory Prescription({
    required String id,
    @JsonKey(name: 'patient_id') required String patientId,
    @JsonKey(name: 'doctor_id') required String doctorId,
    String? diagnosis,
    String? notes,
    required String status,
    @JsonKey(name: 'prescribed_at') DateTime? prescribedAt,
    @JsonKey(name: 'valid_until') DateTime? validUntil,
    Patient? patients,
    Doctor? doctors,
    @JsonKey(name: 'prescription_drugs') @Default([]) List<PrescriptionDrug> prescriptionDrugs,
    @JsonKey(name: 'interaction_alerts') @Default([]) List<Alert> interactionAlerts,
  }) = _Prescription;

  factory Prescription.fromJson(Map<String, dynamic> json) => _$PrescriptionFromJson(json);
}

/// ─── PrescriptionDrug ─────────────────────────────────
@freezed
class PrescriptionDrug with _$PrescriptionDrug {
  const factory PrescriptionDrug({
    required String id,
    @JsonKey(name: 'drug_id') required String drugId,
    required String dosage,
    required String frequency,
    String? duration,
    String? instructions,
    Drug? drugs,
  }) = _PrescriptionDrug;

  factory PrescriptionDrug.fromJson(Map<String, dynamic> json) => _$PrescriptionDrugFromJson(json);
}

/// ─── Interaction ──────────────────────────────────────
@freezed
class Interaction with _$Interaction {
  const factory Interaction({
    @JsonKey(name: 'interactionId') required String interactionId,
    @JsonKey(name: 'drugPair') required DrugPairInfo drugPair,
    @JsonKey(name: 'ingredientPair') required IngredientPairInfo ingredientPair,
    required String severity,
    @JsonKey(name: 'clinicalEffect') String? clinicalEffect,
    String? mechanism,
    String? recommendation,
    @JsonKey(name: 'evidenceLevel') String? evidenceLevel,
  }) = _Interaction;

  factory Interaction.fromJson(Map<String, dynamic> json) => _$InteractionFromJson(json);
}

@freezed
class DrugPairInfo with _$DrugPairInfo {
  const factory DrugPairInfo({
    required String drugAId,
    required String drugAName,
    required String drugAGeneric,
    required String drugBId,
    required String drugBName,
    required String drugBGeneric,
  }) = _DrugPairInfo;

  factory DrugPairInfo.fromJson(Map<String, dynamic> json) => _$DrugPairInfoFromJson(json);
}

@freezed
class IngredientPairInfo with _$IngredientPairInfo {
  const factory IngredientPairInfo({
    required String ingredientAId,
    required String ingredientAName,
    required String ingredientBId,
    required String ingredientBName,
  }) = _IngredientPairInfo;

  factory IngredientPairInfo.fromJson(Map<String, dynamic> json) => _$IngredientPairInfoFromJson(json);
}

/// ─── Alert ────────────────────────────────────────────
@freezed
class Alert with _$Alert {
  const factory Alert({
    required String id,
    @JsonKey(name: 'prescription_id') String? prescriptionId,
    @JsonKey(name: 'drug_a_id') String? drugAId,
    @JsonKey(name: 'drug_b_id') String? drugBId,
    @JsonKey(name: 'ingredient_a_id') String? ingredientAId,
    @JsonKey(name: 'ingredient_b_id') String? ingredientBId,
    required String severity,
    @JsonKey(name: 'clinical_effect') String? clinicalEffect,
    String? recommendation,
    required String status,
    @JsonKey(name: 'acknowledged_by') String? acknowledgedBy,
    @JsonKey(name: 'acknowledged_at') DateTime? acknowledgedAt,
    @JsonKey(name: 'override_reason') String? overrideReason,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Alert;

  factory Alert.fromJson(Map<String, dynamic> json) => _$AlertFromJson(json);
}

/// ─── AlertFilterParams (R-02 fix) ─────────────────────
/// Typed filter params with proper value equality via Freezed.
/// Prevents infinite rebuilds caused by Map<String, dynamic>.
@freezed
class AlertFilterParams with _$AlertFilterParams {
  const factory AlertFilterParams({
    @Default(20) int limit,
    @Default(0) int offset,
    String? severity,
    String? status,
  }) = _AlertFilterParams;

  factory AlertFilterParams.fromJson(Map<String, dynamic> json) => _$AlertFilterParamsFromJson(json);
}

/// ─── API Response Envelope ────────────────────────────
@freezed
class ApiResponse<T> with _$ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    T? data,
    ApiMeta? meta,
    PaginationInfo? pagination,
  }) = _ApiResponse;
}

@freezed
class ApiMeta with _$ApiMeta {
  const factory ApiMeta({
    String? requestId,
    required String timestamp,
  }) = _ApiMeta;

  factory ApiMeta.fromJson(Map<String, dynamic> json) => _$ApiMetaFromJson(json);
}

@freezed
class PaginationInfo with _$PaginationInfo {
  const factory PaginationInfo({
    required int total,
    required int limit,
    required int offset,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _PaginationInfo;

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => _$PaginationInfoFromJson(json);
}
